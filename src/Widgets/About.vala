/*
 * Copyright (C) 2020 kmwallio
 *
 * Modified February 17, 2026
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
    public class About : Adw.Dialog {
        private Gtk.Stack stack;
        private Adw.HeaderBar header;
        private Adw.ToolbarView toolbar_view;

        public About () {
            build_ui ();
        }

        private void build_ui () {
            toolbar_view = new Adw.ToolbarView ();
            set_child (toolbar_view);

            stack = new Stack ();
            stack.add_titled (build_about_ui (), _("About ThiefMD"), _("About"));
            stack.add_titled (build_credits_ui (), _("Credits"), _("Credits"));

            StackSwitcher switcher = new StackSwitcher ();
            switcher.set_stack (stack);
            switcher.halign = Align.CENTER;
            toolbar_view.set_content (stack);

            header = new Adw.HeaderBar ();
            header.set_title_widget (switcher);
            toolbar_view.add_top_bar (header);

            height_request = 450;

            closed.connect (() => {
                destroy ();
            });
        }

        private Gtk.Grid build_about_ui () {
            Grid grid = new Grid ();
            grid.margin_top = 12;
            grid.margin_bottom = 12;
            grid.margin_start = 12;
            grid.margin_end = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.orientation = Orientation.VERTICAL;
            grid.hexpand = true;

            // program_name = ThiefProperties.NAME;
            var name_label = new Gtk.Label (ThiefProperties.NAME);
            name_label.hexpand = true;
            grid.attach (name_label, 1, 2);
            // comments = ThiefProperties.TAGLINE;
            var tag_label = new Gtk.Label (ThiefProperties.TAGLINE);
            tag_label.hexpand = true;
            grid.attach (tag_label, 1, 4);
            // copyright = ThiefProperties.COPYRIGHT;
            var copy_label = new Gtk.Label ("<small>" + ThiefProperties.COPYRIGHT + "</small>");
            copy_label.hexpand = true;
            copy_label.use_markup = true;
            grid.attach (copy_label, 1, 6);
            // version = ThiefProperties.VERSION;
            var version_label = new Gtk.Label (ThiefProperties.VERSION);
            version_label.hexpand = true;
            grid.attach (version_label, 1, 3);
            // website = ThiefProperties.URL;
            var website_label = new Gtk.Label ("<a href='" + ThiefProperties.URL + "'>" + ThiefProperties.URL + "</a> - <a href='https://github.com/kmwallio/ThiefMD/discussions'>" + _("Feedback") + "</a>");
            website_label.hexpand = true;
            website_label.use_markup = true;
            grid.attach (website_label, 1, 5);
            // license_type = ThiefProperties.LICENSE_TYPE;
            var lic_label = new Gtk.Label ("<small>" + _("This program comes with absolutely no warranty.") + "</small>");
            var lic_label2 = new Gtk.Label ("<small>" + _("See the <a href='https://www.gnu.org/licenses/gpl-3.0.html'>GNU General Public License, version 3 or later</a> for details.") + "</small>");
            lic_label.hexpand = true;
            lic_label.use_markup = true;
            lic_label2.hexpand = true;
            lic_label2.use_markup = true;
            grid.attach (lic_label, 1, 7);
            grid.attach (lic_label2, 1, 8);

            var icon = new Gtk.Image.from_icon_name ("com.github.kmwallio.thiefmd");
            icon.set_pixel_size (128);
            grid.attach (icon, 1, 1);

            return grid;
        }

        private Gtk.Grid build_credits_ui () {
            Grid grid = new Grid ();
            grid.margin_top = 12;
            grid.margin_bottom = 12;
            grid.margin_start = 12;
            grid.margin_end = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.orientation = Orientation.VERTICAL;
            grid.hexpand = true;

            Gtk.ScrolledWindow scrl = new Gtk.ScrolledWindow ();
            Gtk.Grid scrl_grid = new Grid ();
            int i = 1;

            ThiefProperties.GIANTS.foreach ((credit) => {
                var credit_label = new Gtk.Label (credit);
                credit_label.hexpand = true;
                credit_label.use_markup = true;
                credit_label.xalign = 0;
                scrl_grid.attach (credit_label, 1, i);
                i++;
                return true;
            });
            scrl.hscrollbar_policy = Gtk.PolicyType.NEVER;
            scrl.hexpand = true;
            scrl.vexpand = true;
            scrl.set_child (scrl_grid);

            grid.attach (scrl, 0, 0);

            return grid;
        }
    }
}