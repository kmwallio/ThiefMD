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
using ThiefMD.Controllers;

namespace ThiefMD.Widgets {
    public class PreviewWindow : Adw.Window {
        private Adw.HeaderBar toolbar;
        private static PreviewWindow? instance = null;
        private Preview html_view;
        private Gtk.Box vbox;

        public PreviewWindow () {
            var settings = AppSettings.get_default ();
            instance = this;
            new KeyBindings (this, false);
            build_ui ();
            settings.changed.connect (update);
        }

        public static void update_preview_title ()
        {
            var settings = AppSettings.get_default ();
            if (instance != null)
            {
                if (settings.show_filename && settings.last_file != "") {
                    string file_name = settings.last_file.substring(settings.last_file.last_index_of(Path.DIR_SEPARATOR_S) + 1);
                    instance.title = "Preview: " + file_name;
                } else {
                    instance.title = "Preview";
                }
                instance.toolbar.set_title_widget (new Gtk.Label (instance.title));
            }
        }

        public static bool has_instance () {
            return instance != null;
        }

        public static PreviewWindow get_instance () {
            if (instance == null) {
                instance = new PreviewWindow ();
            }
            return instance;
        }

        public void update () {
            var settings = AppSettings.get_default ();
            html_view.update_html_view (true, SheetManager.get_markdown (), is_fountain (settings.last_file));
        }

        protected void build_ui () {
            var settings = AppSettings.get_default ();
            int w, h;
            toolbar = new Adw.HeaderBar ();

            if (settings.show_filename && settings.last_file != "") {
                string file_name = settings.last_file.substring(settings.last_file.last_index_of (Path.DIR_SEPARATOR_S) + 1);
                title = "Preview: " + file_name;
            } else {
                title = "Preview";
            }
            toolbar.set_title_widget (new Gtk.Label(title));

            vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            vbox.append (toolbar);
            html_view = new Preview();
            vbox.append (html_view);
            vbox.show ();
            set_content (vbox);

            settings.changed.connect (update_preview_title);

            UI.update_preview ();
            w = ThiefApp.get_instance ().get_size (Gtk.Orientation.HORIZONTAL);
            h = ThiefApp.get_instance ().get_size (Gtk.Orientation.VERTICAL);
            set_size_request (w, h);
            show ();
            update ();
        }

        public bool on_delete_event () {
            var settings = AppSettings.get_default ();
            settings.changed.disconnect (update);
            vbox.remove (html_view);
            instance = null;
            html_view = null;
            return false;
        }
    }
}
