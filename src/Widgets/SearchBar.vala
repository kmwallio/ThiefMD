/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified October 9, 2020
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
    public class SearchBar : Gtk.Revealer {
        private Gtk.Entry search_text;
        private Gtk.Button next;
        private Gtk.Button prev;

        public SearchBar () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            build_ui ();
        }

        private void build_ui () {
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            var grid = new Gtk.Grid ();

            search_text = new Gtk.Entry ();
            next = new Gtk.Button.with_label ("->");
            prev = new Gtk.Button.with_label ("<-");

            grid.attach (search_text, 0, 0, 2, 1);
            grid.attach (prev, 2, 0, 1, 1);
            grid.attach (next, 3, 0, 1, 1);

            grid.show_all ();
            box.pack_end (grid);

            add (box);
            set_reveal_child (false);
            hexpand = true;
        }

        public void toggle_search () {
            if (child_revealed) {
                deactivate_search ();
            } else {
                activate_search ();
            }
        }

        public void deactivate_search () {
            set_reveal_child (false);
        }

        public void activate_search () {
            set_reveal_child (true);
        }
    }
}