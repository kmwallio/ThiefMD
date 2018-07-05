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

namespace ThiefMD.Controllers.FileManager {
    public static bool disable_save = false;

    public File tmp_file;
    public File file;
    public Widgets.Editor view;

    public void save_file (File save_file, uint8[] buffer) throws Error {
        var output = new DataOutputStream (save_file.create(FileCreateFlags.REPLACE_DESTINATION));
        long written = 0;
        while (written < buffer.length)
            written += output.write (buffer[written:buffer.length]);
    }

    private void save_work_file () {
        var lock = new FileLock ();
        var settings = AppSettings.get_default ();
        var file = File.new_for_path (settings.last_file);

        if (file.query_exists ()) {
            try {
                file.delete ();
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }

            Gtk.TextIter start, end;
            Widgets.Editor.buffer.get_bounds (out start, out end);

            string buffer = Widgets.Editor.buffer.get_text (start, end, true);
            uint8[] binbuffer = buffer.data;

            try {
                save_file (file, binbuffer);
            } catch (Error e) {
                warning ("Exception found: "+ e.message);
            }
        }
    }

    public File setup_tmp_file () {
        debug ("Setupping cache...");
        string cache_path = Path.build_filename (Environment.get_user_cache_dir (), "com.github.kmwallio.thiefmd");
        var cache_folder = File.new_for_path (cache_path);
        if (!cache_folder.query_exists ()) {
            try {
                cache_folder.make_directory_with_parents ();
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }
        }

        tmp_file = cache_folder.get_child ("temp");
        return tmp_file;
    }

    private void save_tmp_file () {
        setup_tmp_file ();

        debug ("Saving cache...");
        if ( tmp_file.query_exists () ) {
            try {
                tmp_file.delete();
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }

        }

        Gtk.TextIter start, end;
        Widgets.Editor.buffer.get_bounds (out start, out end);

        string buffer = Widgets.Editor.buffer.get_text (start, end, true);
        uint8[] binbuffer = buffer.data;

        try {
            save_file (tmp_file, binbuffer);
        } catch (Error e) {
            warning ("Exception found: "+ e.message);
        }
    }

    // File I/O
    public void new_file () {
        var lock = new FileLock ();
        debug ("New button pressed.");
        debug ("Buffer was modified. Asking user to save first.");
        var settings = AppSettings.get_default ();
        var dialog = new Controllers.Dialogs.Dialog.display_save_confirm (ThiefApp.get_instance ().main_window);
        dialog.response.connect ((response_id) => {
            switch (response_id) {
                case Gtk.ResponseType.YES:
                    debug ("User saves the file.");

                    try {
                        Controllers.FileManager.save ();
                        string cache = Path.build_filename (Environment.get_user_cache_dir (), "com.github.kmwallio.thiefmd" + "/temp");
                        file = File.new_for_path (cache);
                        Widgets.Editor.buffer.text = "";
                        settings.last_file = file.get_path ();
                        
                    } catch (Error e) {
                        warning ("Unexpected error during save: " + e.message);
                    }
                    break;
                case Gtk.ResponseType.NO:
                    debug ("User doesn't care about the file, shoot it to space.");

                    string cache = Path.build_filename (Environment.get_user_cache_dir (), "com.github.kmwallio.thiefmd" + "/temp");
                    file = File.new_for_path (cache);
                    Widgets.Editor.buffer.text = "";
                    settings.last_file = file.get_path ();
                    
                    break;
                case Gtk.ResponseType.CANCEL:
                    debug ("User cancelled, don't do anything.");
                    break;
                case Gtk.ResponseType.DELETE_EVENT:
                    debug ("User cancelled, don't do anything.");
                    break;
            }
            dialog.destroy();
        });

        if (view.is_modified) {
            dialog.show ();
            view.is_modified = false;
        } else {
            try {
                Controllers.FileManager.save ();
            } catch (Error e) {
                warning ("Unexpected error during save: " + e.message);
            }
            string cache = Path.build_filename (Environment.get_user_cache_dir (), "com.github.lainsce.quilter" + "/temp");
            file = File.new_for_path (cache);
            Widgets.Editor.buffer.text = "";
            settings.last_file = file.get_path ();
            
        }
    }

    public bool open_from_outside (File[] files, string hint) {
        var lock = new FileLock ();
        if (files.length > 0) {
            var file = files[0];
            string text;
            var settings = AppSettings.get_default ();
            settings.last_file = file.get_path ();
            

            try {
                GLib.FileUtils.get_contents (file.get_path (), out text);
                Widgets.Editor.buffer.text = text;
            } catch (Error e) {
                warning ("Error: %s", e.message);
            }
        }
        return true;
    }

    public bool open_file (string file_path) {
        bool file_opened = false;
        var lock = new FileLock ();
        var settings = AppSettings.get_default ();

        try {
            string text;
            var file = File.new_for_path (file_path);

            if (file.query_exists ()) {
                string filename = file.get_path ();
                debug ("Reading %s\n", filename);
                GLib.FileUtils.get_contents (filename, out text);
                Widgets.Editor.buffer.text = text;
                settings.last_file = filename;
                file_opened = true;
            } else {
                warning ("File does not exist\n");
            }
        } catch (Error e) {
            warning ("Error: %s", e.message);
        }

        return file_opened;
    }

    public string get_file_contents (string file_path) {
        var lock = new FileLock ();
        string file_contents = "";

        try {
            var file = File.new_for_path (file_path);

            if (file.query_exists ()) {
                string filename = file.get_path ();
                debug ("Reading %s\n", filename);
                GLib.FileUtils.get_contents (filename, out file_contents);
            } else {
                warning ("File does not exist\n");
            }
        } catch (Error e) {
            warning ("Error: %s", e.message);
        }

        return file_contents;
    }

    public string get_file_lines_yaml (string file_path, int lines, bool non_empty = true) {
        var lock = new FileLock ();
        string file_contents = "";

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
                            file_contents += ((lines_read == 0) ? "" :"\n") + line.chomp();
                            lines_read++;
                        } else {
                            if (headers.match (line, RegexMatchFlags.NOTEMPTY, out matches)) {
                                if (matches.fetch (1).ascii_down() == "title") {
                                    file_contents += ((lines_read == 0) ? "" :"\n") + "# " + matches.fetch (2).replace ("\"", "");
                                    lines_read++;
                                } else if (matches.fetch (1).ascii_down() == "date") {
                                    file_contents += ((lines_read == 0) ? "" :"\n") + matches.fetch (2);
                                    lines_read++;
                                }
                            }
                        }
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

    public void open () throws Error {
        var lock = new FileLock ();
        debug ("Open button pressed.");
        var settings = AppSettings.get_default ();
        var file = Controllers.Dialogs.display_open_dialog ();

        try {
            debug ("Opening file...");
            if (file == null) {
                debug ("User cancelled operation. Aborting.");
            } else {
                string text;
                GLib.FileUtils.get_contents (file.get_path (), out text);
                Widgets.Editor.buffer.text = text;
                settings.last_file = file.get_path ();
            }
        } catch (Error e) {
            warning ("Unexpected error during open: " + e.message);
        }

        view.is_modified = false;
        file = null;
    }

    public void save () throws Error {
        debug ("Save button pressed.");
        var settings = AppSettings.get_default ();
        var file = File.new_for_path (settings.last_file);
        

        if (file.query_exists ()) {
            try {
                file.delete ();
            } catch (Error e) {
                warning ("Error: " + e.message);
            }
        }

        Gtk.TextIter start, end;
        Widgets.Editor.buffer.get_bounds (out start, out end);
        string buffer = Widgets.Editor.buffer.get_text (start, end, true);
        uint8[] binbuffer = buffer.data;

        try {
            save_file (file, binbuffer);
        } catch (Error e) {
            warning ("Unexpected error during save: " + e.message);
        }

        file = null;
        view.is_modified = false;
    }

    public void save_as () throws Error {
        var lock = new FileLock ();
        debug ("Save as button pressed.");
        var settings = AppSettings.get_default ();
        var file = Controllers.Dialogs.display_save_dialog ();
        settings.last_file = file.get_path ();

        try {
            debug ("Saving file...");
            if (file == null) {
                debug ("User cancelled operation. Aborting.");
            } else {
                if (file.query_exists ()) {
                    file.delete ();
                }

                Gtk.TextIter start, end;
                Widgets.Editor.buffer.get_bounds (out start, out end);
                string buffer = Widgets.Editor.buffer.get_text (start, end, true);
                uint8[] binbuffer = buffer.data;
                save_file (file, binbuffer);
            }
        } catch (Error e) {
            warning ("Unexpected error during save: " + e.message);
        }

        file = null;
        view.is_modified = false;
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
                    open_file (new_file.get_path ());
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
            debug ("*** Broke out ***\n");
        }

        debug ("*** Lock acq\n");

        disable_save = true;
    }

    public static void release_lock () {
        disable_save = false;

        debug ("*** Lock rel\n");
    }
}
