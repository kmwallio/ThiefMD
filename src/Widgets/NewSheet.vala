using ThiefMD;
using ThiefMD.Controllers;

namespace ThiefMD.Widgets {
    public class NewSheet : Gtk.Popover {
        public Gtk.Label _label;
        public Gtk.Entry _file_name;
        public Gtk.Button _create;

        public NewSheet () {
            _file_name = new Gtk.Entry ();
            _file_name.set_placeholder_text (_("Sheet name"));
            _file_name.activate.connect (new_file);

            _create = new Gtk.Button.with_label (_("Create"));

            var menu_grid = new Gtk.Grid ();
            menu_grid.margin = 6;
            menu_grid.row_spacing = 6;
            menu_grid.column_spacing = 12;
            menu_grid.orientation = Gtk.Orientation.VERTICAL;

            menu_grid.attach (_file_name, 0, 0, 2, 1);
            menu_grid.attach (_create, 1, 1, 1, 1);

            menu_grid.show_all ();

            add (menu_grid);

            _create.clicked.connect (new_file);
        }

        public void new_file () {
            string file_name = _file_name.get_text ().chomp ();
            _file_name.set_text ("");

            if (file_name == "") {
                return;
            }

            // Check for .md extension
            if (!file_name.ascii_down ().has_suffix(".md") && !file_name.ascii_down ().has_suffix(".markdown")) {
                file_name += ".md";
            }

            SheetManager.new_sheet(file_name);
        }
    }
}