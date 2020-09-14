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

using Gtk;
using Gdk;

namespace ThiefMD {
    public const int BYTE_BITS = 8;
    public const int WORD_BITS = 16;
    public const int DWORD_BITS = 32;

    public enum Target {
        STRING,
        URI
    }

    public const TargetEntry[] target_list = {
        { "STRING" , 0, Target.STRING },
        { "text/uri-list", 0, Target.URI }
    };

    public static File dnd_get_file (SelectionData selection_data, uint target_type) {
        File file;
        string file_to_parse = "";
        // Check that we got the format we can use
        switch (target_type)
        {
            case Target.URI:
                file_to_parse = (string) selection_data.get_data();
            break;
            case Target.STRING:
                file_to_parse = (string) selection_data.get_data();
            break;
            default:
                print ("Invalid data type\n");
            break;
        }

        file_to_parse = file_to_parse.chomp ();
        if (file_to_parse != "")
        {
            if (file_to_parse.has_prefix ("file"))
            {
                file = File.new_for_uri (file_to_parse.chomp ());
                string? check_path = file.get_path ();
                if ((check_path == null) || (check_path.chomp () == ""))
                {
                    file_to_parse = "/dev/null/thiefmd";
                }
                else
                {
                    file_to_parse = check_path.chomp ();
                }
            }
        }

        file = File.new_for_path (file_to_parse);
        return file;
    }

    public class PreventDelayedDrop {
        private bool droppable;
        private Mutex droptex;
        public PreventDelayedDrop () {
            droppable = true;
            droptex = Mutex ();
        }

        public bool can_get_drop () {
            bool res = droppable;
            debug ("%s get drop", res ? "CAN" : "CANNOT");

            if (droppable) {
                debug ("Acquiring lock");
                droptex.lock ();
                debug ("Lock acquired");
                droppable = false;
                Timeout.add (300, clear_drop);
                droptex.unlock ();
            }
            return res;
        }

        private bool clear_drop () {
            droptex.lock ();
            droppable = true;
            droptex.unlock ();
            return false;
        }
    }
}