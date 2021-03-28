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

using ThiefMD.Controllers;
using ThiefMD.Connections;
using ThiefMD.Widgets;

namespace ThiefMD {
    errordomain ThiefError {
        FILE_NOT_FOUND,
        FILE_NOT_VALID_ARCHIVE,
        FILE_NOT_VALID_THEME
    }

    public bool generate_html (string raw_mk, out string processed_mk) {
        if (Pandoc.needs_bibtex (raw_mk)) {
            return Pandoc.make_preview (out processed_mk, raw_mk);
        } else {
            return Pandoc.generate_discount_html (raw_mk, out processed_mk);
        }
    }

    private string find_bibtex_for_sheet (string path = "") {
        string result = "";
        string search_path = Path.get_dirname (path);
        if (search_path == "") {
            Sheet? search_sheet = SheetManager.get_sheet ();
            if (search_sheet != null) {
                search_path = Path.get_dirname (search_sheet.file_path ());
            }
        }
        if (search_path != "") {
            
            int idx = 0;
            while (search_path != "") {
                try {
                    Dir dir = Dir.open (search_path, 0);
                    string? file_name = null;
                    while ((file_name = dir.read_name()) != null) {
                        if (!file_name.has_prefix(".")) {
                            string file_path = Path.build_filename (search_path, file_name);
                            if (file_path.has_suffix (".bib")) {
                                result = file_path;
                                break;
                            }
                        }
                    }
                } catch (Error e) {
                    warning ("Could not scan directory: %s", e.message);
                    break;
                }
                idx = search_path.last_index_of_char (Path.DIR_SEPARATOR);
                if (idx != -1) {
                    search_path = search_path[0:idx];
                } else {
                    break;
                }
            }
        }

        return result;
    }

    public void get_chunk_of_text_around_cursor (ref Gtk.TextIter start, ref Gtk.TextIter end, bool force_lines = false) {
        start.backward_line ();

        //
        // Try to make sure we don't wind up in the middle of
        // CHARACTER
        // [Iter]Dialogue
        //
        int line_checks = 0;
        if (!force_lines) {
            while (start.get_char () != '\n' && start.get_char () != '\r' && line_checks <= 5) {
                if (!start.backward_line ()) {
                    break;
                }
                line_checks += 1;
            }

            end.forward_line ();
            line_checks = 0;
            while (end.get_char () != '\n' && end.get_char () != '\r' && line_checks <= 5) {
                if (!end.forward_line ()) {
                    break;
                }
                line_checks += 1;
            }
        } else {
            while (line_checks <= 5) {
                if (!start.backward_line ()) {
                    break;
                }
                line_checks += 1;
            }

            end.forward_line ();
            line_checks = 0;
            while (line_checks <= 5) {
                if (!end.forward_line ()) {
                    break;
                }
                line_checks += 1;
            }
        }
    }

    public bool exportable_file (string filename) {
        string check = filename.down ();
        return check.has_suffix (".md") || check.has_suffix (".markdown") ||
                check.has_suffix (".fountain") || check.has_suffix (".fou") || check.has_suffix (".spmd");
    }

    public bool can_open_file (string filename) {
        string check = filename.down ();
        return check.has_suffix (".md") || check.has_suffix (".markdown") ||
                check.has_suffix (".fountain") || check.has_suffix (".fou") || check.has_suffix (".spmd") ||
                check.has_suffix (".bib") || check.has_suffix (".bibtex");
    }

    public bool is_fountain (string filename) {
        string check = filename.down ();
        return check.has_suffix (".fountain") || check.has_suffix (".fou") || check.has_suffix (".spmd");
    }

    public bool match_keycode (uint keyval, uint code) {
        Gdk.KeymapKey [] keys;
        Gdk.Keymap keymap = Gdk.Keymap.get_for_display (Gdk.Display.get_default ());
        if (keymap.get_entries_for_keyval (keyval, out keys)) {
            foreach (var key in keys) {
                if (code == key.keycode) {
                    return true;
                }
            }
        }

        return false;
    }

    public string get_some_words (string buffer) {
        string found = "";
        try {
            Regex check_words = new Regex ("(\\s*)([^\\.\\?!:\"\\s]+)([\\.\\?!:\"\\s]*)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex is_word = new Regex ("\\w+", RegexCompileFlags.CASELESS, 0);
            Regex file_name_chars_only = new Regex ("[^A-Za-z0-9]", RegexCompileFlags.CASELESS, 0);
            MatchInfo match_info;
            if (check_words.match_full (buffer, buffer.length, 0, 0, out match_info)) {
                if (match_info == null) {
                    return found;
                }

                int got_words = 0;
                do {
                    if (match_info.get_match_count () >= 2) {
                        string word = match_info.fetch (2);
                        word = (word != null) ? file_name_chars_only.replace (word, word.length, 0, "") : word;

                        if (word != null && word != "" && word.length < 10 && is_word.match (word, RegexMatchFlags.NOTEMPTY)) {
                            found += "-" + word.down ();
                            got_words++;
                            if (got_words >= 4) {
                                break;
                            }
                        }
                    }
                } while (match_info.next ());
            }
        } catch (Error e) {
            warning ("Could not extract text: %s", e.message);
        }

        if (found.length > 150) {
            found = "";
        }

        return found;
    }

    public Gtk.ImageMenuItem set_icon_option (string name, string icon, Sheets project) {
        Gtk.ImageMenuItem set_icon = new Gtk.ImageMenuItem.with_label (name);
        set_icon.set_image (new Gtk.Image.from_pixbuf (get_pixbuf_for_value (icon)));
        set_icon.always_show_image = true;
        set_icon.activate.connect (() => {
            project.metadata.icon = icon;
        });

        return set_icon;
    }

    public Gdk.Pixbuf? get_pixbuf_for_value (string value) {
        Gdk.Pixbuf? ret_val = null;
        try {
            if (value != "") {
                File icon_file = File.new_for_path (value);
                if (icon_file.query_exists ()) {
                    ret_val = new Gdk.Pixbuf.from_file (value);
                } else {
                    if (value.has_prefix ("/")) {
                        ret_val = new Gdk.Pixbuf.from_resource (value);
                    } else {
                        ret_val =  Gtk.IconTheme.get_default ().load_icon (value, Gtk.IconSize.MENU, 0);
                    }
                }
            }

            if (ret_val == null) {
                return new Gdk.Pixbuf.from_resource ("/com/github/kmwallio/thiefmd/icons/empty.svg");
            } else if (ret_val.get_height () != 16) {
                double percent = (16) / ((double) ret_val.get_height ());
                int new_w = (int)(percent * ret_val.get_width ());
                return ret_val.scale_simple (new_w, 16, Gdk.InterpType.NEAREST);
            }
        } catch (Error e) {
            warning ("Could not set default icon: %s", e.message);
            try {
                return Gtk.IconTheme.get_default ().load_icon ("folder", Gtk.IconSize.MENU, 0);
            } catch (Error e) {
                warning ("Could not set backup folder icon: %s", e.message);
            }
        }

        return ret_val;
    }

    public Gdk.Pixbuf? get_pixbuf_for_folder (string folder) {
        Gdk.Pixbuf? ret_val = null;
        File metadata_file = File.new_for_path (Path.build_filename (folder, ".thiefsheets"));
        ThiefSheets metadata = new ThiefSheets ();
        if (metadata_file.query_exists ()) {
            try {
                metadata = ThiefSheets.new_for_file (metadata_file.get_path ());
            } catch (Error e) {
                warning ("Could not load metafile: %s", e.message);
            }
        }
        ret_val = get_pixbuf_for_value (metadata.icon);
        return ret_val;
    }

    public string string_or_empty_string (string? str) {
        return (str != null) ? str : "";
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

    public string get_possible_markdown_url (string url) {
        if (url.index_of_char (':') > 0 && url.index_of_char (':') <= 7) {
            string protocol = url.substring (0, url.index_of_char (':'));
            if (protocol.down () != "file") {
                return "";
            }
        }
        string attempt = Pandoc.find_file (url, "");
        if (attempt != url) {
            return attempt;
        } else {
            if (url.last_index_of_char ('.') != -1) {
                string markdownify_file = url.substring (0, url.last_index_of_char ('.'));
                attempt = try_possible_url_exts (markdownify_file);
                if (attempt != "") {
                    return attempt;
                }
            } else if (url.has_suffix ("/")) {
                attempt = try_possible_url_exts (url.substring (0, url.length - 1));
                if (attempt != "") {
                    return attempt;
                }
            } else {
                attempt = try_possible_url_exts (url);
                if (attempt != "") {
                    return attempt;
                }
            }
        }

        return "";
    }

    private string try_possible_url_exts (string url, bool skip_recurse = false) {
        string test_url = url;
        if (test_url.has_prefix ("file://")) {
            test_url = test_url.substring (7);
        }
        string[] exts = {".md", ".markdown", ".fountain", ".fou", ".spmd", "/index.md", "/index.markdown", "/index.fountain"};
        foreach (var ext in exts) {
            string attempt = Pandoc.find_file (test_url + ext, "");
            if (attempt != test_url + ext) {
                return attempt;
            }
        }

        string next_attempt = test_url;
        if (test_url.has_suffix ("/")) {
            next_attempt = test_url.substring (0, test_url.length - 1);
            debug (next_attempt);
            string attempt = try_possible_url_exts (next_attempt);
            if (attempt != "") {
                return attempt;
            }
        }

        if (test_url.index_of_char ('#') != -1) {
            next_attempt = test_url.substring (0, test_url.index_of_char ('#'));
            debug (next_attempt);
            string attempt = try_possible_url_exts (next_attempt);
            if (attempt != "") {
                return attempt;
            }
        }

        if (next_attempt.index_of_char ('/') != -1 && !skip_recurse) {
            string[] parts = next_attempt.split ("/");
            for (int i = 0; i < parts.length; i++) {
                next_attempt = "";
                for (int j = 0; j < parts.length; j++) {
                    if (parts[j] == "") {
                        continue;
                    } else if (j == i) {
                        next_attempt += "_" + parts[j];
                    } else {
                        next_attempt += parts[j];
                    }
                    next_attempt += "/";
                }
                debug (next_attempt);
                string attempt = try_possible_url_exts (next_attempt, true);
                if (attempt != "") {
                    return attempt;
                }
            }
        }
        return "";
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
            bool res = false;

            if (droptex.trylock ()) {
                if (can_action) {
                    res = true;
                    can_action = false;
                    Timeout.add (delay, clear_action);
                }
                droptex.unlock ();
            }

            debug ("%s do action", res ? "CAN" : "CANNOT");
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