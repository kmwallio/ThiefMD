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
using Adw;

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
    TimedMutex preview_mutex;
    public void update_preview () {
        if (preview_mutex == null) {
            preview_mutex = new TimedMutex (250);
        }

        if (PreviewWindow.has_instance ()) {
            if (preview_mutex.can_do_action ()) {
                var settings = AppSettings.get_default ();
                PreviewWindow.get_instance ().update ();
                settings.writing_changed ();
            }
        }
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
        sheet.width_request = settings.view_sheets_width;
        instance.library_split.set_end_child (sheet);
        instance.set_library_split_position_silent (settings.view_library_width);
        instance.library_pane.set_visible_child (instance.library_split);
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
    private GtkSource.StyleSchemeManager thief_schemes;
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
            var display = Gdk.Display.get_default ();
            if (display != null) {
                Gtk.StyleContext.remove_provider_for_display (display, border_provider);
            }
            border_provider = null;
        }
    }

    private void insert_border_color () {
        remove_border_color ();
        var style_context = ThiefApp.get_instance ().toolbar.get_style_context ();
        border_provider = new Gtk.CssProvider ();
        var font_color = style_context.get_color ();
        string border_css = ThiefProperties.BUTTON_CSS.printf (font_color.to_string ());
        try {
            var display = Gdk.Display.get_default ();
            if (display != null) {
                border_provider.load_from_data ((uint8[]) border_css.data);
                Gtk.StyleContext.add_provider_for_display (display, border_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            }
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

        debug ("Loading user connections");
        GLib.Idle.add (() => {
            SecretSchemas.get_instance ().load_secrets ();
            debug ("Connections loaded");
            return false;
        }, GLib.Priority.LOW);

        return false;
    }

    public bool show_link_brackets () {
        var settings = AppSettings.get_default ();
        if (current_palette == null || settings.theme_id == "thiefmd") {
            return false;
        } else {
            return (current_palette.global.foreground == current_palette.link.foreground) &&
                    (current_palette.global.background == current_palette.link.background);
        }
    }

    public void get_focus_bg_color (out double r, out double g, out double b) {
        var settings = AppSettings.get_default ();
        Ultheme.Color background;
        if (current_palette == null || settings.theme_id == "thiefmd") {
            background = Ultheme.Color.from_string ("#FAFAFA");
        } else {
            background = Ultheme.Color.from_string (current_palette.global.background);
        }
        r = background.red / 255.0;
        g = background.green / 255.0;
        b = background.blue / 255.0;
    }

    public void get_focus_color (out double r, out double g, out double b) {
        var settings = AppSettings.get_default ();
        Ultheme.Color focus;
        if (current_palette == null || settings.theme_id == "thiefmd") {
            focus = Ultheme.Color.from_string ("#191919");
        } else {
            focus = Ultheme.Color.from_string (current_palette.global.foreground);
        }
        r = focus.red / 255.0;
        g = focus.green / 255.0;
        b = focus.blue / 255.0;
    }

    public void get_codeblock_bg_color (out double r, out double g, out double b) {
        var settings = AppSettings.get_default ();
        Ultheme.Color code_bg;
        if (current_palette == null || settings.theme_id == "thiefmd") {
            code_bg = Ultheme.Color.from_string ("#FAFAFA");
        } else {
            code_bg = Ultheme.Color.from_string (current_palette.code_block.background);
        }
        r = code_bg.red / 255.0;
        g = code_bg.green / 255.0;
        b = code_bg.blue / 255.0;
    }

    public void get_out_of_focus_color (out double r, out double g, out double b) {
        var settings = AppSettings.get_default ();
        Ultheme.Color background;
        Ultheme.Color foreground;
        if (current_palette == null || settings.theme_id == "thiefmd") {
            background = Ultheme.Color.from_string ("#FAFAFA");
            foreground = Ultheme.Color.from_string ("#191919");
        } else {
            background = Ultheme.Color.from_string (current_palette.global.background);
            foreground = Ultheme.Color.from_string (current_palette.global.foreground);
        }
        Ultheme.Color out_of_focus = foreground.interpolate (background, 0.82);
        r = out_of_focus.red / 255.0;
        g = out_of_focus.green / 255.0;
        b = out_of_focus.blue / 255.0;
    }

    public void load_font () {
        var settings = AppSettings.get_default ();
        if (font_provider != null) {
            var display = Gdk.Display.get_default ();
            if (display != null) {
                Gtk.StyleContext.remove_provider_for_display (display, font_provider);
            }
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
            font_provider.load_from_data ((uint8[]) new_font.data);
            var display = Gdk.Display.get_default ();
            if (display != null) {
                Gtk.StyleContext.add_provider_for_display (display, font_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            }
        } catch (Error e) {
            warning ("Error setting font: %s", e.message);
        }
    }

    public GtkSource.StyleSchemeManager UserSchemes () {
        if (thief_schemes == null) {
            thief_schemes = new GtkSource.StyleSchemeManager ();

            // Include default paths + user schemes + build/install scheme dir
            var default_paths = GtkSource.StyleSchemeManager.get_default ().get_search_path ();
            var custom_path = Path.build_filename (Build.PKGDATADIR, "gtksourceview-5", "styles");

            string[] paths = new string[default_paths.length + 2];
            for (int i = 0; i < default_paths.length; i++) {
                paths[i] = default_paths[i];
            }
            paths[default_paths.length] = UserData.scheme_path;
            paths[default_paths.length + 1] = custom_path;

            thief_schemes.set_search_path (paths);
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
        SheetManager.reapply_editor_theme ();

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
            var display = Gdk.Display.get_default ();
            if (display != null) {
                Gtk.StyleContext.remove_provider_for_display (display, active_provider);
            }
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
            var display = Gdk.Display.get_default ();
            if (display != null) {
                Gtk.StyleContext.remove_provider_for_display (display, active_provider);
            }
            active_provider = null;
        }

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/kmwallio/thiefmd/app-stylesheet.css");
        var display = Gdk.Display.get_default ();
        if (display != null) {
            Gtk.StyleContext.add_provider_for_display (display, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            active_provider = provider;
        }
        Adw.StyleManager.get_default().color_scheme = Adw.ColorScheme.FORCE_LIGHT;
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

        Ultheme.Color bg_active = Ultheme.Color.from_string (palette.global_active.background);
        Ultheme.Color bg_lighter = bg_active.lighten ().lighten ();
        debug ("Comparing %s to %s", palette.global.foreground, bg_lighter.to_string ());
        if (bg_lighter.to_string ().has_prefix (palette.global.foreground)) {
            bg_active = bg_active.darken ().darken ();
        }

        string new_css = ThiefProperties.DYNAMIC_CSS.printf (
            palette.global.background,
            bg_active.to_string ().substring (0, 7),
            palette.headers.foreground,
            palette.global_active.foreground,
            palette.global.foreground
        );

        try {
            var display = Gdk.Display.get_default ();
            if (display != null) {
                if (active_provider != null) {
                    Gtk.StyleContext.remove_provider_for_display (display, active_provider);
                    active_provider = null;
                }
                var provider = new Gtk.CssProvider ();
                provider.load_from_data ((uint8[]) new_css.data);
                Gtk.StyleContext.add_provider_for_display (display, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                active_provider = provider;
                remove_border_color ();
            }
        } catch (Error e) {
            warning ("Could not set dynamic css: %s", e.message);
        }
    }

    private void set_dark_mode_based_on_colors () {
        var settings = AppSettings.get_default ();

        if (current_palette != null && settings.theme_id != "thiefmd") {
            // Use luminance to determine if the background is dark or light as some themes
            // include 2 dark themes or 2 light themes
            Ultheme.Color color = Ultheme.Color.from_string (current_palette.global.background);
            double hue, lum, sat;
            color.to_hls (out hue, out lum, out sat);

            // Set dark theme
            Adw.StyleManager.get_default().color_scheme = (lum < 0.5) ? Adw.ColorScheme.FORCE_DARK : Adw.ColorScheme.FORCE_LIGHT;
        } else {
            if (settings.theme_id != "thiefmd") {
                Adw.StyleManager.get_default().color_scheme = settings.dark_mode ? Adw.ColorScheme.FORCE_DARK : Adw.ColorScheme.FORCE_LIGHT;
            } else {
                Adw.StyleManager.get_default().color_scheme = Adw.ColorScheme.FORCE_LIGHT;
            }
        }
    }

    //
    // ThiefMD Custom GtkSourceView Languages
    //
    private GtkSource.LanguageManager thief_languages;

    public GtkSource.LanguageManager get_language_manager () {
        if (thief_languages == null) {
            thief_languages = new GtkSource.LanguageManager ();
            string custom_languages = Path.build_path (
                Path.DIR_SEPARATOR_S,
                Build.PKGDATADIR,
                "gtksourceview-5",
                "language-specs");
            string[] language_paths = {
                custom_languages
            };
            thief_languages.set_search_path (language_paths);

            var markdown = thief_languages.get_language ("markdown");
            if (markdown == null) {
                warning ("Could not load custom languages");
                thief_languages = GtkSource.LanguageManager.get_default ();
            }
        }

        return thief_languages;
    }

    public GtkSource.Language get_source_language (string filename = "something.md") {
        var languages = get_language_manager ();
        GtkSource.Language? language = null;
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
        settings.view_state = 2;
        show_view ();
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
        settings.view_state = (settings.view_state + 1) % 3;
        show_view ();
    }

    public void show_view () {
        var settings = AppSettings.get_default ();

        if (!_init) {
            _init = true;
            _show_filename = settings.show_filename;
        }

        if (!ThiefApp.get_instance ().ready) {
            return;
        }
        var instance = ThiefApp.get_instance ();
        instance.show_touch_friendly = settings.view_state == 2;
        instance.hide_search ();
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
            instance.library_split.set_end_child (current);
            instance.library_split.set_position (settings.view_library_width);
            instance.library_pane.set_visible_child (instance.library_split);
            instance.library_pane.show ();
        }
        instance.library_box.show ();
        instance.main_content.set_position (settings.view_library_width + settings.view_sheets_width);
    }

    public void hide_library () {
        var settings = AppSettings.get_default ();
        ThiefApp instance = ThiefApp.get_instance ();
        if (current != null) {
            current.show ();
            current.width_request = settings.view_sheets_width;
            instance.library_split.set_end_child (current);
        }
        instance.library_box.hide ();
            instance.set_library_split_position_silent (0);
        instance.library_pane.set_visible_child (instance.library_split);
        instance.library_pane.show ();
        instance.set_main_position_silent (settings.view_sheets_width);
    }

    // Show all three panels
    public void show_sheets_and_library () {
        var settings = AppSettings.get_default ();
        ThiefApp instance = ThiefApp.get_instance ();
        if (current != null) {
            current.show ();
            current.width_request = settings.view_sheets_width;
            instance.library_box.show ();
            instance.library_box.width_request = settings.view_library_width;
                instance.set_library_split_position_silent (settings.view_library_width);
            instance.library_pane.set_visible (true);
            instance.library_pane.set_visible_child (instance.library_split);
        }
        instance.library_pane.show ();
        instance.set_main_position_silent (settings.view_library_width + settings.view_sheets_width);
    }

    // Show just the Editor
    public void hide_sheets () {
        ThiefApp instance = ThiefApp.get_instance ();
        instance.library_pane.hide ();
        instance.set_main_position_silent (0);
    }
}