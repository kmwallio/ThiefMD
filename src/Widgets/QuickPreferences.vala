using ThiefMD;
using ThiefMD.Controllers;

namespace ThiefMD.Widgets {
    public class QuickPreferences : Gtk.Popover {
        public Gtk.Label _label;
        public Gtk.Entry _file_name;
        public Gtk.Button _create;

        public QuickPreferences () {
            var settings = AppSettings.get_default ();

            var typewriter_button = new Gtk.ToggleButton.with_label ((_("Typewriter Scrolling")));
            typewriter_button.set_image (new Gtk.Image.from_icon_name ("preferences-desktop-keyboard", Gtk.IconSize.SMALL_TOOLBAR));
            typewriter_button.set_always_show_image (true);
            typewriter_button.tooltip_text = _("Toggle Typewriter Scrolling");

            if (settings.typewriter_scrolling == false) {
                typewriter_button.set_active (false);
            } else {
                typewriter_button.set_active (settings.typewriter_scrolling);
            }

            typewriter_button.toggled.connect (() => {
    			if (typewriter_button.active) {
    				settings.typewriter_scrolling = true;
    			} else {
    				settings.typewriter_scrolling = false;
    			}

            });

            var menu_grid = new Gtk.Grid ();
            menu_grid.margin = 6;
            menu_grid.row_spacing = 6;
            menu_grid.column_spacing = 12;
            menu_grid.orientation = Gtk.Orientation.VERTICAL;
            menu_grid.add (typewriter_button);
            menu_grid.show_all ();

            add (menu_grid);
            show_all ();
        }
    }
}