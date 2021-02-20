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

using WebKit;
using ThiefMD;
using ThiefMD.Controllers;

namespace ThiefMD.Widgets {
    public class PreviewWindow : Hdy.Window {
        private Hdy.HeaderBar toolbar;
        private static PreviewWindow? instance = null;

        public PreviewWindow () {
            new KeyBindings (this, false);
            build_ui ();
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
                instance.toolbar.title = instance.title;
            }
        }

        public static PreviewWindow get_instance () {
            if (instance == null) {
                instance = new PreviewWindow ();
            }
            return instance;
        }

        protected void build_ui () {
            var settings = AppSettings.get_default ();
            int w, h, m, p;
            toolbar = new Hdy.HeaderBar ();

            if (settings.show_filename && settings.last_file != "") {
                string file_name = settings.last_file.substring(settings.last_file.last_index_of (Path.DIR_SEPARATOR_S) + 1);
                title = "Preview: " + file_name;
            } else {
                title = "Preview";
            }
            toolbar.title = title;
            UI.update_preview ();

            parent = ThiefApp.get_instance ();
            destroy_with_parent = true;
            ThiefApp.get_instance ().get_size (out w, out h);
            w = w - ThiefApp.get_instance ().pane_position;
            set_default_size(w, h - 150);

            Gtk.Box vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            toolbar.set_show_close_button (true);
            vbox.add (toolbar);
            vbox.add (Preview.get_instance ());
            add (vbox);

            delete_event.connect (this.hide_on_delete);
            instance = this;
            settings.changed.connect (update_preview_title);
        }

        public bool on_delete_event () {
            remove (Preview.get_instance ());
            show_all ();
            instance = null;

            return false;
        }
    }
}
