/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified September 1, 2020
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

namespace ThiefMD {
    public const int BYTE_BITS = 8;
    public const int WORD_BITS = 16;
    public const int DWORD_BITS = 32;

    /* GTK4 TODO: replace legacy target entries with Gtk.DropTarget usage */

    public static File dnd_get_file_from_string (string selection_text) {
        string file_to_parse = selection_text.chomp ();
        if (file_to_parse == "") {
            return File.new_for_path ("/dev/null/thiefmd");
        }

        if (file_to_parse.has_prefix ("file")) {
            var file = File.new_for_uri (file_to_parse);
            string? check_path = file.get_path ();
            if (check_path != null && check_path.chomp () != "") {
                file_to_parse = check_path.chomp ();
            } else {
                file_to_parse = "/dev/null/thiefmd";
            }
        }

        return File.new_for_path (file_to_parse);
    }

    public class PreventDelayedDrop : TimedMutex {
        public PreventDelayedDrop () {
            base (300);
        }

        public bool can_get_drop () {
            return can_do_action ();
        }
    }
}