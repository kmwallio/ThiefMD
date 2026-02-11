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
    public class SearchBar : Gtk.Box {
        private Gtk.Revealer revealer;
        private Gtk.Entry search_text;
        private Gtk.Button next;
        private Gtk.Button prev;
        private Gtk.Label matches;
        private Gtk.Box box;
        private bool searched = false;

        public SearchBar () {
            Object (orientation: Gtk.Orientation.VERTICAL, spacing: 0);
            revealer = new Gtk.Revealer ();
            revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            build_ui ();
        }

        private void build_ui () {
            box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

            matches = new Gtk.Label ("                           ");
            var header_context = matches.get_style_context ();
            header_context.add_class ("thief-search-matches");
            search_text = new Gtk.Entry ();
            header_context = search_text.get_style_context ();
            header_context.add_class ("thief-search-input");
            next = new Gtk.Button ();
            header_context = next.get_style_context ();
            header_context.add_class ("thief-search-button");
            var next_image = new Gtk.Image.from_icon_name ("go-next-symbolic");
            next_image.pixel_size = 16;
            next.set_child (next_image);
            prev = new Gtk.Button ();
            header_context = prev.get_style_context ();
            header_context.add_class ("thief-search-button");
            var prev_image = new Gtk.Image.from_icon_name ("go-next-rtl-symbolic");
            prev_image.pixel_size = 16;
            prev.set_child (prev_image);
            var close = new Gtk.Button ();
            header_context = close.get_style_context ();
            header_context.add_class ("thief-search-button");
            var close_image = new Gtk.Image.from_icon_name ("window-close-symbolic");
            close_image.pixel_size = 16;
            close.set_child (close_image);
            close.clicked.connect (() => {
                if (revealer.child_revealed) {
                    deactivate_search ();
                }
            });
            header_context = box.get_style_context ();
            header_context.add_class ("thief-search-box");

            //  grid.attach (search_text, 0, 0, 2, 1);
            //  grid.attach (prev, 2, 0, 1, 1);
            //  grid.attach (next, 3, 0, 1, 1);
            //  grid.hexpand = false;

            //  grid.show_all ();
            box.hexpand = true;
            box.append (matches);
            box.append (search_text);
            box.append (prev);
            box.append (next);
            box.append (close);
            box.set_visible (true);

            next.clicked.connect (() => {
                SheetManager.search_next ();
            });

            prev.clicked.connect (() => {
                SheetManager.search_prev ();
            });

            search_text.activate.connect (() => {
                if (!searched) {
                    SheetManager.search_for (search_text.text);
                    searched = true;
                }
                SheetManager.search_next ();
            });

            revealer.set_child (box);
            revealer.set_reveal_child (false);
            append (revealer);
            hexpand = true;
        }

        public void search_for (string term) {
            search_text.text = term;
            SheetManager.search_for (search_text.text);
        }

        public void set_match_count (int match_count) {
            if (match_count < 0) {
                matches.label = "";
            } else {
                matches.label = _("(%d occurences)").printf (match_count);
            }
            debug ("Have %d matches", match_count);
            box.show ();
        }

        public void toggle_search () {
            if (revealer.child_revealed) {
                deactivate_search ();
            } else {
                activate_search ();
            }
        }

        public bool should_escape_search () {
            return search_text.has_focus;
        }

        public bool search_enabled () {
            return (revealer.child_revealed && search_text.text.chug ().chomp () != "");
        }

        public string get_search_text () {
            return search_text.text;
        }

        public void deactivate_search () {
            set_match_count (-1);
            searched = false;
            search_text.changed.disconnect (update_text);
            SheetManager.search_for (null);
            revealer.set_reveal_child (false);
        }

        public void activate_search () {
            set_match_count (-1);
            search_text.changed.connect (update_text);
            search_text.grab_focus_without_selecting ();
            revealer.set_reveal_child (true);
        }

        private void update_text () {
            string search = search_text.text;
            searched = true;
            SheetManager.search_for (search);
        }
    }
}