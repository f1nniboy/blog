{ pkgs, ... }:
let
  toTOML = (pkgs.formats.toml { }).generate;
in
toTOML "config.toml" {
  title = "f1nn";
  description = "my personal blog";
  author = "f1nn";

  # locale
  compile_sass = true;
  minify_html = true;

  # other
  base_url = "/";

  taxonomies = [
    {
      name = "tags";
      feed = true;
    }
  ];

  # theme
  theme = "custom";
  extra = {
    main_menu = [
      {
        name = "about";
        url = "";
        trailing_slash = true;
      }
      {
        name = "posts";
        url = "posts";
      }
    ];
    socials = [
      {
        name = "email";
        url = "mailto:me@f1nn.space";
      }
      {
        name = "discord";
        url = "https://discord.com/users/747682664135524403";
      }
      {
        name = "github";
        url = "https://github.com/f1nniboy";
      }
    ];
    close_responsive_menu_on_resize = false;
    copy_button = false;
    show_default_author = false;
    favicon_emoji = "👨‍💻";
    copyright = "theme by [ebkalderon](https://github.com/ebkalderon)";
  };
}
