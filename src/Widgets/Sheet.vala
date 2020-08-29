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
    /**
     * Sheet
     * 
     * Button Widget pointing to a file on the system.
     */
    public class Sheet : Gtk.Button {
        private string _sheet_path;
        private bool _selected;
        private Gtk.Label _label;
        private string _label_buffer;
        private Sheets _parent;

        public bool active {
            set {
                var header_context = this.get_style_context ();
                if (value) {
                    header_context.add_class ("thief-list-sheet-active");
                } else {
                    header_context.remove_class ("thief-list-sheet-active");
                }
            }
        }

        public Sheet (string sheet_path, Sheets parent) {
            _sheet_path = sheet_path;
            _parent = parent;
            _label_buffer = "<b>" + sheet_path.substring(sheet_path.last_index_of("/") + 1) + "</b>";
            _label = new Gtk.Label(_label_buffer);
            _label.use_markup = true;
            _label.set_ellipsize (Pango.EllipsizeMode.END);
            _label.xalign = 0;

            var header_context = this.get_style_context ();
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);
            header_context.add_class ("thief-list-sheet");

            add(_label);

            clicked.connect (() => {
                debug ("Clicked\n");
                SheetManager.load_sheet (this);
            });

            redraw ();
            show_all ();
            debug ("Creating %s\n", sheet_path);
        }

        public Sheets get_parent_sheets () {
            return _parent;
        }

        public void redraw () {
            Preview.update_view ();
            string file_contents = FileManager.get_file_lines_yaml (_sheet_path, Constants.SHEET_PREVIEW_LINES);
            if (file_contents.chomp() != "") {
                _label_buffer = "<small>" + SheetManager.mini_mark(file_contents) + "</small>";
            } else {
                _label_buffer = "<b>" + _sheet_path.substring(_sheet_path.last_index_of("/") + 1) + "</b>";
            }
            _label.set_label (_label_buffer);
        }

        public override bool button_press_event(Gdk.EventButton event) {
            base.button_press_event (event);

            if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) {
                Gtk.Menu menu = new Gtk.Menu ();
                Gtk.MenuItem menu_item = new Gtk.MenuItem.with_label ("Remove from Library");
                menu.attach_to_widget (this, null);
                menu.add (menu_item);
                menu_item.activate.connect (() => {
                    var settings = AppSettings.get_default ();
                    debug ("Got remove for sheet");
                });
                menu.show_all ();
                menu.popup (null, null, null, event.button, event.time);
            }
            return true;
        }

        public string file_path () {
            return _sheet_path;
        }
    }
}
