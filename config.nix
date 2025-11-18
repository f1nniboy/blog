{ pkgs, ... }:
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
  # TODO: use as attr from package
  base_url = "https://f1nn.space";

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
        trailing_slash = true;
      }
      {
        name = "tags";
        url = "tags";
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
    close_responsive_menu_on_resize = false;
    copy_button = false;
    show_default_author = false;
    bottom_footnotes = true;
    header_title = "f1nn's blog";
    favicon_emoji = "📟";
    copyright = "theme by [ebkalderon](https://github.com/ebkalderon)";
  };
}
