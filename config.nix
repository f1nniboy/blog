{ pkgs, domain, ... }:
let
  toTOML = (pkgs.formats.toml { }).generate;
in
toTOML "config.toml" {
  title = "f1nn's blog";
  description = "my personal blog";
  author = "f1nn";

  # html
  compile_sass = true;
  minify_html = true;

  # feed
  generate_feeds = true;
  feed_filenames = [ "rss.xml" ];

  # other
  base_url = domain;

  taxonomies = [
    {
      name = "tags";
      feed = true;
    }
  ];

  markdown = {
    highlight_code = true;
    highlight_theme = "monokai";
    render_emoji = true;
    smart_punctuation = true;
    bottom_footnotes = true;
  };

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
        trailing_slash = true;
      }

      {
        name = "bits";
        url = "bits";
        trailing_slash = true;
      }
    ];
    socials = [
      {
        name = "email";
        url = "mailto:me@f1nn.space";
      }
      {
        name = "github";
        url = "https://github.com/f1nniboy";
      }
    ];

    responsive_images = {
      widths = [
        200
        400
        600
        800
        1000
        1200
      ];
      # must exist in the above list
      fallback_width = 1200;
    };
    close_responsive_menu_on_resize = false;
    copy_button = false;
    show_default_author = false;
    header_title = "f1nn's blog";
    favicon_emoji = "📟";
    copyright = "theme by [ebkalderon](https://github.com/ebkalderon)";
  };
}
