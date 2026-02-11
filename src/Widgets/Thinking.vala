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
    public delegate void ThinkingCallback ();
    public class Thinking : Gtk.Dialog {
        private ThinkingCallback work = null;
        private Mutex running;
        private string message;

        public Thinking (string set_title, owned ThinkingCallback callback, Gee.List<string>? messages = null, Gtk.Window? parent = null) {
            set_transient_for ((parent == null) ? ThiefApp.get_instance () : parent);
            resizable = false;
            deletable = false;
            modal = true;
            work = (owned) callback;
            running = Mutex ();
            title = set_title;
            if (messages == null || messages.is_empty) {
                message = "";
            } else {
                message = messages.get (Random.int_range(0, messages.size));
            }
            build_ui ();
        }

        private void build_ui () {
            set_child (build_thinking_ui ());
            Timeout.add (500, run_and_done);
        }

        public void run () {
            present ();
        }

        private bool run_and_done () {
            if (work == null) {
                return true;
            } else {
                if (running.trylock ()) {
                    debug ("Doing work.");
                    work ();
                    running.unlock ();
                    this.destroy ();
                }
                return false;
            }
        }

        private Gtk.Grid build_thinking_ui () {
            Gtk.Grid grid = new Gtk.Grid ();
            grid.margin_top = 12;
            grid.margin_bottom = 12;
            grid.margin_start = 12;
            grid.margin_end = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.hexpand = true;
            grid.vexpand = true;

            var icon = new Gtk.Image.from_icon_name ("com.github.kmwallio.thiefmd");
            icon.set_pixel_size (128);
            grid.attach (icon, 1, 1);

            var stealing_label = new Gtk.Label ((message != "") ? "<b>" + message + "</b>" : _("<b>Stealing file contents...</b>"));
            stealing_label.use_markup = true;
            stealing_label.hexpand = true;
            grid.attach (stealing_label, 1, 2);

            return grid;
        }
    }
}