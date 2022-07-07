/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified July 6, 2022
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
using ThiefMD.Controllers;

namespace ThiefMD {
    public class WelcomeWindow : Hdy.Window {
        public WelcomeWindow () {
            build_ui ();
        }

        private void build_ui () {
            var settings = AppSettings.get_default ();
            var h_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            var v_box = new Gtk.Grid ();
            v_box.margin = 6;
            v_box.row_spacing = 6;
            v_box.column_spacing = 12;
            v_box.orientation = Gtk.Orientation.VERTICAL;
            v_box.hexpand = true;
            v_box.vexpand = true;

            Hdy.HeaderBar bar = new Hdy.HeaderBar ();
            bar.title = _("Welcome to ThiefMD");
            bar.show_close_button = true;
            var header_context = bar.get_style_context ();
            header_context.add_class ("thief-toolbar");
            header_context.add_class("thiefmd-toolbar");

            var add_library_button = new Gtk.Button ();
            add_library_button.hexpand = true;
            add_library_button.vexpand = true;
            add_library_button.has_tooltip = true;
            add_library_button.tooltip_text = (_("Add Folder to Library"));
            add_library_button.label = "  " + (_("Add Folder to Library"));
            add_library_button.set_image (new Gtk.Image.from_icon_name ("folder-new-symbolic", Gtk.IconSize.DIALOG));
            add_library_button.always_show_image = true;
            add_library_button.clicked.connect (() => {
                string new_lib = Dialogs.select_folder_dialog ();
                if (FileUtils.test(new_lib, FileTest.IS_DIR)) {
                    if (settings.add_to_library (new_lib)) {
                        // Refresh
                        ThiefApp instance = ThiefApp.get_instance ();
                        instance.refresh_library ();
                        ThiefApp.show_main_instance ();
                        this.close ();
                    }
                }
            });

            v_box.add (add_library_button);

            var open_solo_editor = new Gtk.Button ();
            open_solo_editor.hexpand = true;
            open_solo_editor.vexpand = true;
            open_solo_editor.has_tooltip = true;
            open_solo_editor.tooltip_text = (_("Open File"));
            open_solo_editor.label = "  " + (_("Open File"));
            open_solo_editor.set_image (new Gtk.Image.from_icon_name ("document-open-symbolic", Gtk.IconSize.DIALOG));
            open_solo_editor.always_show_image = true;
            open_solo_editor.clicked.connect (() => {
                File open_file = Dialogs.display_open_dialog (ThiefProperties.SUPPORTED_OPEN_FILES);
                if (open_file != null && open_file.query_exists ()) {
                    ThiefApplication.open_file (open_file);
                    this.close ();
                }
            });

            v_box.add (open_solo_editor);

            // Try to load library image
            try {
                var library = new Gtk.Image.from_resource ("/com/github/kmwallio/thiefmd/icons/library.png");
                h_box.add (library);
            } catch (Error e) {
                warning ("Could not load logo: %s", e.message);
            }
            h_box.add (v_box);

            var winbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            winbox.add (bar);
            winbox.add (h_box);

            delete_event.connect (this.on_delete_event);
            add (winbox);
            show_all ();
        }

        public bool on_delete_event () {
            ThiefApplication.close_window (this);
            return false;
        }
    }
}
