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
    public class About : Dialog {
        private Gtk.Stack stack;
        private Gtk.HeaderBar bar;

        public About () {
            set_transient_for (ThiefApp.get_instance ().main_window);
            resizable = false;
            deletable = true;
            modal = true;
            build_ui ();
        }

        private void build_ui () {
            add_headerbar ();
            title = "";
            window_position = WindowPosition.CENTER;

            stack = new Stack ();
            stack.add_titled (build_about_ui (), _("About ThiefMD"), _("About"));
            stack.add_titled (build_credits_ui (), _("Credits"), _("Credits"));

            StackSwitcher switcher = new StackSwitcher ();
            switcher.set_stack (stack);
            switcher.halign = Align.CENTER;

            Box box = new Box (Orientation.VERTICAL, 0);

            bar.set_custom_title (switcher);
            box.add (stack);
            this.get_content_area().add (box);

            set_default_size (450, 450);

            add_button (_("Close"), Gtk.ResponseType.CLOSE);
            response.connect (() =>
            {
                destroy ();
            });

            show_all ();
        }

        private Gtk.Grid build_about_ui () {
            Grid grid = new Grid ();
            grid.margin = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.orientation = Orientation.VERTICAL;
            grid.hexpand = true;

            //  program_name = ThiefProperties.NAME;
            var name_label = new Gtk.Label (ThiefProperties.NAME);
            name_label.hexpand = true;
            grid.attach (name_label, 1, 2);
            //  comments = ThiefProperties.TAGLINE;
            var tag_label = new Gtk.Label (ThiefProperties.TAGLINE);
            tag_label.hexpand = true;
            grid.attach (tag_label, 1, 4);
            //  copyright = ThiefProperties.COPYRIGHT;
            var copy_label = new Gtk.Label ("<small>" + ThiefProperties.COPYRIGHT + "</small>");
            copy_label.hexpand = true;
            copy_label.use_markup = true;
            grid.attach (copy_label, 1, 6);
            //  version = ThiefProperties.VERSION;
            var version_label = new Gtk.Label (ThiefProperties.VERSION);
            version_label.hexpand = true;
            grid.attach (version_label, 1, 3);
            //  website = ThiefProperties.URL;
            var website_label = new Gtk.Label ("<a href='" + ThiefProperties.URL + "'>" + ThiefProperties.URL + "</a>");
            website_label.hexpand = true;
            website_label.use_markup = true;
            grid.attach (website_label, 1, 5);
            //  license_type = ThiefProperties.LICENSE_TYPE;
            var lic_label = new Gtk.Label ("<small>This program comes with absolutely no warranty.</small>");
            var lic_label2 = new Gtk.Label ("<small>See the <a href='https://www.gnu.org/licenses/gpl-3.0.html'>GNU General Public License, version 3 or later</a> for details.</small>");
            lic_label.hexpand = true;
            lic_label.use_markup = true;
            lic_label2.hexpand = true;
            lic_label2.use_markup = true;
            grid.attach (lic_label, 1, 7);
            grid.attach (lic_label2, 1, 8);

            try {
                IconTheme icon_theme = IconTheme.get_default();
                var thief_icon = icon_theme.load_icon("com.github.kmwallio.thiefmd", 128, IconLookupFlags.FORCE_SVG);
                var icon = new Gtk.Image.from_pixbuf (thief_icon);
                grid.attach (icon, 1, 1);
            } catch (Error e) {
                warning ("Could not load logo: %s", e.message);
            }

            grid.show_all ();

            return grid;
        }

        private Gtk.Grid build_credits_ui () {
            Grid grid = new Grid ();
            grid.margin = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.orientation = Orientation.VERTICAL;
            grid.hexpand = true;

            Gtk.ScrolledWindow scrl = new Gtk.ScrolledWindow (null, null);
            Gtk.Grid scrl_grid = new Grid ();
            int i = 1;
            int nat_w;
            foreach (var credit in ThiefProperties.GIANTS) {
                var credit_label = new Gtk.Label (credit);
                credit_label.hexpand = true;
                credit_label.use_markup = true;
                credit_label.xalign = 0;
                scrl_grid.attach (credit_label, 1, i);
                i++;
            }
            scrl.hexpand = true;
            scrl.vexpand = true;
            scrl.add (scrl_grid);

            grid.attach (scrl, 0, 0);

            return grid;
        }

        public void add_headerbar () {
            bar = new Gtk.HeaderBar ();
            bar.set_show_close_button (true);
            bar.set_title ("");

            this.set_titlebar(bar);
        }
    }
}