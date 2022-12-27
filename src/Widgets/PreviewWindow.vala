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
        private Preview html_view;

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
                    instance.title = _("Preview: ") + file_name;
                } else {
                    instance.title = _("Preview");
                }
                instance.toolbar.title = instance.title;
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
            toolbar = new Hdy.HeaderBar ();

            if (settings.show_filename && settings.last_file != "") {
                string file_name = settings.last_file.substring(settings.last_file.last_index_of (Path.DIR_SEPARATOR_S) + 1);
                instance.title = _("Preview: ") + file_name;
            } else {
                instance.title = _("Preview");
            }
            toolbar.title = title;

            Gtk.Box vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            toolbar.set_show_close_button (true);
            vbox.add (toolbar);
            html_view = new Preview();
            vbox.add (html_view);
            vbox.show_all ();
            add (vbox);

            delete_event.connect (this.hide_on_delete);
            settings.changed.connect (update_preview_title);

            UI.update_preview ();
            ThiefApp.get_instance ().get_size (out w, out h);
            set_default_size(w, h);
            show_all ();
            update ();
        }

        public bool on_delete_event () {
            var settings = AppSettings.get_default ();
            settings.changed.disconnect (update);
            remove (html_view);
            instance = null;
            html_view = null;
            return false;
        }
    }
}
