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
    public class ThemePreview : Gtk.Button {
        private Ultheme.Parser theme;
        private Gtk.SourceView view;
        private Gtk.SourceBuffer buffer;
        private bool am_dark;
        private Ultheme.HexColorPalette palette;

        public ThemePreview (Ultheme.Parser parser, bool is_dark) {
            theme = parser;
            am_dark = is_dark;
            var manager = Gtk.SourceLanguageManager.get_default ();
            var language = manager.guess_language (null, "text/markdown");
            margin = 0;
            view = new Gtk.SourceView ();
            view.margin = 0;
            buffer = new Gtk.SourceBuffer.with_language (language);
            buffer.highlight_syntax = true;
            view.editable = false;
            view.set_buffer (buffer);
            view.set_wrap_mode (Gtk.WrapMode.NONE);
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

            clicked.connect (() => {
                switch_to_this_scheme ();
            });

            show_all ();
        }

        private void switch_to_this_scheme () {
            var settings = AppSettings.get_default ();
            if (am_dark) {
                ThiefApp.get_instance ().edit_view_content.set_scheme (theme.get_dark_theme_id ());
                settings.theme_id = theme.get_dark_theme_id ();
            } else {
                ThiefApp.get_instance ().edit_view_content.set_scheme (theme.get_light_theme_id ());
                settings.theme_id = theme.get_light_theme_id ();
            }
        }

        public void set_text (string text) {
            buffer.text = text;
        }

        public void set_scheme (string scheme) {
            UI.thief_schemes.force_rescan ();
            var style = UI.thief_schemes.get_scheme (scheme);
            buffer.set_style_scheme (style);
        }
    }
}