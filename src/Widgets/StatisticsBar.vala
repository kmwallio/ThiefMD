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
    public class StatisticsBar : Gtk.Revealer {
        Gtk.Box statsbar;
        private Gtk.Label reading_time;
        private Gtk.Label active_file;
        string last_file;

        public class StatisticsBar () {
            build_ui ();
        }

        private void build_ui () {
            statsbar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            statsbar.hexpand = true;
            var header_context = statsbar.get_style_context ();
            header_context.add_class ("thiefmd-toolbar");

            reading_time = new Gtk.Label ("Statistics");
            reading_time.use_markup = true;
            reading_time.xalign = 1;
            statsbar.pack_end (reading_time);

            active_file = new Gtk.Label ("File");
            active_file.use_markup = true;
            active_file.xalign = 0;
            statsbar.pack_end (active_file);

            statsbar.show_all ();
            add (statsbar);
        }

        public void show_statistics () {
            if (child_revealed) {
                return;
            }

            var settings = AppSettings.get_default ();
            settings.show_writing_statistics = true;
            update_wordcount ();
            settings.writing_changed.connect (update_wordcount);
            settings.sheet_changed.connect (update_wordcount);
            set_reveal_child (true);
        }

        public void hide_statistics () {
            if (!child_revealed) {
                return;
            }

            var settings = AppSettings.get_default ();
            settings.show_writing_statistics = false;
            settings.writing_changed.disconnect (update_wordcount);
            settings.sheet_changed.disconnect (update_wordcount);
            set_reveal_child (false);
        }

        public void toggle_statistics () {
            if (child_revealed) {
                hide_statistics ();
            } else {
                show_statistics ();
            }
        }

        public void update_wordcount () {
            int wordcount, hours, minutes, seconds;
            SheetManager.get_word_count_stats (out wordcount, out hours, out minutes, out seconds);
            string working_on = SheetManager.get_current_file_path ();

            if (working_on == null) {
                working_on = _("No file opened");
            }

            if (wordcount > 0 && (hours + minutes + seconds == 0)) {
                seconds = 1;
            }

            reading_time.label = (_("%d %s %d %s and %d %s reading time.")).printf (
                hours, (hours == 1) ? _("hour") : _("hours"),
                minutes, (minutes == 1) ? _("minute") : _("minutes"),
                seconds, (seconds == 1) ? _("seconds") : _("seconds")
            );

            active_file.label = (_("%s : %d words.")).printf (
                get_base_library_path (working_on).replace (Path.DIR_SEPARATOR_S, " " + Path.DIR_SEPARATOR_S + " "),
                wordcount
            );

            if (wordcount == 0 && last_file != working_on) {
                last_file = working_on;
                Timeout.add (50, () => {
                    update_wordcount ();
                    return false;
                });
            }
        }
    }
}