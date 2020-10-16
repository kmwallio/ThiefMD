/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified September 6, 2020
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
    errordomain ThiefError {
        FILE_NOT_FOUND,
        FILE_NOT_VALID_ARCHIVE,
        FILE_NOT_VALID_THEME
    }

    public string make_title (string text) {
        string current_title = text.replace ("_", " ");
        current_title = current_title.replace ("-", " ");
        string [] parts = current_title.split (" ");
        if (parts != null && parts.length != 0) {
            current_title = "";
            foreach (var part in parts) {
                part = part.substring (0, 1).up () + part.substring (1).down ();
                current_title += part + " ";
            }
            current_title = current_title.chomp ();
        }

        return current_title;
    }

    public string get_base_library_path (string path) {
        var settings = AppSettings.get_default ();
        if (path == null) {
            return "No file opened";
        }
        string res = path;
        foreach (var base_lib in settings.library ()) {
            if (res.has_prefix (base_lib)) {
                File f = File.new_for_path (base_lib);
                string base_chop = f.get_parent ().get_path ();
                res = res.substring (base_chop.length);
                if (res.has_prefix (Path.DIR_SEPARATOR_S)) {
                    res = res.substring (1);
                }
            }
        }

        return res;
    }

    public string csv_to_md (string csv) {
        StringBuilder b = new StringBuilder ();
        string[] lines = csv.split ("\n");
        int[] items = new int[lines.length];
        for (int l = 0; l < lines.length; l++) {
            string line = lines[l];
            string[] values = line.split (",");
            int j = 0;
            for (int i = 0; i < values.length; i++) {
                if (i == 0) {
                    b.append ("|");
                }
                string value = values[i];
                if (l == 0) {
                    items[j] = -1;
                }
                value = value.chomp ().chug ();
                if (value.has_prefix ("\"") && value.has_suffix ("\"")) {
                    value = value.substring (1, value.length - 2);
                    if (l == 0) {
                        items[j] = value.length;
                    }
                } else if (value.has_prefix ("\"")) {
                    string t;
                    do  {
                        t = values[i++];
                        if (l == 0) {
                            items[i] = -1;
                        }
                        value += t;
                    } while (!value.has_suffix ("\"") && i < values.length);
                    value = value.substring (1, value.length - 2);
                }
                b.append (value);
                if (l > 0) {
                    if (value.length < items[j]) {
                        for (int r = value.length; r < items[j]; r++) {
                            b.append (" ");
                        }
                    }
                }
                b.append ("|");
                j++;
            }
            b.append ("\n");
            if (l == 0) {
                b.append ("|");
                for (int k = 0; k < items.length && items[k] > 0; k++) {
                    for (int t = 0; t < items[k]; t++) {
                        b.append ("-");
                    }
                    b.append ("|");
                }
                b.append ("\n");
            }
        }

        return b.str;
    }

    public class TimedMutex {
        private bool can_action;
        private Mutex droptex;
        private int delay;

        public TimedMutex (int milliseconds_delay = 300) {
            if (milliseconds_delay < 100) {
                milliseconds_delay = 100;
            }

            delay = milliseconds_delay;
            can_action = true;
            droptex = Mutex ();
        }

        public bool can_do_action () {
            bool res = can_action;
            debug ("%s do action", res ? "CAN" : "CANNOT");

            if (can_action) {
                debug ("Acquiring lock");
                droptex.lock ();
                debug ("Lock acquired");
                can_action = false;
                Timeout.add (delay, clear_action);
                droptex.unlock ();
            }
            return res;
        }

        private bool clear_action () {
            droptex.lock ();
            can_action = true;
            droptex.unlock ();
            return false;
        }
    }
}