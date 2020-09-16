/*
 * Copyright (C) 2017 Lains
 * 
 * Modified July 5, 2018
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

namespace ThiefMD.Controllers.FileManager {
    public static bool disable_save = false;

    public void save_file (File save_file, uint8[] buffer) throws Error {
        if (save_file.query_exists ()) {
            save_file.delete ();
        }

        var output = new DataOutputStream (save_file.create(FileCreateFlags.REPLACE_DESTINATION));
        long written = 0;
        while (written < buffer.length)
            written += output.write (buffer[written:buffer.length]);
    }

    public void open_file (string file_path, out Widgets.Editor editor) {
        bool file_opened = false;
        var lock = new FileLock ();
        var settings = AppSettings.get_default ();

        try {
            string text;
            var file = File.new_for_path (file_path);

            if (file.query_exists ()) {
                string filename = file.get_path ();
                debug ("Reading %s\n", filename);
                editor = new Widgets.Editor (filename);
                settings.last_file = filename;
                file_opened = true;
            } else {
                warning ("File does not exist\n");
            }
        } catch (Error e) {
            warning ("Error: %s", e.message);
        }
    }

    public bool copy_item (string source_file, string destination_folder) throws Error
    {
        File to_move = File.new_for_path (source_file);
        File final_destination = File.new_for_path (Path.build_filename (destination_folder, to_move.get_basename ()));
        return to_move.copy (final_destination, FileCopyFlags.NONE);
    }

    public bool move_item (string source_file, string destination_folder) throws Error
    {
        bool moved = false;
        bool is_active = false;
        var settings = AppSettings.get_default ();

        if (SheetManager.close_active_file (source_file))
        {
            is_active = true;
        }

        File to_move = File.new_for_path (source_file);
        File final_destination = File.new_for_path (Path.build_filename (destination_folder, to_move.get_basename ()));
        moved = to_move.move (final_destination, FileCopyFlags.NONE);

        return moved;
    }

    public bool move_to_trash (string file_path)
    {
        bool moved = false;
        File to_delete = File.new_for_path (file_path);
        if (!to_delete.query_exists ()) {
            return true;
        }

        try {
            moved = to_delete.trash ();
        } catch (Error e) {
            warning ("Error: %s", e.message);
        }

        return moved;
    }

    public static string get_file_contents (string file_path) {
        // var lock = new FileLock ();
        string file_contents = "";

        try {
            var file = File.new_for_path (file_path);

            if (file.query_exists ()) {
                string filename = file.get_path ();
                debug ("Reading %s\n", filename);
                GLib.FileUtils.get_contents (filename, out file_contents);
            }
        } catch (Error e) {
            warning ("Error: %s", e.message);
        }

        return file_contents;
    }

    public string get_yamlless_markdown (string buffer, int lines, bool non_empty = true, bool include_title = true, bool include_date = true)
    {
        Regex headers = null;
        try {
            headers = new Regex ("^\\s*(.+)\\s*:\\s+(.+)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
        } catch (Error e) {
            warning ("Could not compile regex: %s", e.message);
        }

        MatchInfo matches;
        var markdown = new StringBuilder ();
        int mklines = 0;

        if (buffer.length > 4 && buffer[0:4] == "---\n") {
            int i = 0;
            int last_newline = 3;
            int next_newline;
            bool valid_frontmatter = true;
            string line = "";

            while (valid_frontmatter) {
                next_newline = buffer.index_of_char('\n', last_newline + 1);
                if (next_newline == -1) {
                    valid_frontmatter = false;
                    break;
                }
                line = buffer[last_newline+1:next_newline];
                last_newline = next_newline;

                if (line == "---") {
                    break;
                }

                if (headers != null) {
                    if (headers.match (line, RegexMatchFlags.NOTEMPTY, out matches)) {
                        if (include_title && matches.fetch (1).ascii_down() == "title") {
                            markdown.append ("# " + matches.fetch (2).replace ("\"", "") + "\n");
                            mklines++;
                        } else if (include_date && matches.fetch (1).ascii_down() == "date") {
                            markdown.append ("## " + matches.fetch (2) + "\n");
                            mklines++;
                        }
                    } else {
                        // If it's a list or empty line, we're cool
                        line = line.down ();
                        if (!line.chomp ().has_prefix ("-") && line.chomp () != "" && line.chomp ().has_prefix ("categories")) {
                            valid_frontmatter = false;
                            break;
                        }
                    }
                } else {
                    string quick_parse = line.chomp ();
                    if (quick_parse.has_prefix ("title")) {
                        markdown.append ("# " + quick_parse.substring (quick_parse.index_of (":") + 1));
                    } else if (quick_parse.has_prefix ("date")) {
                        markdown.append ("## " + quick_parse.substring (quick_parse.index_of (":") + 1));
                    }
                }

                i++;
            }

            if (!valid_frontmatter) {
                markdown.erase ();
                markdown.append (buffer);
            } else {
                markdown.append (buffer[last_newline:buffer.length]);
            }
        } else {
            markdown.append (buffer);
        }

        return markdown.str;
    }

    public string get_file_lines_yaml (string file_path, int lines, bool non_empty = true) {
        // var lock = new FileLock ();
        var markdown = new StringBuilder ();

        if (lines <= 0) {
            return get_file_contents(file_path);
        }

        try {
            var file = File.new_for_path (file_path);
            Regex headers = new Regex ("^\\s*(.+)\\s*:\\s+(.+)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            MatchInfo matches;

            if (file.query_exists ()) {
                string filename = file.get_path ();
                debug ("Reading %s\n", filename);

                var input = new DataInputStream (file.read ());
                int lines_read = 0;
                string line;
                bool in_yaml = false;

                while (((line = input.read_line (null)) != null) && (lines_read < lines)) {
                    if ((!non_empty) || (line.chomp() != "")) {
                        if (line == "---") {
                            if (in_yaml) {
                                in_yaml = false;
                                continue;
                            } else if (lines_read == 0) {
                                in_yaml = true;
                            }
                        }
                        if (!in_yaml) {
                            markdown.append (((lines_read == 0) ? "" :"\n") + line.chomp());
                            lines_read++;
                        } else {
                            if (headers.match (line, RegexMatchFlags.NOTEMPTY, out matches)) {
                                if (matches.fetch (1).ascii_down() == "title") {
                                    markdown.append (((lines_read == 0) ? "" :"\n") + "# " + matches.fetch (2).replace ("\"", ""));
                                    lines_read++;
                                } else if (matches.fetch (1).ascii_down() == "date") {
                                    markdown.append (((lines_read == 0) ? "" :"\n") + matches.fetch (2));
                                    lines_read++;
                                }
                            }
                        }
                    }
                }

                if (lines_read == 1) {
                    markdown.append ("\n");
                }

            } else {
                warning ("File does not exist\n");
            }
        } catch (Error e) {
            warning ("Error: %s", e.message);
        }

        return markdown.str;
    }

    public bool add_ignore_folder (string directory_path)
    {
        File ignore_dir = File.new_for_path (directory_path);
        File parent_dir = ignore_dir.get_parent ();
        bool file_created = false;
        string? buffer;
        if (parent_dir.query_exists ()) {
            var ignore_file = parent_dir.get_child (".thiefignore");
            if (!ignore_file.query_exists ()) {
                // Create new .thiefignore file
                buffer = ignore_dir.get_basename ();
                if (buffer == null) {
                    return false;
                }
            } else {
                buffer = get_file_lines (ignore_file.get_path (), 100, true) + "\n" + ignore_dir.get_basename ();
                try {
                    ignore_file.delete ();
                } catch (Error e) {
                    warning ("Error: %s\n", e.message);
                }
            }
            try {
                uint8[] binbuffer = buffer.data;
                save_file (ignore_file, binbuffer);
                file_created = true;
            } catch (Error e) {
                warning ("Exception found: "+ e.message);
            }
        }

        return file_created;
    }

    public string get_file_lines (string file_path, int lines, bool non_empty = true) {
        var lock = new FileLock ();
        string file_contents = "";

        if (lines <= 0) {
            return get_file_contents(file_path);
        }

        try {
            var file = File.new_for_path (file_path);

            if (file.query_exists ()) {
                string filename = file.get_path ();
                debug ("Reading %s\n", filename);

                var input = new DataInputStream (file.read ());
                int lines_read = 0;
                string line;

                while (((line = input.read_line (null)) != null) && (lines_read < lines)) {
                    if ((!non_empty) || (line.chomp() != "")) {
                        file_contents += ((lines_read == 0) ? "" :"\n") + line.chomp();
                        lines_read++;
                    }
                }

                if (lines_read == 1) {
                    file_contents += "\n";
                }

            } else {
                warning ("File does not exist\n");
            }
        } catch (Error e) {
            warning ("Error: %s", e.message);
        }

        return file_contents;
    }

    public void save () throws Error {
        debug ("Save button pressed.");

        try {
            SheetManager.save_active ();
        } catch (Error e) {
            warning ("Unexpected error during save: " + e.message);
        }
    }

    public static bool create_sheet (string parent_folder, string file_name) {
        var lock = new FileLock ();
        File parent_dir = File.new_for_path (parent_folder);
        bool file_created = false;

        if (parent_dir.query_exists ()) {
            var new_file = parent_dir.get_child (file_name);
            // Make sure the file doesn't exist.
            if (!new_file.query_exists ()) {
                string buffer = "";
                uint8[] binbuffer = buffer.data;

                try {
                    save_file (new_file, binbuffer);
                    file_created = true;
                } catch (Error e) {
                    warning ("Exception found: "+ e.message);
                }
            }
        }

        return file_created;
    }

    public class FileLock {
        public FileLock () {
            FileManager.acquire_lock ();
        }

        ~FileLock () {
            FileManager.release_lock ();
        }
    }

    public static void acquire_lock () {
        //
        // Bad locking, but wait if we're doing file switching already
        //
        // Misbehave after ~4 seconds of waiting...
        //
        int tries = 0;
        while (disable_save && tries < 15) {
            Thread.usleep(250);
            tries++;
        }

        if (tries == 15) {
            warning ("*** Broke out ***\n");
        }

        debug ("*** Lock acq\n");

        disable_save = true;
    }

    public static void release_lock () {
        disable_save = false;

        debug ("*** Lock rel\n");
    }
}
