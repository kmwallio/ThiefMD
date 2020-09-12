/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified September 2, 2020
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
using Gtk;
using Gdk;

namespace ThiefMD.Widgets {
    public class Preferences : Dialog {
        private Stack stack;

        public Preferences () {
            set_transient_for (ThiefApp.get_instance ().main_window);
            resizable = false;
            deletable = false;
            modal = true;
            build_ui ();
        }

        private void build_ui () {
            this.set_border_width (20);
            title = _("Preferences");
            window_position = WindowPosition.CENTER;

            stack = new Stack ();
            stack.add_titled (editor_grid (), "Editor Preferences", _("Editor"));
            stack.add_titled (display_grid (), "Display Preferences", _("Display"));

            StackSwitcher switcher = new StackSwitcher ();
            switcher.set_stack (stack);
            switcher.halign = Align.CENTER;

            Box box = new Box (Orientation.VERTICAL, 0);

            box.add (switcher);
            box.add (stack);
            this.get_content_area().add (box);

            add_button (_("Done"), Gtk.ResponseType.CLOSE);
            response.connect (() =>
            {
                destroy ();
            });

            show_all ();
        }

        private Grid display_grid () {
            Grid grid = new Grid ();
            grid.margin = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.orientation = Orientation.VERTICAL;
            grid.hexpand = true;

            ThemeSelector theme_selector = new ThemeSelector ();
            grid.add (theme_selector);
            grid.show_all ();

            return grid;
        }

        private Grid editor_grid () {
            var settings = AppSettings.get_default ();
            Grid grid = new Grid ();
            grid.margin = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.orientation = Orientation.VERTICAL;
            grid.hexpand = true;

            var spellcheck_switch = new Switch ();
            spellcheck_switch.set_active (settings.spellcheck);
            spellcheck_switch.notify["active"].connect (() => {
                settings.spellcheck = spellcheck_switch.get_active ();
            });
            spellcheck_switch.tooltip_text = _("Toggle Spellcheck");
            var spellcheck_label = new Label(_("Check Spelling"));
            spellcheck_label.xalign = 0;

            var typewriter_switch = new Switch ();
            typewriter_switch.set_active (settings.typewriter_scrolling);
            typewriter_switch.notify["active"].connect (() => {
                settings.typewriter_scrolling = typewriter_switch.get_active ();
            });
            typewriter_switch.tooltip_text = _("Toggle Spellcheck");
            var typewriter_label = new Label(_("Use TypeWriter Scrolling"));

            var ui_colorscheme_switch = new Switch ();
            ui_colorscheme_switch.set_active (settings.ui_editor_theme);
            ui_colorscheme_switch.notify["active"].connect (() => {
                settings.ui_editor_theme = ui_colorscheme_switch.get_active ();
                if (!settings.ui_editor_theme) {
                    UI.reset_css ();
                }
            });
            ui_colorscheme_switch.tooltip_text = _("Toggle UI Matching");
            var ui_colorscheme_label = new Label(_("Match UI to Editor Theme"));

            grid.attach (spellcheck_switch, 1, 0, 1, 1);
            grid.attach (spellcheck_label, 2, 0, 2, 1);
            grid.attach (typewriter_switch, 1, 1, 1, 1);
            grid.attach (typewriter_label, 2, 1, 2, 1);
            grid.attach (ui_colorscheme_switch, 1, 2, 1, 1);
            grid.attach (ui_colorscheme_label, 2, 2, 2, 1);
            grid.show_all ();

            return grid;
        }
    }
}