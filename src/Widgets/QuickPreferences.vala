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

            var spellcheck_button = new Gtk.ToggleButton.with_label ((_("Check Spelling")));
            spellcheck_button.set_image (new Gtk.Image.from_icon_name ("tools-check-spelling", Gtk.IconSize.SMALL_TOOLBAR));
            spellcheck_button.set_always_show_image (true);
            spellcheck_button.tooltip_text = _("Toggle Spellcheck");

            if (settings.spellcheck == false) {
                spellcheck_button.set_active (false);
            } else {
                spellcheck_button.set_active (settings.spellcheck);
            }

            spellcheck_button.toggled.connect (() => {
                if (spellcheck_button.active) {
                    settings.spellcheck = true;
                } else {
                    settings.spellcheck = false;
                }
            });

            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            var separator2 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            var preview_button = new Gtk.Button.with_label ((_("Preview")));
            preview_button.has_tooltip = true;
            preview_button.tooltip_text = _("Launch Preview");
            preview_button.clicked.connect (() => {
                PreviewWindow pvw = new PreviewWindow();
                pvw.run(null);
            });

            var menu_grid = new Gtk.Grid ();
            menu_grid.margin = 6;
            menu_grid.row_spacing = 6;
            menu_grid.column_spacing = 12;
            menu_grid.orientation = Gtk.Orientation.VERTICAL;
            menu_grid.add (typewriter_button);
            menu_grid.add (separator);
            menu_grid.add (spellcheck_button);
            menu_grid.add (separator2);
            menu_grid.add (preview_button);
            menu_grid.show_all ();

            add (menu_grid);
        }
    }
}
