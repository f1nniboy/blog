+++
title = "How to Use Headscale With Mullvad VPN"
description = "Replicate Tailscale's Mullvad exit nodes using Headscale at home"
date = 2025-11-24

[taxonomies]
tags = [ "tailscale", "vpn" ]
+++

I recently switched to a self-hosted **[Headscale](https://github.com/juanfont/headscale)** instance for my homelab, as I don't like to be dependent on a central service (**Tailscale**) for connectivity between my devices.

# The Issue
I consider myself pretty paranoid (*as you should be*), so I like to be connected to Mullvad VPN at all times. To make the Mullvad standalone app and Tailscale work together nicely, I had to use a hacky `nftables` rule to tell Mullvad to pass-through all traffic from Tailscale, by marking it with a special "tracking mark" — you can read more about this on [Mullvad's site](https://mullvad.net/en/help/split-tunneling-with-linux-advanced#allow-ip).

```
table inet mullvad_tailscale {
  chain output {
    type route hook output priority 0; policy accept;
    ip daddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
  }
}
```

This works fine on my desktop and laptop, but how can you use Tailscale and Mullvad simultaneously on mobile? Android only supports one connected VPN at a time, and I don't feel like tinkering with firewall settings there (*if that's even possible?*). It would also be nice to get rid of the standalone Mullvad app on desktop and just connect to the relays directly, without the `nftables` hack.

# Doing Some Research
While scouting the Headscale repo, I stumbled across issue **[#1545](https://github.com/juanfont/headscale/issues/1545)** requesting support for "Wireguard-only peers," exactly what Tailscale added to support Mullvad exit nodes.

At first the issue seemed pretty stale — opened in September 2023 and still open — but coincidentally a **[PR](https://github.com/juanfont/headscale/pull/2892)** was just recently opened to implement this feature. The creator said they've been using this feature for a while now & it sounded prettty feature-complete, so I decided to give it a try.

If you're on NixOS, making use of this pull request is as easy as ...
```nix
{ pkgs, ... }: {
  services.headscale = {
    # ...
    package = pkgs.headscale.overrideAttrs (_: {
      src = pkgs.fetchFromGitHub {
        owner = "iridated";
        repo = "headscale";
        rev = "wireguard-only-peers";
        hash = ""; # build once to get the hash
      };
  
      vendorHash = ""; # build once to get the hash
    });
  };
}
```

# How To (The Manual Way)
First, I'll go over the rather painful manual way to create a Mullvad Wireguard-only node in your tailnet. This guide assumes you have some basic knowledge about Headscale and its CLI interface.

If you don't care about how this works behind the scenes, you can just do it the **[automatic way](#how-to-the-automatic-way)**.

## 1. Pick a relay and add it to Headscale
You can search for relays on [Mullvad's site](https://mullvad.net/en/servers).

```bash
RELAY_PUBLIC_KEY=zOBWmQ3BEOZKsYKbj4dC2hQjxCbr3eKa6wGWyEDYbC4=
RELAY_IPV4=176.125.235.73
RELAY_IPV6=2a02:20c8:4124::a03f

USER_ID=1234
NODE_NAME=cool-node-name
```

We will need this shell function below, as the Headscale CLI interface requires you to convert the Wireguard public key into a Tailscale `nodekey`.
```bash
wg2ts() {
    echo "nodekey:"$(echo "$1" | base64 -d 2>/dev/null | od -An -tx1 | tr -d ' \n')
}
```

Now, let's create the Wireguard-only node in our tailnet. This makes the Mullvad relay known to Headscale, but we can't really do anything with it yet.
```bash
$ headscale node register-wg-only \
    --name $NODE_NAME \
    --user $USER_ID \
    --public-key "$(wg2ts $RELAY_PUBLIC_KEY)" \
    --allowed-ips "0.0.0.0/0, ::/0" \
    --endpoints "$RELAY_IPV4:51820, $RELAY_IPV6:51820" \
    --extra-config '{"suggestExitNode": true}'
    
WireGuard-only peer $NODE_NAME registered (allocated IPs: ..., ...). Use 'nodes add-wg-connection' to connect nodes.
```

We'll have to run another command to figure out which ID was assigned to our Wireguard node. Save this as `WIREGUARD_NODE_ID` for later use.
```bash
$ headscale node list -o json \
    | jq -r ".wireguard_only_peers[] | select(.name == \"$NODE_NAME\") | .id"
  
100000001
```

## 2. Register your Tailscale device with Mullvad to allow authentication with relays
To actually make use of the added Mullvad relay, we will now have to register our chosen Tailscale device with Mullvad, using their API. 

```bash
MULLVAD_ACCOUNT=1234567890123456
NODE_ID=5678
NODEKEY=$(headscale node list -o json | jq -r ".nodes[] | select(.id == $NODE_ID) | .node_key")
```

Now the other way around: Mullvad expects you to register a Wireguard public key, so we'll have to convert the device's `nodekey` to one.
```bash
ts2wg() {
    hex="$(echo "$1" | sed 's/^nodekey://i; s/[^0-9a-fA-F]//g')"
    printf '%b' "$(echo "$hex" | sed 's/../\\x&/g')" | base64 | tr -d '\n'
    echo
}
```

Let's register the device with Mullvad now. This makes the Wireguard public key of the chosen device known to Mullvad and allows us to connect to their relays.
```bash
$ curl -sSL \
    https://api.mullvad.net/wg \
    -d account="$MULLVAD_ACCOUNT" \
    --data-urlencode pubkey="$(ts2wg $NODEKEY)"
    
10.70.37.216/32,fc00:bbbb:bbbb:bb01::7:3bf2/128
```

{% alert(type="tip") %}
You can also register the public key using [Mullvad's web interface](https://mullvad.net/en/account/devices).
{% end %}

## 3. Create a connection to the relay
Now that we have the IPs Mullvad wants us to connect with, we can add the connection to the Tailscale node in our tailnet. Without these special masquerade IPs, connections to the relay would not work. The masquerade IPs are unique for each public key, so you can re-use them for other relays.

```bash
$ headscale node add-wg-connection \
    --node-id $NODE_ID \
    --wg-peer-id $WIREGUARD_NODE_ID \
    --ipv4-masq-addr $IPV4_FROM_ABOVE \
    --ipv6-masq-addr $IPV6_FROM_ABOVE
    
Connection created between node $NODE_ID and WireGuard peer $WIREGUARD_NODE_ID
```

# How To (The Automatic Way)
Understandably, no one wants to manually create all **670**<sup>[*[citation needed](https://mullvad.net/en/servers)*]</sup> Mullvad relays by hand. I made a small Python script to help with maintaining these relays & connections to nodes, which can be found **[here](https://github.com/f1nniboy/headscale-mullvad)**.


As a bonus, Mullvad relay nodes will display nicely in the mobile app using this method.
{{ image(
  src="tailscale-app.png",
  alt="Screenshot of Tailscale mobile app with current exit node 'Ireland: Dublin (ie-dub-wg-101)' being displayed."
) }}

---

And you're **done**! Now you just have to
- force-close the Tailscale mobile app & select the exit node from the drop down menu **or**
- restart the Tailscale daemon and `tailscale set --exit-node=$NODE_NAME`

# Closing Words
This guide should also apply to any other VPN provider giving you direct access to the Wireguard relays, while the registration process of course differs. I have been daily-driving this setup for a few days now without encountering any issues. You should still remember, this feature is pretty much still **work-in-progress** and not merged into the repository yet. I'll update this post with new information once it gets merged.
