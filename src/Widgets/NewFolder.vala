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
    public class NewFolder : Gtk.Popover {
        public Gtk.Label _label;
        public Gtk.Entry _file_name;
        public Gtk.Button _create;

        public NewFolder () {
            _file_name = new Gtk.Entry ();
            _file_name.set_placeholder_text (_("Folder name"));
            _file_name.activate.connect (new_folder);

            _create = new Gtk.Button.with_label (_("mkdir"));

            var menu_grid = new Gtk.Grid ();
            menu_grid.margin = 6;
            menu_grid.row_spacing = 6;
            menu_grid.column_spacing = 12;
            menu_grid.orientation = Gtk.Orientation.HORIZONTAL;

            menu_grid.attach (_file_name, 0, 0, 2, 1);
            menu_grid.attach (_create, 3, 0, 1, 1);

            menu_grid.show_all ();

            add (menu_grid);

            _create.clicked.connect (new_folder);
        }

        public void new_folder () {
            string file_name = _file_name.get_text ().chomp ();
            _file_name.set_text ("");

            if (file_name == "") {
                return;
            }

            ThiefApp.get_instance ().library.new_folder (file_name);
            this.hide ();
        }
    }
}