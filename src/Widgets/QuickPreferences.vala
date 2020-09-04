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
            typewriter_button.set_active (settings.typewriter_scrolling);

            typewriter_button.toggled.connect (() => {
                settings.typewriter_scrolling = typewriter_button.active;
            });

            var spellcheck_button = new Gtk.ToggleButton.with_label ((_("Check Spelling")));
            spellcheck_button.set_image (new Gtk.Image.from_icon_name ("tools-check-spelling", Gtk.IconSize.SMALL_TOOLBAR));
            spellcheck_button.set_always_show_image (true);
            spellcheck_button.tooltip_text = _("Toggle Spellcheck");
            spellcheck_button.set_active (settings.spellcheck);

            spellcheck_button.toggled.connect (() => {
                settings.spellcheck = spellcheck_button.active;
            });

            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            var separator2 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            var preview_button = new Gtk.ModelButton ();
            preview_button.text = (_("Preview"));
            preview_button.has_tooltip = true;
            preview_button.tooltip_text = _("Launch Preview");
            preview_button.clicked.connect (() => {
                PreviewWindow pvw = new PreviewWindow();
                pvw.run(null);
            });

            var preferences_button = new Gtk.ModelButton ();
            preferences_button.text = (_("Preferences"));
            preferences_button.has_tooltip = true;
            preferences_button.tooltip_text = _("Edit Preferences");
            preferences_button.clicked.connect (() => {
                Preferences prf = new Preferences(spellcheck_button, typewriter_button);
                prf.run();
            });

            var about_button = new Gtk.ModelButton ();
            about_button.text = (_("About"));
            about_button.has_tooltip = true;
            about_button.tooltip_text = _("About ThiefMD");
            about_button.clicked.connect (() => {
                About abt = new About();
                abt.run();
            });

            var menu_grid = new Gtk.Grid ();
            menu_grid.margin = 6;
            menu_grid.row_spacing = 6;
            menu_grid.column_spacing = 12;
            menu_grid.orientation = Gtk.Orientation.VERTICAL;
            menu_grid.add (typewriter_button);
            // menu_grid.add (separator);
            menu_grid.add (spellcheck_button);
            menu_grid.add (separator2);
            menu_grid.add (preview_button);
            menu_grid.add (preferences_button);
            menu_grid.add (about_button);
            menu_grid.show_all ();

            add (menu_grid);
        }
    }
}
