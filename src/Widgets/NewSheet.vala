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
    public class NewSheet : Gtk.Popover {
        public Gtk.Label _label;
        public Gtk.Entry _file_name;
        public Gtk.Button _create;
        public Gtk.Button _import;

        public NewSheet () {
            _file_name = new Gtk.Entry ();
            Sheets? check = SheetManager.get_sheets ();
            string suggested_extension = ".md";
            if (check != null) {
                suggested_extension = check.guess_extension ();
            }
            _file_name.set_placeholder_text (_("Sheet name") + suggested_extension);
            _file_name.activate.connect (new_file);

            _create = new Gtk.Button.with_label (_("Create"));
            _import = new Gtk.Button.with_label (_("Import"));

            var menu_grid = new Gtk.Grid ();
            menu_grid.margin_top = 6;
            menu_grid.margin_bottom = 6;
            menu_grid.margin_start = 6;
            menu_grid.margin_end = 6;
            menu_grid.row_spacing = 6;
            menu_grid.column_spacing = 12;
            menu_grid.orientation = Gtk.Orientation.VERTICAL;

            menu_grid.attach (_file_name, 0, 0, 2, 1);
            menu_grid.attach (_import, 0, 1, 1, 1);
            menu_grid.attach (_create, 1, 1, 1, 1);

            set_child (menu_grid);

            _create.clicked.connect (new_file);
            _import.clicked.connect (() => {
                File? import_file = Dialogs.display_open_dialog (ThiefProperties.SUPPORTED_IMPORT_FILES);
                if (import_file != null && import_file.query_exists () && SheetManager.get_sheets () != null) {
                    this.hide ();
                    FileManager.import_file (import_file.get_path (), SheetManager.get_sheets ());
                }
            });
        }

        public void new_file () {
            string file_name = _file_name.get_text ().chomp ();
            _file_name.set_text ("");

            if (file_name == "") {
                return;
            }

            // Check for .valid extension
            if (!can_open_file (file_name)) {
                Sheets? check = SheetManager.get_sheets ();
                if (check == null) {
                    file_name += ".md";
                } else {
                    file_name += check.guess_extension ();
                }
            }

            SheetManager.new_sheet(file_name);
            this.hide ();
        }
    }
}