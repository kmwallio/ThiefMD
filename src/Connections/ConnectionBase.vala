/*
 * Copyright (C) 2020 kmwallio
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the “Software”), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall
 * be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

using ThiefMD;
using ThiefMD.Widgets;
using ThiefMD.Controllers;
using ThiefMD.Exporters;

namespace ThiefMD.Connections {
    public class ConnectionData : Object {
        public string connection_type { get; set; }
        public string user { get; set; }
        public string auth { get; set; }
        public string endpoint { get; set; }
    }

    public abstract class ConnectionBase : Object {
        // Name to show in Export Window Drop Down
        public abstract string export_name { get; protected set; }

        // Compatible CSS for Exporter  { "preview", "print"}
        public abstract ExportBase exporter { get; protected  set; }

        public abstract bool connection_valid ();
        public abstract void connection_close ();
    }

    public class ConnectionError : Gtk.Dialog {
        private Gtk.Label message;

        public ConnectionError (Gtk.Window? win, string set_title, Gtk.Label body) {
            set_transient_for (win);
            modal = true;
            title = set_title;
            message = body;
            build_ui ();
        }

        // GTK4 shim for old run() callers
        public void run () {
            present ();
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
            icon.set_pixel_size (96);
            grid.attach (icon, 1, 1, 1, 1);

            grid.attach (message, 1, 2, 1, 1);

            Gtk.Button close = new Gtk.Button.with_label (_("Close"));
            grid.attach (close, 1, 3, 1, 1);

            close.clicked.connect (() => {
                this.destroy ();
            });

            response.connect (() => {
                this.destroy ();
            });

            return grid;
        }
    }
}
