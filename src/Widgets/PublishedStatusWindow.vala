/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified September 13, 2020
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
using ThiefMD.Widgets;
using ThiefMD.Controllers;
using ThiefMD.Exporters;
using Gdk;

namespace ThiefMD.Widgets {
    public class PublishedStatusWindow : Gtk.Dialog {
        private Gtk.Label message;

        public PublishedStatusWindow (PublisherPreviewWindow win, string set_title, Gtk.Label body) {
            set_transient_for (win);
            modal = true;
            title = set_title;
            message = body;
            build_ui ();
        }

        private void build_ui () {
            set_child (build_message_ui ());
        }

        private Gtk.Grid build_message_ui () {
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

            grid.attach (message, 1, 2);

            Gtk.Button close = new Gtk.Button.with_label (_("Close"));
            grid.attach (close, 1, 3);

            close.clicked.connect (() => {
                this.destroy ();
            });

            response.connect (() => {
                this.destroy ();
            });
            return grid;
        }

        public void run () {
            present ();
        }
    }
}