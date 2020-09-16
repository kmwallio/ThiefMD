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

    //
    // Sheets Management
    //
    TimedMutex preview_mutex;
    public void update_preview () {
        if (preview_mutex == null) {
            preview_mutex = new TimedMutex (250);
        }

        if (preview_mutex.can_do_action ()) {
            Preview.get_instance ().update_html_view (true, SheetManager.get_markdown ());
        }
    }

    // Switches Sheets shown in the Library view with the
    // provided sheet
    public Sheets set_sheets (Sheets sheet) {
        if (sheet == null) {
            return sheet;
        }
        ThiefApp instance = ThiefApp.get_instance ();
        var old = instance.library_pane.get_child2 ();
        int cur_pos = instance.library_pane.get_position ();
        if (old != null) {
            instance.library_pane.remove (old);
        }
        instance.library_pane.add2 (sheet);
        instance.library_pane.set_position (cur_pos);
        instance.library_pane.get_child2 ().show_all ();
        return (Sheets) old;
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

    public void load_user_themes () {
        if (user_themes != null) {
            return;
        }

        load_css_scheme ();
        user_themes = new List<Ultheme.Parser> ();
        if (!Thread.supported ()) {
            warning ("No threads available for work");
            GLib.Idle.add (load_themes);
        } else {
            theme_worker_thread = new Thread<bool>("theme_worker_thread", load_themes);
        }
    }

    private bool need_to_update_theme (string contents, File file) {
        string new_theme = Checksum.compute_for_string (ChecksumType.MD5, contents);
        string old_text;
        try {
            GLib.FileUtils.get_contents (file.get_path (), out old_text);
            string old_theme = Checksum.compute_for_string (ChecksumType.MD5, old_text);

            return new_theme == old_theme;
        } catch (Error e) {
            return true;
        }
    }

    private bool load_themes () {
        // Load previous added themes
        debug ("Loading themes");
        try {
            Dir theme_dir = Dir.open (UserData.style_path, 0);
            string? file_name = null;
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

    public Gtk.SourceStyleSchemeManager UserSchemes () {
        if (thief_schemes == null) {
            thief_schemes = new Gtk.SourceStyleSchemeManager ();
        }

        return thief_schemes;
    }

    public void load_css_scheme () {
        var settings = AppSettings.get_default ();
        Ultheme.HexColorPalette palette;
        debug ("Using %s", settings.custom_theme);
        if (settings.ui_editor_theme && settings.theme_id != "thiefmd") {
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
                } catch (Error e) {
                    warning ("Could not load previous style: %s", e.message);
                }
            }
        }
    }

    public void reset_css () {
        var settings = AppSettings.get_default ();

        try {
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/com/github/kmwallio/thiefmd/app-stylesheet.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
        } catch (Error e) {
            warning ("Could not set dynamic css: %s", e.message);
        }

        SheetManager.refresh_scheme ();
    }

    public void set_css_scheme (Ultheme.HexColorPalette palette) {
        var settings = AppSettings.get_default ();
        if (palette == null || !settings.ui_editor_theme) { 
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
            var provider = new Gtk.CssProvider ();
            provider.load_from_data (new_css);
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.dark_mode;
        } catch (Error e) {
            warning ("Could not set dynamic css: %s", e.message);
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
                "gtksourceview-3.0",
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

    public Gtk.SourceLanguage get_source_language () {
        var languages = get_language_manager ();

        var markdown_syntax = languages.get_language ("markdown");
        if (markdown_syntax == null) {
            markdown_syntax = languages.guess_language (null, "text/markdown");
        }

        return markdown_syntax;
    }

    //
    // Switching Main Window View
    //

    // Cycle through views
    public void toggle_view () {
        var settings = AppSettings.get_default ();
        ThiefApp instance = ThiefApp.get_instance ();

        if (!_init) {
            _init = true;
            _show_filename = settings.show_filename;
        }

        if (moving ()) {
            return;
        }

        settings.view_state = (settings.view_state + 1) % 3;

        if (settings.view_state == 2) {
            settings.view_sheets_width = instance.sheets_pane.get_position ();
        } else if (settings.view_state == 1) {
            int target_sheets = instance.sheets_pane.get_position () - instance.library_pane.get_position ();
            settings.view_sheets_width = target_sheets;
            settings.view_library_width = instance.library_pane.get_position ();
        }

        show_view ();
    }

    public void show_view () {
        var settings = AppSettings.get_default ();

        if (!_init) {
            _init = true;
            _show_filename = settings.show_filename;
        }

        if (moving ()) {
            return;
        }

        if (settings.view_state == 0) {
            settings.show_filename = _show_filename;

            if (settings.view_library_width <= 10) {
                settings.view_library_width = 200;
            }

            if (settings.view_sheets_width <= 10) {
                settings.view_sheets_width = 200;
            }

            show_sheets_and_library ();
            debug ("Show both\n");
        } else if (settings.view_state == 1) {
            hide_library ();
            debug ("Show sheets\n");
        } else if (settings.view_state == 2) {
            hide_sheets ();
            debug ("Show editor\n");
            _show_filename = settings.show_filename;
            settings.show_filename = true;
        }
        debug ("View mode: %d\n", settings.view_state);
    }

    // Switch to showing Editor + Sheets
    public void show_sheets () {
        var settings = AppSettings.get_default ();
        ThiefApp instance = ThiefApp.get_instance ();

        instance.library_pane.show ();
        instance.library_pane.get_child1 ().show ();
        instance.library_pane.get_child2 ().show_all ();

        debug ("Showing sheets (%d)\n", instance.sheets_pane.get_position ());
        move_panes(0, settings.view_sheets_width);
    }

    public void hide_library () {
        var settings = AppSettings.get_default ();
        ThiefApp instance = ThiefApp.get_instance ();

        instance.library_pane.show ();
        instance.library_pane.get_child1 ().show ();
        instance.library_pane.get_child2 ().show_all ();

        debug ("Hiding library (%d)\n", instance.library_pane.get_position ());
        if (instance.library_pane.get_position () > 0 || instance.sheets_pane.get_position () <= 0) {
            _moving.moving = false;
            int target_sheets = 0;
            if (instance.library_pane.get_position () > 0) {
                target_sheets = instance.sheets_pane.get_position () - instance.library_pane.get_position ();
            } else {
                if (instance.sheets_pane.get_position () > 0) {
                    target_sheets = instance.sheets_pane.get_position ();
                } else {
                    target_sheets = settings.view_sheets_width;
                }
            }

            move_panes (0, target_sheets);
        }

        _moving.connect (() => {
            // Second instance because instance above goes out of scope
            // leading to segfault?
            ThiefApp instance2 = ThiefApp.get_instance ();
            instance2.library_pane.get_child1 ().hide ();
        });
    }

    // Show all three panels
    public void show_sheets_and_library () {
        var settings = AppSettings.get_default ();
        ThiefApp instance = ThiefApp.get_instance ();

        instance.library_pane.show ();
        instance.library_pane.get_child1 ().show ();
        instance.library_pane.get_child2 ().show_all ();

        move_panes (settings.view_library_width, settings.view_sheets_width + settings.view_library_width);
    }

    // Show just the Editor
    public void hide_sheets () {
        ThiefApp instance = ThiefApp.get_instance ();

        debug ("Hiding sheets (%d)\n", instance.sheets_pane.get_position ());

        _moving.connect (() => {
            // Second instance because instance above goes out of scope
            // leading to segfault?
            ThiefApp instance2 = ThiefApp.get_instance ();
            instance2.library_pane.get_child2 ().hide ();
            instance2.library_pane.hide ();
        });
        move_panes(0, 0);
    }

    // There's totally a GTK thing that supports animation, but I haven't found where to
    // steal the code from yet
    private int _hop_sheets = 0;
    private int _hop_library = 0;
    private void move_panes (int library_pane, int sheet_pane) {
        ThiefApp instance = ThiefApp.get_instance ();

        if (moving ()) {
            return;
        }

        _moving.moving = true;

        _hop_sheets = (int)((sheet_pane - instance.sheets_pane.get_position ()) / Constants.ANIMATION_FRAMES);
        _hop_library = (int)((library_pane - instance.library_pane.get_position ()) / Constants.ANIMATION_FRAMES);

        debug ("Sheets (%d, %d), Library (%d, %d)\n", sheet_pane, instance.sheets_pane.get_position (), library_pane, instance.library_pane.get_position ());

        debug ("Sheets hop: %d, Library Hop: %d\n", _hop_sheets, _hop_library);

        Timeout.add ((int)(Constants.ANIMATION_TIME / Constants.ANIMATION_FRAMES), () => {
            int next_sheets = instance.sheets_pane.get_position () + _hop_sheets;
            int next_library = instance.library_pane.get_position () + _hop_library;
            bool sheet_done = false;
            bool lib_done = false;

            if (!_moving.moving) {
                // debug ("No longer moving\n");
                _moving.moving = false;
                return false;
            }

            // debug ("Sheets move: (%d, %d), Library move: (%d, %d)\n", next_sheets, _hop_sheets, next_library, _hop_library);

            if ((_hop_sheets > 0) && (next_sheets >= sheet_pane)) {
                instance.sheets_pane.set_position (sheet_pane);
                sheet_done = true;
            } else if ((_hop_sheets < 0) && (next_sheets <= sheet_pane)) {
                instance.sheets_pane.set_position (sheet_pane);
                sheet_done = true;
            } else {
                instance.sheets_pane.set_position (next_sheets);
            }
            sheet_done = sheet_done || (_hop_sheets == 0);

            if ((_hop_library > 0) && (next_library >= library_pane)) {
                instance.library_pane.set_position (library_pane);
                lib_done = true;
            } else if ((_hop_library < 0) && (next_library <= library_pane)) {
                instance.library_pane.set_position (library_pane);
                lib_done = true;
            } else {
                instance.library_pane.set_position (next_library);
            }
            lib_done = lib_done || (_hop_library == 0);

            // debug ("Sheets done: %s, Library done: %s\n", sheet_done ? "yes" : "no", lib_done ? "yes" : "no");

            _moving.moving = !lib_done || !sheet_done;
            if (!moving ()) {
                _moving.movement_done ();
                SheetManager.redraw ();
            }
            return _moving.moving;
        });
    }

    private delegate void MovementCallback ();
    private class Movement {
        public bool moving;
        private MovementCallback handler;
        public signal void movement_done ();

        public Movement () {
            moving = false;
            handler = do_nothing;

            movement_done.connect (() => {
                handler ();
                handler = do_nothing;
            });
        }

        public void do_nothing () {
            // avoid segfault?
        }

        public void connect (MovementCallback callback) {
            handler = callback;
        }
    }

    public bool moving () {
        if (_moving == null) {
            _moving = new Movement ();
        }

        return _moving.moving;
    }
    private static Movement _moving;
}