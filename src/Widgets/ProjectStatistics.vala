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
    public class ProjectStatitics : Gtk.Window {
        Gtk.HeaderBar headerbar;
        private int word_count = 0;
        private string monitor_path = "";
        private Gtk.Button refresh;
        private Gtk.Label word_label;
        private Gtk.Label reading_time;

        public ProjectStatitics (string path) {
            monitor_path = path;
            build_ui ();
        }

        private void build_ui () {
            var settings = AppSettings.get_default ();
            headerbar = new Gtk.HeaderBar ();
            headerbar.set_title (get_base_library_path (monitor_path).replace (Path.DIR_SEPARATOR_S, " " + Path.DIR_SEPARATOR_S + " "));
            var header_context = headerbar.get_style_context ();
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);
            header_context.add_class ("thief-toolbar");

            word_label = new Gtk.Label ("");
            word_label.xalign = 0;
            word_label.use_markup = true;

            reading_time = new Gtk.Label ("");
            reading_time.xalign = 0;
            reading_time.use_markup = true;

            var grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.margin = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.vexpand = true;
            grid.hexpand = true;

            grid.attach (word_label, 0, 0, 2, 1);
            grid.attach (reading_time, 0, 1, 2, 1);

            Gtk.Button export_button = new Gtk.Button.with_label (_("Export"));
            export_button.clicked.connect (() => {
                string novel = ThiefApp.get_instance ().library.get_novel (monitor_path);
                PublisherPreviewWindow ppw = new PublisherPreviewWindow (novel);
                ppw.show ();
            });

            Gtk.Button close_button = new Gtk.Button.with_label (_("Close"));
            close_button.clicked.connect (() => {
                settings.writing_changed.disconnect (update_wordcount);
                destroy ();
            });

            grid.attach (export_button, 0, 3, 1, 1);
            grid.attach (close_button, 1, 3, 1, 1);

            grid.show_all ();

            refresh = new Gtk.Button ();
            refresh.tooltip_text = _("Refresh Statistics");
            refresh.set_image (new Gtk.Image.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.LARGE_TOOLBAR));

            refresh.activate.connect (update_wordcount);
            headerbar.set_show_close_button (true);
            headerbar.pack_start (refresh);
            set_titlebar (headerbar);
            transient_for = ThiefApp.get_instance ();
            destroy_with_parent = true;
            add (grid);

            int w, h;
            ThiefApp.get_instance ().get_size (out w, out h);

            show_all ();

            settings.writing_changed.connect (update_wordcount);
            delete_event.connect (() => {
                settings.writing_changed.disconnect (update_wordcount);
                return false;
            });
        }

        public void update_wordcount () {
            if (!ThiefApp.get_instance ().library.file_in_library (monitor_path)) {
                var settings = AppSettings.get_default ();
                settings.writing_changed.disconnect (update_wordcount);
                destroy ();
                return;
            }
            word_count = ThiefApp.get_instance ().library.get_word_count_for_path (monitor_path);
            int timereadings = word_count / Constants.WORDS_PER_SECOND;
            int hours = timereadings / 3600;
            timereadings = timereadings % 3600;
            int minutes = timereadings / 60;
            timereadings = timereadings % 60;
            int seconds = timereadings;

            if (word_count > 0 && (hours + minutes + seconds == 0)) {
                seconds = 1;
            }

            word_label.label = "<b>" + word_count.to_string () + "</b> " + _("words");
            reading_time.label = _("<b>Reading Time:</b>\n%d %s\n%d %s\n%d %s").printf (
                hours, (hours == 1) ? _("Hour") : _("Hours"),
                minutes, (minutes == 1) ? _("Minute") : _("Minutes"),
                seconds, (seconds == 1) ? _("Seconds") : _("Seconds")
            );
        }
    }
}