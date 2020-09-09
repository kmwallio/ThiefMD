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

        // Change style depending on sheet available in the editor
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

            // Default to filename
            _label_buffer = "<b>" + sheet_path.substring(sheet_path.last_index_of("/") + 1) + "</b>";
            _label = new Gtk.Label(_label_buffer);
            _label.use_markup = true;
            _label.set_ellipsize (Pango.EllipsizeMode.END);
            _label.xalign = 0;
            add(_label);

            var header_context = this.get_style_context ();
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);
            header_context.add_class ("thief-list-sheet");

            clicked.connect (() => {
                debug ("Loading %s\n", _sheet_path);
                SheetManager.load_sheet (this);
            });

            // Add ability to be dragged
            Gtk.drag_source_set (
                this,                      // widget will be drag-able
                Gdk.ModifierType.BUTTON1_MASK, // modifier that will start a drag
                target_list,               // lists of target to support
                Gdk.DragAction.MOVE            // what to do with data after dropped
            );

            // All possible source signals
            this.drag_begin.connect(on_drag_begin);
            this.drag_data_get.connect(on_drag_data_get);
            this.drag_data_delete.connect(on_drag_data_delete);
            this.drag_end.connect(on_drag_end);

            // Load minimark if file has content
            redraw ();
            show_all ();
            debug ("Creating %s\n", sheet_path);
        }

        public Sheets get_parent_sheets () {
            return _parent;
        }

        public string file_path () {
            return _sheet_path;
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

        //
        // Click Menu Options
        //

        public override bool button_press_event(Gdk.EventButton event) {
            base.button_press_event (event);

            if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) {
                Gtk.Menu menu = new Gtk.Menu ();
                menu.attach_to_widget (this, null);

                Gtk.MenuItem menu_preview_sheet = new Gtk.MenuItem.with_label ((_("Preview")));
                menu.add (menu_preview_sheet);
                menu_preview_sheet.activate.connect (() => {
                    SheetManager.load_sheet (this);
                    PreviewWindow pvw = new PreviewWindow();
                    pvw.run(null);
                });

                menu.add (new Gtk.SeparatorMenuItem ());

                Gtk.MenuItem menu_delete_sheet = new Gtk.MenuItem.with_label ((_("Move to Trash")));
                menu.add (menu_delete_sheet);
                menu_delete_sheet.activate.connect (() => {
                    debug ("Got remove for sheet %s", _sheet_path);
                    _parent.remove_sheet (this);
                    FileManager.move_to_trash (_sheet_path);
                });
                menu.show_all ();
                menu.popup_at_pointer (event);
            }
            return true;
        }

        //
        // Drag and Drop Support
        //

        private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
            warning ("%s: on_drag_begin", widget.name);
        }

        private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
            Gtk.SelectionData selection_data,
            uint target_type, uint time)
        {
            warning ("%s: on_drag_data_get for %s", widget.name, _sheet_path);

            switch (target_type) {
                case Target.STRING:
                    selection_data.set (
                        selection_data.get_target(),
                        BYTE_BITS,
                        (uchar [])_sheet_path.to_utf8());
                break;
                default:
                    warning ("No known action to take.");
                break;
            }

            debug ("Done moving");
        }

        private void on_drag_data_delete (Gtk.Widget widget, Gdk.DragContext context) {
            warning ("%s: on_drag_data_delete for %s", widget.name, _sheet_path);
        }

        private void on_drag_end (Gtk.Widget widget, Gdk.DragContext context) {
            warning ("%s: on_drag_end for %s", widget.name, _sheet_path);
        }
    }
}
