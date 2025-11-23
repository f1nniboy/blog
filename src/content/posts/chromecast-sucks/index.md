+++
title = "Chromecast Sucks (at SSL Certificates)"
description = "How to *fail miserably* at installing a self-signed certificate on a Chromecast"
date = 2025-11-22

[taxonomies]
tags = [ "chromecast", "certs" ]
+++

I needed to install a self-signed certificate on my Chromecast[^1] for my homelab, since I decided to go the **run-your-own-certificate-authority** route — more about that setup in a later blog post.

[^1]: or Google TV, *whatever*

# Android = Freedom, Right?
With Android being the most open OS of the mobile monopoly, I thought it would be a 5-minute task to install the root certificate. First, I tried downloading it using [TV Bro](https://github.com/truefedex/tv-bro), a browser for Chromecast, and installing it by simply opening the file, which ...

{{ image(
  src="first-try.png",
  alt="Popup with title 'Install CA certificates in Settings' and subtext 'This certificate from null must be installed in Settings. Only install CA certificates from organizations you trust.'"
) }}

... didn't work. Supposedly, installing certificates like this used to work fine on older Android versions, but they decided it was a consumer-friendly idea to lock down the device I paid for.

## Settings
Easy, you might say: just follow what the system popup says and look for ...
- Security & Privacy
  - More security & privacy
    - Encryption & credentials
    
... in Settings, where you can usually install certificates on Android devices. Well, for whatever ungodly reason, Google decided to strip this setting from the Chromecast entirely.

{{ image(src="security-options.png", alt="'Privacy' menu in Settings, with the 'Security' sub-menu open. The 'Security' sub-menu only contains the entries 'Scan apps with Play Protect' and 'Improve harmful app detection'.") }}

## CertInstaller
Following that failure, I tried being slick by copying the root certificate to some random location on the Chromecast using `adb` and manually installing it using the `com.android.certinstaller` package.

```bash
adb shell am start \
    -n com.android.certinstaller/.CertInstallerMain \
    -a android.intent.action.VIEW \
    -t application/x-x509-ca-cert \
    -d file:///data/local/tmp/root.crt
```

I ran this command to no avail; it resulted in the same error popup as before. This wasn't very surprising, as opening the certificate in the browser does pretty much the same thing as the command above.

# What Now?
Funnily enough, it is actually a breeze to install certificates on an Apple TV, allowing you to directly download the certificate via URL. Thanks to Google's restrictions, I have just *given up* on installing the root certificate for now and just connect to my Jellyfin instance using `http://`. Not the solution I was hoping for, but it will do for now. :confused:
