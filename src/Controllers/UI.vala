/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified August 29, 2020
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

using ThiefMD;
using ThiefMD.Widgets;

namespace ThiefMD.Controllers.UI {
    private bool _init = false;
    private bool _show_filename = false;
    private Gtk.CssProvider active_provider = null;
    private Gtk.CssProvider font_provider = null;
    private Gtk.CssProvider border_provider;
    private Ultheme.HexColorPalette current_palette = null;

    //
    // Sheets Management
    //
    public void update_preview () {
        
    }

    // Switches Sheets shown in the Library view with the
    // provided sheet
    Sheets? current;
    public Sheets set_sheets (Sheets? sheet) {
        var settings = AppSettings.get_default ();
        if (sheet == null) {
            return sheet;
        }
        ThiefApp instance = ThiefApp.get_instance ();
        var old = current;
        if (current != null) {
            instance.library_pane.remove (current);
            sheet.width_request = settings.view_sheets_width;
            instance.library_pane.add (sheet);
            instance.library_pane.show_all ();
            instance.library_pane.width_request = settings.view_sheets_width + settings.view_library_width;
        }
        settings.sheet_changed ();
        current = sheet;
        return (Sheets) old;
    }

    public void widen_sheets () {
        if (current != null) {
            current.hexpand = true;
        }
    }

    public void shrink_sheets () {
        if (current != null) {
            var settings = AppSettings.get_default ();
            current.hexpand = false;
            current.width_request = settings.view_sheets_width;
        }
    }

    //
    // Themeing and Styling of the App
    //
    private Gtk.SourceStyleSchemeManager thief_schemes;
    public List<Ultheme.Parser> user_themes;
    private Thread<bool> theme_worker_thread;

    public void add_user_theme (Ultheme.Parser user_theme) {
        if (user_themes == null) {
            user_themes = new List<Ultheme.Parser> ();
        }

        user_themes.append (user_theme);
    }

    private void remove_border_color () {
        if (border_provider != null) {
            Gtk.StyleContext.remove_provider_for_screen (Gdk.Screen.get_default(), border_provider);
            border_provider = null;
        }
    }

    private void insert_border_color () {
        remove_border_color ();
        var style_context = ThiefApp.get_instance ().toolbar.get_style_context ();
        border_provider = new Gtk.CssProvider ();
        var font_color = style_context.get_color (0);
        string border_css = ThiefProperties.BUTTON_CSS.printf (font_color.to_string ());
        try {
            border_provider.load_from_data (border_css);
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default(), border_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Could not add accessibility css: %s", e.message);
        }
    }

    public void load_user_themes_and_connections () {
        if (user_themes != null) {
            return;
        }

        load_css_scheme ();
        user_themes = new List<Ultheme.Parser> ();
        if (!Thread.supported ()) {
            warning ("No threads available for work");
            GLib.Idle.add (load_themes_and_connections);
        } else {
            theme_worker_thread = new Thread<bool>("theme_worker_thread", load_themes_and_connections);
        }
    }

    private bool need_to_update_theme (string contents, File file) {
        string new_theme = Checksum.compute_for_string (ChecksumType.MD5, contents);
        string old_text;
        try {
            GLib.FileUtils.get_contents (file.get_path (), out old_text);
            string old_theme = Checksum.compute_for_string (ChecksumType.MD5, old_text);

            return new_theme != old_theme;
        } catch (Error e) {
            return true;
        }
    }

    private bool load_themes_and_connections () {
        // Load previous added themes
        debug ("Loading themes");
        try {
            // Clean outdated themes
            var one_week_ago = new DateTime.now_utc ().add_days (-7);
            Dir scheme_dir = Dir.open (UserData.scheme_path, 0);
            string? file_name = null;
            while ((file_name = scheme_dir.read_name()) != null) {
                if (!file_name.has_prefix(".")) {
                    if (file_name.down ().has_suffix (".xml")) {
                        string scheme_path = Path.build_filename (UserData.scheme_path, file_name);
                        File scheme_file = File.new_for_path (scheme_path);
                        FileInfo last_modified = scheme_file.query_info (FileAttribute.TIME_MODIFIED, FileQueryInfoFlags.NONE);
                        var scheme_modified_time = last_modified.get_modification_date_time ();
                        // If the time is less than one week ago, it's older than
                        // one week ago and should be safe to delete.
                        if (scheme_modified_time.compare (one_week_ago) < 0) {
                            scheme_file.delete ();
                        }
                    }
                }
            }

            // Load schemes
            Dir theme_dir = Dir.open (UserData.style_path, 0);
            file_name = null;
            while ((file_name = theme_dir.read_name()) != null) {
                if (!file_name.has_prefix(".")) {
                    if (file_name.down ().has_suffix ("ultheme")) {
                        string style_path = Path.build_filename (UserData.style_path, file_name);
                        File style_file = File.new_for_path (style_path);
                        var theme = new Ultheme.Parser (style_file);

                        // Reparse dark theme
                        string dark_path = Path.build_filename (UserData.scheme_path, theme.get_dark_theme_id () + ".xml");
                        File dark_file = File.new_for_path (dark_path);
                        try {
                            string dark_theme_data = theme.get_dark_theme ();
                            if (dark_file.query_exists () && need_to_update_theme(dark_theme_data, dark_file)) {
                                dark_file.delete ();
                                FileManager.save_file (dark_file, dark_theme_data.data);
                            }
                            if (!dark_file.query_exists ()) {
                                FileManager.save_file (dark_file, dark_theme_data.data);
                            }
                        } catch (Error e) {
                            warning ("Could not save local scheme: %s", e.message);
                        }

                        string light_path = Path.build_filename (UserData.scheme_path, theme.get_light_theme_id () + ".xml");
                        File light_file = File.new_for_path (light_path);
                        try {
                            string light_theme_data = theme.get_light_theme ();
                            if (light_file.query_exists () && need_to_update_theme (light_theme_data, light_file)) {
                                light_file.delete ();
                                FileManager.save_file (light_file, light_theme_data.data);
                            }
                            if (!light_file.query_exists ()) {
                                FileManager.save_file (light_file, light_theme_data.data);
                            }
                        } catch (Error e) {
                            warning ("Could not save local scheme: %s", e.message);
                        }

                        add_user_theme (theme);
                    }
                }
            }
        } catch (Error e) {
            warning ("Could not load themes: %s", e.message);
        }
        debug ("Themes loaded");

        return false;
    }

    public bool show_link_brackets () {
        var settings = AppSettings.get_default ();
        if (current_palette == null || settings.theme_id == "thiefmd") {
            return false;
        } else {
            return (current_palette.global.foreground == current_palette.link.foreground) &&
                    (current_palette.global.background == current_palette.link.background);
            //  Clutter.Color text_color = Clutter.Color.from_string (current_palette.global.foreground);
            //  Clutter.Color link_color = Clutter.Color.from_string (current_palette.link.foreground);
            //  float m1, lum1, lum2, m2;
            //  text_color.to_hls (out m1, out lum1, out m2);
            //  link_color.to_hls (out m1, out lum2, out m2);
            //  m1 = float.max (lum1, lum2);
            //  m2 = float.min (lum1, lum2);

            //  // Make sure contrast ratio differentiates links from normal text
            //  if (((m1 + 0.05) / (m2 + 0.05)) > Constants.MINIMUM_CONTRAST_RATIO) {
            //      return false;
            //  } else {
            //      text_color = Clutter.Color.from_string (current_palette.global.background);
            //      link_color = Clutter.Color.from_string (current_palette.link.background);
            //      text_color.to_hls (out m1, out lum1, out m2);
            //      link_color.to_hls (out m1, out lum2, out m2);
            //      m1 = float.max (lum1, lum2);
            //      m2 = float.min (lum1, lum2);

            //      return ((m1 + 0.05) / (m2 + 0.05)) < Constants.MINIMUM_CONTRAST_RATIO;
            //  }
        }
    }

    public void get_focus_bg_color (out double r, out double g, out double b) {
        var settings = AppSettings.get_default ();
        Clutter.Color background;
        if (current_palette == null || settings.theme_id == "thiefmd") {
            background = Clutter.Color.from_string ("#FAFAFA");
        } else {
            background = Clutter.Color.from_string (current_palette.global.background);
        }
        r = background.red / 255.0;
        g = background.green / 255.0;
        b = background.blue / 255.0;
    }

    public void get_focus_color (out double r, out double g, out double b) {
        var settings = AppSettings.get_default ();
        Clutter.Color focus;
        if (current_palette == null || settings.theme_id == "thiefmd") {
            focus = Clutter.Color.from_string ("#191919");
        } else {
            focus = Clutter.Color.from_string (current_palette.global.foreground);
        }
        r = focus.red / 255.0;
        g = focus.green / 255.0;
        b = focus.blue / 255.0;
    }

    public void get_codeblock_bg_color (out double r, out double g, out double b) {
        var settings = AppSettings.get_default ();
        Clutter.Color code_bg;
        if (current_palette == null || settings.theme_id == "thiefmd") {
            code_bg = Clutter.Color.from_string ("#FAFAFA");
        } else {
            code_bg = Clutter.Color.from_string (current_palette.code_block.background);
        }
        r = code_bg.red / 255.0;
        g = code_bg.green / 255.0;
        b = code_bg.blue / 255.0;
    }

    public void get_out_of_focus_color (out double r, out double g, out double b) {
        var settings = AppSettings.get_default ();
        Clutter.Color background;
        Clutter.Color foreground;
        if (current_palette == null || settings.theme_id == "thiefmd") {
            background = Clutter.Color.from_string ("#FAFAFA");
            foreground = Clutter.Color.from_string ("#191919");
        } else {
            background = Clutter.Color.from_string (current_palette.global.background);
            foreground = Clutter.Color.from_string (current_palette.global.foreground);
        }
        Clutter.Color out_of_focus = foreground.interpolate (background, 0.82);
        r = out_of_focus.red / 255.0;
        g = out_of_focus.green / 255.0;
        b = out_of_focus.blue / 255.0;
    }

    public void load_font () {
        var settings = AppSettings.get_default ();
        if (font_provider != null) {
            Gtk.StyleContext.remove_provider_for_screen (Gdk.Screen.get_default (), font_provider);
            font_provider = null;
        }

        if (settings.get_css_font_family () == "") {
            return;
        }

        // Assuming 12pt is 1rem, scale to original CSS based on that
        string new_font = ThiefProperties.FONT_SETTINGS.printf (
            settings.get_css_font_family (), (int)((settings.get_css_font_size ()) * 1),
            settings.get_css_font_family (), (int)((settings.get_css_font_size ()) * 1.2),
            settings.get_css_font_family (), (int)((settings.get_css_font_size ()) * 1.4)
        );

        try {
            font_provider = new Gtk.CssProvider ();
            font_provider.load_from_data (new_font);
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), font_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Error setting font: %s", e.message);
        }
    }

    public Gtk.SourceStyleSchemeManager UserSchemes () {
        if (thief_schemes == null) {
            thief_schemes = new Gtk.SourceStyleSchemeManager ();
        }

        return thief_schemes;
    }

    public void load_css_scheme () {
        var settings = AppSettings.get_default ();
        Ultheme.HexColorPalette palette;
        bool set_scheme = false;

        debug ("Using %s", settings.custom_theme);
        if (settings.theme_id != "thiefmd") {
            string style_path = Path.build_filename (UserData.style_path, settings.custom_theme);
            File style = File.new_for_path (style_path);
            if (style.query_exists ()) {
                try {
                    var theme = new Ultheme.Parser (style);
                    if (settings.dark_mode) {
                        theme.get_dark_theme_palette (out palette);
                    } else {
                        theme.get_light_theme_palette (out palette);
                    }
                    set_css_scheme (palette);
                    set_scheme = true;
                } catch (Error e) {
                    debug ("Could not load previous style (%s): %s", settings.custom_theme, e.message);
                }
            }
        } else {
            reset_css ();
            set_scheme = true;
        }

        if (settings.show_writing_statistics) {
            ThiefApp.get_instance ().stats_bar.show_statistics ();
        }

        SheetManager.redraw_sheets ();

        // Attempt to wait for app instance to be ready.
        if (!set_scheme) {
            Timeout.add (50, () => {
                load_css_scheme ();
                return false;
            });
        }
    }

    public void clear_css () {
        if (active_provider != null) {
            Gtk.StyleContext.remove_provider_for_screen (Gdk.Screen.get_default (), active_provider);
            active_provider = null;
        }
        set_dark_mode_based_on_colors ();
        remove_border_color ();
        insert_border_color ();
    }

    public void reset_css () {
        var settings = AppSettings.get_default ();

        if (!settings.ui_editor_theme) {
            clear_css ();
            return;
        }

        if (active_provider != null) {
            Gtk.StyleContext.remove_provider_for_screen (Gdk.Screen.get_default (), active_provider);
            active_provider = null;
        }

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/kmwallio/thiefmd/app-stylesheet.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        active_provider = provider;
        Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
        current_palette = null;
    }

    public void set_css_scheme (Ultheme.HexColorPalette palette) {
        var settings = AppSettings.get_default ();
        current_palette = palette;
        set_dark_mode_based_on_colors ();
        if (palette == null || !settings.ui_editor_theme) { 
            clear_css ();
            return;
        }

        string new_css = ThiefProperties.DYNAMIC_CSS.printf (
            palette.global.background,
            palette.global_active.background,
            palette.headers.foreground,
            palette.global_active.foreground,
            palette.global.foreground
        );

        try {
            if (active_provider != null) {
                Gtk.StyleContext.remove_provider_for_screen (Gdk.Screen.get_default (), active_provider);
                active_provider = null;
            }
            var provider = new Gtk.CssProvider ();
            provider.load_from_data (new_css);
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            active_provider = provider;
            remove_border_color ();
        } catch (Error e) {
            warning ("Could not set dynamic css: %s", e.message);
        }
    }

    private void set_dark_mode_based_on_colors () {
        var settings = AppSettings.get_default ();

        if (current_palette != null && settings.theme_id != "thiefmd") {
            // Use luminance to determine if the background is dark or light as some themes
            // include 2 dark themes or 2 light themes
            Clutter.Color color = Clutter.Color.from_string (current_palette.global.background);
            float hue, lum, sat;
            color.to_hls (out hue, out lum, out sat);

            // Set dark theme
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = (lum < 0.5);

            if (Build.HOST == "darwin") {
                if (lum < 0.5) {
                    Environment.set_variable ("GTK_THEME", "Adwaita-dark", true);
                } else {
                    Environment.set_variable ("GTK_THEME", "Adwaita", true);
                }
            }
        } else {
            if (settings.theme_id != "thiefmd") {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.dark_mode;
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
            }
        }
    }

    //
    // ThiefMD Custom GtkSourceView Languages
    //
    private Gtk.SourceLanguageManager thief_languages;

    public Gtk.SourceLanguageManager get_language_manager () {
        if (thief_languages == null) {
            thief_languages = new Gtk.SourceLanguageManager ();
            string custom_languages = Path.build_path (
                Path.DIR_SEPARATOR_S,
                Build.PKGDATADIR,
                "gtksourceview-4",
                "language-specs");
            string[] language_paths = {
                custom_languages
            };
            thief_languages.set_search_path (language_paths);

            var markdown = thief_languages.get_language ("markdown");
            if (markdown == null) {
                warning ("Could not load custom languages");
                thief_languages = Gtk.SourceLanguageManager.get_default ();
            }
        }

        return thief_languages;
    }

    public Gtk.SourceLanguage get_source_language (string filename = "something.md") {
        var languages = get_language_manager ();
        Gtk.SourceLanguage? language = null;
        string file_name = filename.down ();

        if (file_name.has_suffix (".bib") || file_name.has_suffix (".bibtex")) {
            language = languages.get_language ("bibtex");
            if (language == null) {
                language = languages.guess_language (null, "text/x-bibtex");
            }
        } else if (file_name.has_suffix (".fountain") || file_name.has_suffix (".fou") || file_name.has_suffix (".spmd")) {
            language = languages.get_language ("fountain");
            if (language == null) {
                language = languages.guess_language (null, "text/fountain");
            }
        } else {
            language = languages.get_language ("markdown");
            if (language == null) {
                language = languages.guess_language (null, "text/markdown");
            }
        }

        return language;
    }

    //
    // Switching Main Window View
    //

    public void focus_editor () {
        var settings = AppSettings.get_default ();
        ThiefApp instance = ThiefApp.get_instance ();
        if (instance.main_content != null) {
            instance.main_content.set_visible_child (SheetManager.get_view ());
            if (instance.main_content.folded) {
                settings.view_state = 2;
            }
        }
    }

    public void show_editor () {
        var settings = AppSettings.get_default ();
        settings.view_state = 1;
        show_view ();
    }

    public void show_search () {
        ThiefApp instance = ThiefApp.get_instance ();
        instance.show_search ();
    }

    public void show_library () {
        var settings = AppSettings.get_default ();
        settings.view_state = 0;
        show_view ();
    }

    // Cycle through views
    public void toggle_view () {
        var settings = AppSettings.get_default ();
        ThiefApp instance = ThiefApp.get_instance ();

        if (!_init) {
            _init = true;
            _show_filename = settings.show_filename;
        }

        if (!instance.ready) {
            return;
        }

        instance.hide_search ();
        if (instance.main_content != null && instance.main_content.folded) {
            settings.view_state = (settings.view_state + 1) % 3;
            if (settings.view_state == 0) {
                show_sheets_and_library ();
                instance.main_content.set_visible_child (instance.library_pane);
                instance.library_pane.set_visible_child (instance.library_view);
            } else if (settings.view_state == 1) {
                show_sheets_and_library ();
                instance.main_content.set_visible_child (instance.library_pane);
                if (current != null) {
                    instance.library_pane.set_visible_child (current);
                }
                if (!instance.library_pane.folded) {
                    toggle_view ();
                }
            } else {
                instance.main_content.set_visible_child (SheetManager.get_view ());
            }
        } else {
            settings.view_state = (settings.view_state + 1) % 3;
            show_view ();
        }
    }

    public void show_view () {
        var settings = AppSettings.get_default ();

        if (!_init) {
            _init = true;
            _show_filename = settings.show_filename;
        }

        ThiefApp.get_instance ().hide_search ();
        if (settings.view_state == 0) {
            show_sheets_and_library ();
        } else if (settings.view_state == 1) {
            hide_library ();
        } else if (settings.view_state == 2) {
            hide_sheets ();
        }
    }

    // Switch to showing Editor + Sheets
    public void show_sheets () {
        var settings = AppSettings.get_default ();
        ThiefApp instance = ThiefApp.get_instance ();
        if (current != null) {
            current.show ();
            current.width_request = settings.view_sheets_width;
            instance.library_pane.set_visible_child (current);
            instance.library_pane.show ();
        }
        instance.main_content.set_visible_child (instance.library_pane);
    }

    public void hide_library () {
        var settings = AppSettings.get_default ();
        ThiefApp instance = ThiefApp.get_instance ();
        if (current != null) {
            current.show ();
            current.width_request = settings.view_sheets_width;
            instance.library_pane.set_visible_child (current);
            instance.library_view.hide ();
            instance.library_pane.width_request = settings.view_sheets_width;
            instance.main_content.set_visible_child (SheetManager.get_view ());
            instance.library_pane.show ();
        }
        
        if (instance.ready && instance.main_content.folded) {
            settings.view_state += 1;
        }
    }

    // Show all three panels
    public void show_sheets_and_library () {
        var settings = AppSettings.get_default ();
        ThiefApp instance = ThiefApp.get_instance ();
        if (current != null) {
            current.show ();
            current.width_request = settings.view_sheets_width;
            instance.library_view.show ();
            instance.library_view.width_request = settings.view_library_width;
            instance.library_pane.show_all ();
            instance.library_pane.width_request = settings.view_sheets_width + settings.view_library_width;
        }
        instance.main_content.set_visible_child (SheetManager.get_view ());
    }

    // Show just the Editor
    public void hide_sheets () {
        ThiefApp instance = ThiefApp.get_instance ();
        instance.library_pane.hide ();
    }
}