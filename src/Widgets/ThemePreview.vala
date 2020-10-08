/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified September 8, 2020
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
using ThiefMD.Controllers;

namespace ThiefMD.Widgets {
    public class CssPreview : Gtk.ToggleButton {
        private Gtk.OffscreenWindow prev_window;
        private Preview preview;
        private bool print_css;
        private string css_name;

        public CssPreview (string css, bool is_print) {
            preview = new Preview ();
            css_name = css;
            print_css = is_print;
            prev_window = new Gtk.OffscreenWindow ();
            preview.print_only = is_print;
            preview.override_css = css;
            preview.update_html_view (false, ThiefProperties.PREVIEW_CSS_MARKDOWN.printf (make_title(css != "" ? css : "None")));
            preview.hexpand = true;
            preview.vexpand = true;
            preview.zoom_level = 0.25;
            prev_window.set_size_request (Constants.CSS_PREVIEW_WIDTH, Constants.CSS_PREVIEW_HEIGHT);
            set_size_request (Constants.CSS_PREVIEW_WIDTH, Constants.CSS_PREVIEW_HEIGHT);

            add (preview);

            clicked.connect (() => {
                switch_to_this_css ();
            });

            var settings = AppSettings.get_default ();
            settings.changed.connect (() => {
                set_preview_state ();
            });
            set_preview_state ();
        }

        private void switch_to_this_css () {
            var settings = AppSettings.get_default ();

            if (print_css) {
                settings.print_css = css_name;
            } else {
                settings.preview_css = css_name;
            }
        }

        private void set_preview_state () {
            var settings = AppSettings.get_default ();
            if (settings.print_css == css_name && print_css) {
                active = true;
            } else if (settings.preview_css == css_name && !print_css) {
                active = true;
            } else {
                active = false;
            }
        }
    }

    public class ThemePreview : Gtk.ToggleButton {
        private Ultheme.Parser theme;
        private Gtk.SourceView view;
        private Gtk.SourceBuffer buffer;
        private bool am_dark;
        private Ultheme.HexColorPalette palette;

        public ThemePreview (Ultheme.Parser parser, bool is_dark) {
            var settings = AppSettings.get_default ();
            theme = parser;
            am_dark = is_dark;

            margin = 0;
            view = new Gtk.SourceView ();
            view.margin = 0;
            buffer = new Gtk.SourceBuffer.with_language (UI.get_source_language ());
            buffer.highlight_syntax = true;
            view.editable = false;
            view.set_buffer (buffer);
            view.set_wrap_mode (Gtk.WrapMode.WORD);
            buffer.text = ThiefProperties.PREVIEW_TEXT.printf(theme.get_theme_name ());
            add (view);

            if (am_dark) {
                string dark_path = Path.build_filename (UserData.scheme_path, theme.get_dark_theme_id () + ".xml");
                File dark_file = File.new_for_path (dark_path);
                if (!dark_file.query_exists ()) {
                    try {
                        FileManager.save_file (dark_file, theme.get_dark_theme ().data);
                    } catch (Error e) {
                        warning ("Could not save local scheme: %s", e.message);
                    }
                }
                set_scheme (theme.get_dark_theme_id ());
            } else {
                string light_path = Path.build_filename (UserData.scheme_path, theme.get_light_theme_id () + ".xml");
                File light_file = File.new_for_path (light_path);
                if (!light_file.query_exists ()) {
                    try {
                        FileManager.save_file (light_file, theme.get_light_theme ().data);
                    } catch (Error e) {
                        warning ("Could not save local scheme: %s", e.message);
                    }
                }
                set_scheme (theme.get_light_theme_id ());
            }

            set_preview_state ();

            clicked.connect (() => {
                switch_to_this_scheme ();
            });

            settings.changed.connect (() => {
                set_preview_state ();
            });

            show_all ();
        }

        private void set_preview_state () {
            var settings = AppSettings.get_default ();
            if (settings.theme_id == theme.get_dark_theme_id () && am_dark) {
                active = true;
            } else if (settings.theme_id == theme.get_light_theme_id () && !am_dark) {
                active = true;
            } else {
                active = false;
            }
        }

        private static string theme_to_switch_to;
        private static bool switch_to_dark = true;
        private static bool trying = false;
        public static Mutex switcher_mutex;

        private bool switch_theme () {
            var settings = AppSettings.get_default ();
            // Since switching to GLib.Settings, not seeing the retry
            // issues anymore.
            //if (settings.can_update_theme ()) {
                switcher_mutex.lock ();
                settings.dark_mode = switch_to_dark;
                settings.custom_theme = theme_to_switch_to;
                trying = false;
                switcher_mutex.unlock ();
            //}

            //  settings.dark_mode = switch_to_dark;
            //  settings.custom_theme = theme_to_switch_to;

            return trying;
        }

        private void switch_to_this_scheme () {
            var settings = AppSettings.get_default ();
            if (am_dark) {
                settings.theme_id = theme.get_dark_theme_id ();
                theme.get_dark_theme_palette (out palette);
            } else {
                settings.theme_id = theme.get_light_theme_id ();
                theme.get_light_theme_palette (out palette);
            }

            if (!settings.can_update_theme ()) {
                warning ("Theme cannot be updated, will schedule retry");
                if (!trying && switcher_mutex.trylock ()) {
                    theme_to_switch_to = theme.base_file_name ();
                    switch_to_dark = am_dark;
                    trying = true;
                    Timeout.add (250, switch_theme);
                    switcher_mutex.unlock ();
                }
            }

            settings.dark_mode = am_dark;
            settings.custom_theme = theme.base_file_name ();

            UI.set_css_scheme (palette);
            SheetManager.refresh_scheme ();
        }

        public void set_text (string text) {
            buffer.text = text;
        }

        public void set_scheme (string scheme) {
            UI.UserSchemes ().force_rescan ();
            var style = UI.UserSchemes ().get_scheme (scheme);
            buffer.set_style_scheme (style);
        }
    }
}