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

    public void import_file (string file_path, Sheets parent) {
        File import_f = File.new_for_path (file_path);
        string ext = file_path.substring (file_path.last_index_of (".") + 1).down ();
        debug ("Importing (%s): %s", ext, import_f.get_path ());

        // Supported import file extensions
        if (ext == "docx" ||
            ext == "odt" ||
            ext == "html" ||
            ext == "tex" ||
            ext == "epub" ||
            ext == "textile" ||
            ext == "html" ||
            ext == "fb2" ||
            ext == "dbk" ||
            ext == "xml" ||
            ext == "opml" ||
            ext == "rst")
        {
            Thinking worker = new Thinking (_("Importing File"), () => {
                string dest_name = import_f.get_basename ();
                dest_name = dest_name.substring (0, dest_name.last_index_of ("."));
                dest_name += ".md";
                debug ("Attempt to create: %s", dest_name);
                string dest_path = Path.build_filename (parent.get_sheets_path (), dest_name);
                if (Pandoc.make_md_from_file (dest_path, import_f.get_path ())) {
                    if (ext == "docx" || ext == "odt" || ext == "epub" || ext == "fb2") {
                        string new_markdown = get_file_contents (dest_path);
                        Gee.LinkedList<string> files_to_find = Pandoc.file_import_paths (new_markdown);
                        string formatted_markdown = strip_external_formatters (new_markdown);
                        extract_files_to_dest (import_f.get_path (), files_to_find, parent.get_sheets_path ());
                        if (formatted_markdown != "") {
                            File write_twice = File.new_for_path (dest_path);
                            try {
                                save_file (write_twice, formatted_markdown.data);
                            } catch (Error e) {
                                warning ("Could not strip external formatting: %s", e.message);
                            }
                        }
                    }
                }
            });
            worker.run ();
        }

        parent.refresh ();
        ThiefApp.get_instance ().library.refresh_dir (parent);
    }

    private string strip_external_formatters (string markdown) {
        string resdown = markdown;
        try {
            Regex non_supported_tags = new Regex ("(\\[\\]\\{[=\\#sw\\.[^\\}]*\\n?\\r?[^\\}]*?\\})", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex non_supported_tags2 = new Regex ("(\\{[=\\#sw\\.[^\\}]*\\n?\\r?[^\\}]*?\\})", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex random_colons = new Regex ("^([:\\\\])+\\s*$", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex empty_lines = new Regex ("\\n\\s*\\n\\s*\\n", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex end_break = new Regex ("\\\\$", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex sentence_break = new Regex ("([a-zA-Z,;:\\\"])\\n([a-zA-Z,;:\\\"\\()])", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);

            resdown = non_supported_tags.replace (resdown, resdown.length, 0, "");
            resdown = non_supported_tags2.replace (resdown, resdown.length, 0, "");
            resdown = random_colons.replace (resdown, resdown.length, 0, "");
            resdown = empty_lines.replace (resdown, resdown.length, 0, "\n\n");
            resdown = end_break.replace (resdown, resdown.length, 0, "  ");
            resdown = sentence_break.replace (resdown, resdown.length, 0, "\\1 \\2");
            resdown = resdown.replace ("\n\n\n", "\n\n"); // Switch 3 empty lines to 2
            resdown = resdown.replace ("\n\n\n", "\n\n"); // Switch 3 empty lines to 2
            resdown = resdown.replace ("\\\'", "'");
            resdown = resdown.replace ("\\\"", "\"");
        } catch (Error e) {
            warning ("Could not strip special formatters: %s", e.message);
        }
        return resdown;
    }

    private bool list_contains (
        string needle,
        Gee.List<string> haystack,
        out string place_file_at,
        bool case_insensitive = true,
        bool match_as_suffix = true)
    {
        foreach (string hay in haystack) {
            if (hay == needle) {
                place_file_at = hay;
                return true;
            } else if (case_insensitive && hay.down() == needle.down ()) {
                place_file_at = hay;
                return true;
            } else if (match_as_suffix && needle.has_suffix (hay)) {
                place_file_at = hay;
                return true;
            } else if (match_as_suffix && case_insensitive && needle.down ().has_suffix (hay.down ())) {
                place_file_at = hay;
                return true;
            }
        }

        return false;
    }

    public void extract_files_to_dest (string archive_path, Gee.LinkedList<string> files, string destination_path) {
        File arch_file = File.new_for_path (archive_path);
        File dest = File.new_for_path (destination_path);
        if (!arch_file.query_exists ()) {
            return;
        }

        try {
            debug ("Looking for: %s", string.joinv (", ", files.to_array ()));
            var archive = new Archive.Read ();
            throw_on_failure (archive.support_filter_all ());
            throw_on_failure (archive.support_format_all ());
            throw_on_failure (archive.open_filename (arch_file.get_path (), 10240));

            unowned Archive.Entry entry;
            while (archive.next_header (out entry) == Archive.Result.OK) {
                // Extract theme into memory
                debug ("Found: %s", entry.pathname ());
                string extraction_path = "";
                if (list_contains(entry.pathname (), files, out extraction_path)) {
                    uint8[] buffer = null;
                    Array<uint8> bin_buffer = new Array<uint8> ();
                    Posix.off_t offset;
                    while (archive.read_data_block (out buffer, out offset) == Archive.Result.OK) {
                        if (buffer == null) {
                            break;
                        }

                        bin_buffer.append_vals (buffer, buffer.length);
                    }

                    if (bin_buffer.length != 0) {
                        File dest_file = File.new_for_path (Path.build_filename (dest.get_path (), extraction_path));
                        File dest_parent = dest_file.get_parent ();
                        debug ("Extracting: %s to %s", entry.pathname (), dest_file.get_path ());
                        if (dest_parent != null) {
                            if (!dest_parent.query_exists ()) {
                                dest_parent.make_directory_with_parents ();
                            }
                            save_file (dest_file, bin_buffer.data);
                        }
                    }
                } else {
                    archive.read_data_skip ();
                }
            }
        } catch (Error e) {
            warning ("Error loading archive: %s", e.message);
        }
    }

    public void load_css_pkg (File css_pkg) {
        if (!css_pkg.query_exists ()) {
            return;
        }

        try {
            var archive = new Archive.Read ();
            throw_on_failure (archive.support_filter_all ());
            throw_on_failure (archive.support_format_all ());
            throw_on_failure (archive.open_filename (css_pkg.get_path (), 10240));
            string theme_name = css_pkg.get_basename ();
            theme_name = theme_name.substring (0, theme_name.last_index_of ("."));
            if (theme_name == null || theme_name.chug ().chomp () == "") {
                return;
            }
            File theme_dest = File.new_for_path (Path.build_filename (UserData.css_path, theme_name));

            // Browse files in archive.
            unowned Archive.Entry entry;
            while (archive.next_header (out entry) == Archive.Result.OK) {
                // Extract theme into memory
                if (entry.pathname ().has_suffix (".css")){
                    uint8[] buffer = null;
                    Posix.off_t offset;
                    string css_buffer = "";
                    while (archive.read_data_block (out buffer, out offset) == Archive.Result.OK) {
                        if (buffer == null) {
                            break;
                        }
                        if (buffer[buffer.length - 1] != 0) {
                            buffer += 0;
                        }
                        css_buffer += (string)buffer;
                    }

                    if (!theme_dest.query_exists ()) {
                        theme_dest.make_directory_with_parents ();
                    }

                    string dest = "preview.css";
                    if (entry.pathname ().down ().has_suffix("print.css") || entry.pathname ().down ().has_suffix("pdf.css")) {
                        dest = "print.css";
                    }
                    File dest_file = File.new_for_path (Path.build_filename (theme_dest.get_path (), dest));
                    save_file (dest_file, css_buffer.data);
                } else {
                    archive.read_data_skip ();
                }
            }
        } catch (Error e) {
            warning ("Error loading archive: %s", e.message);
        }
    }

    private void throw_on_failure (Archive.Result res) throws Error {
        if ((res == Archive.Result.OK) ||
            (res == Archive.Result.WARN)) {
            return;
        }

        throw new ThiefError.FILE_NOT_FOUND ("Could not read archive");
    }

    public void save_file (File save_file, uint8[] buffer) throws Error {
        if (save_file.query_exists ()) {
            save_file.delete ();
        }

        var output = new DataOutputStream (save_file.create(FileCreateFlags.REPLACE_DESTINATION));
        long written = 0;
        while (written < buffer.length)
            written += output.write (buffer[written:buffer.length]);
    }

    public string save_temp_file (string text) {
        string res_file = "";
        string cache_path = Path.build_filename (Environment.get_user_cache_dir (), "com.github.kmwallio.thiefmd");
        var cache_folder = File.new_for_path (cache_path);
        if (!cache_folder.query_exists ()) {
            try {
                cache_folder.make_directory_with_parents ();
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }
        }

        Rand probably_a_better_solution_than_this = new Rand ();
        string random_name = "%d.md".printf (probably_a_better_solution_than_this.int_range (100000, 999999));
        File tmp_file = cache_folder.get_child (random_name);

        try {
            save_file (tmp_file, text.data);
            res_file = tmp_file.get_path ();
        } catch (Error e) {
            warning ("Failed temp file generation: %s", e.message);
        }

        return res_file;
    }

    public void open_file (string file_path, out Widgets.Editor editor) {
        bool file_opened = false;
        var lock = new FileLock ();
        var settings = AppSettings.get_default ();

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

    public int get_word_count (string file_path) {
        var settings = AppSettings.get_default ();
        string title, date;
        string markdown = get_yamlless_markdown (get_file_contents (file_path), 0, out title, out date, true, settings.export_include_yaml_title, false);

        // This is for an approximate word count, not trying to be secure or anything...
        try {
            Regex style = new Regex ("<style\\b[^<]*(?:(?!<\\/style>)<[^<]*)*<\\/style>", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex script = new Regex ("<script\\b[^<]*(?:(?!<\\/script>)<[^<]*)*<\\/script>", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex random_tags = new Regex ("<\\/?(div|p|script|img|td|tr|table|small|u|b|strong|em|sup|sub|span)[^>]*>", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex words = new Regex ("\\s+\\n*", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex num_bullets = new Regex ("^\\s*[0-9]+\\.\\s+");

            markdown = num_bullets.replace (markdown, markdown.length, 0, " ");
            markdown = style.replace (markdown, markdown.length, 0, " ");
            markdown = script.replace (markdown, markdown.length, 0, " ");
            markdown = random_tags.replace (markdown, markdown.length, 0, " ");
            // Markdown special characters?
            markdown = markdown.replace ("*", "")
                                .replace ("#", "")
                                .replace (">", "")
                                .replace ("|", "")
                                .replace ("-", "")
                                .replace ("_", "")
                                .replace ("`", "")
                                .replace ("=", "")
                                .replace ("+", "");

            markdown = words.replace (markdown, markdown.length, 0, " ");
            markdown = markdown.chomp ().chug ();

            return words.split (markdown, RegexMatchFlags.NOTEMPTY | RegexMatchFlags.NOTEMPTY_ATSTART | RegexMatchFlags.NEWLINE_ANY).length;
        } catch (Error e) {
            warning ("Could not get accurate count: %s", e.message);
        }

        return 0;
    }

    public bool get_parsed_markdown (string raw_mk, out string processed_mk) {
        var settings = AppSettings.get_default ();
        var mkd = new Markdown.Document.from_gfm_string (raw_mk.data, 0x00200000 + 0x00004000 + 0x02000000 + 0x01000000 + 0x04000000 + 0x00400000 + 0x10000000 + 0x40000000);
        mkd.compile (0x00200000 + 0x00004000 + 0x02000000 + 0x01000000 + 0x00400000 + 0x04000000 + 0x40000000 + 0x10000000);
        mkd.get_document (out processed_mk);

        return (processed_mk.chomp () != "");
    }

    public Gee.Map<string, string> get_yaml_kvp (string markdown) {
        Gee.Map<string, string> kvps = new Gee.HashMap<string, string> ();
        string buffer = markdown;

        Regex headers = null;
        try {
            headers = new Regex ("^\\s*(.+)\\s*:\\s+(.*)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
        } catch (Error e) {
            warning ("Could not compile regex: %s", e.message);
        }

        if (buffer.has_prefix ("---" + ThiefProperties.THIEF_MARK_CONST)) {
            buffer = buffer.replace (ThiefProperties.THIEF_MARK_CONST, "");
        }

        if (buffer.length > 4 && buffer[0:4] == "---\n") {
            int i = 0;
            int last_newline = 3;
            int next_newline;
            bool valid_frontmatter = true;
            string line = "";

            while (valid_frontmatter) {
                next_newline = buffer.index_of_char('\n', last_newline + 1);
                if (next_newline == -1 && !((buffer.length > last_newline + 1) && buffer.substring (last_newline + 1).has_prefix("---"))) {
                    valid_frontmatter = false;
                    break;
                }

                if (next_newline == -1) {
                    line = buffer.substring (last_newline + 1);
                } else {
                    line = buffer[last_newline+1:next_newline];
                }
                line = line.replace (ThiefProperties.THIEF_MARK_CONST, "");
                last_newline = next_newline;

                if (line == "---") {
                    break;
                }

                if (headers != null) {
                    MatchInfo matches;
                    if (headers.match (line, RegexMatchFlags.NOTEMPTY_ATSTART, out matches)) {
                        string key = matches.fetch (1).chug ().chomp ();
                        string value = matches.fetch (2).chug ().chomp ();
                        if (value.has_prefix ("\"") && value.has_suffix ("\"")) {
                            value = value.substring (1, value.length - 2);
                        }

                        if (!kvps.has_key (key)) {
                            kvps.set (key, value);
                        } else {
                            if (key == matches.fetch (1)) {
                                kvps.set (key, value);
                            }
                        }
                    } else {
                        // If it's a list or empty line, we're cool
                        line = line.down ().chomp ();
                        if (!line.has_prefix ("-") && line != "") {
                            valid_frontmatter = false;
                            break;
                        }
                    }
                } else {
                    string quick_parse = line.chomp ();
                    int split = quick_parse.index_of (":");
                    if (split != -1) {
                        string match = quick_parse.substring (0, split);
                        string key = quick_parse.substring (0, split).chug ().chomp ();
                        string value = quick_parse.substring (quick_parse.index_of (":") + 1);
                        if (value.has_prefix ("\"") && value.has_suffix ("\"")) {
                            value = value.substring (1, value.length - 2);
                        }
                        if (!kvps.has_key (key)) {
                            kvps.set (key, value);
                        } else {
                            if (key == match) {
                                kvps.set (key, value);
                            }
                        }
                    }
                }

                i++;
            }

            if (!valid_frontmatter) {
                kvps = new Gee.HashMap<string, string> ();
            }
        }

        return kvps;
    }

    public string get_yamlless_markdown (
        string markdown,
        int lines,
        out string title,
        out string date,
        bool non_empty = true,
        bool include_title = true,
        bool include_date = true)
    {
        string buffer = markdown;
        Regex headers = null;
        try {
            headers = new Regex ("^\\s*(.+)\\s*:\\s+(.*)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
        } catch (Error e) {
            warning ("Could not compile regex: %s", e.message);
        }

        string temp_title = "";
        string temp_date = "";

        MatchInfo matches;
        var markout = new StringBuilder ();
        int mklines = 0;

        if (buffer.has_prefix ("---" + ThiefProperties.THIEF_MARK_CONST)) {
            buffer = buffer.replace (ThiefProperties.THIEF_MARK_CONST, "");
        }

        if (buffer.length > 4 && buffer[0:4] == "---\n") {
            int i = 0;
            int last_newline = 3;
            int next_newline;
            bool valid_frontmatter = true;
            string line = "";

            while (valid_frontmatter) {
                next_newline = buffer.index_of_char('\n', last_newline + 1);
                if (next_newline == -1 && !((buffer.length > last_newline + 1) && buffer.substring (last_newline + 1).has_prefix("---"))) {
                    valid_frontmatter = false;
                    break;
                }

                if (next_newline == -1) {
                    line = buffer.substring (last_newline + 1);
                } else {
                    line = buffer[last_newline+1:next_newline];
                }
                line = line.replace (ThiefProperties.THIEF_MARK_CONST, "");
                last_newline = next_newline;

                if (line == "---") {
                    break;
                }

                if (headers != null) {
                    if (headers.match (line, RegexMatchFlags.NOTEMPTY_ATSTART, out matches)) {
                        if (matches.fetch (1).ascii_down() == "title") {
                            temp_title = matches.fetch (2).chug ().chomp ();
                            if (temp_title.has_prefix ("\"") && temp_title.has_suffix ("\"")) {
                                temp_title = temp_title.substring (1, temp_title.length - 2);
                            }
                            if (include_title) {
                                markout.append ("# " + temp_title + "\n");
                                mklines++;
                            }
                        } else if (matches.fetch (1).ascii_down() == "date") {
                            temp_date = matches.fetch (2).chug ().chomp ();
                            if (include_date) {
                                markout.append ("## " + temp_date + "\n");
                                mklines++;
                            }
                        }
                    } else {
                        // If it's a list or empty line, we're cool
                        line = line.down ().chomp ();
                        if (!line.has_prefix ("-") && line != "") {
                            valid_frontmatter = false;
                            break;
                        }
                    }
                } else {
                    string quick_parse = line.chomp ();
                    if (quick_parse.has_prefix ("title")) {
                        temp_title = quick_parse.substring (quick_parse.index_of (":") + 1);
                        if (temp_title.has_prefix ("\"") && temp_title.has_suffix ("\"")) {
                            temp_title = temp_title.substring (1, temp_title.length - 2);
                        }
                        if (include_title) {
                            markout.append ("# " + temp_title);
                            mklines++;
                        }
                    } else if (quick_parse.has_prefix ("date")) {
                        temp_date = quick_parse.substring (quick_parse.index_of (":") + 1).chug ().chomp ();
                        if (include_date) {
                            markout.append ("## " + temp_date);
                            mklines++;
                        }
                    }
                }

                i++;
            }

            if (!valid_frontmatter) {
                markout.erase ();
                markout.append (markdown);
            } else {
                markout.append (buffer[last_newline:buffer.length]);
            }
        } else {
            markout.append (markdown);
        }

        title = temp_title;
        date = temp_date;

        return markout.str;
    }

    public string get_file_lines_yaml (
        string file_path,
        int lines,
        bool non_empty,
        out string title,
        out string date)
    {
        // var lock = new FileLock ();
        var markdown = new StringBuilder ();
        string temp_title = "";
        string temp_date = "";

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

                while (((line = input.read_line (null)) != null) && (lines_read < lines || lines <= 0)) {
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
                            if (temp_title == "" && line.has_prefix ("#") && line.index_of (" ") != -1) {
                                temp_title = line.substring (line.index_of (" ")).chug ().chomp ();
                            }
                            markdown.append (((lines_read == 0) ? "" :"\n") + line.chomp());
                            lines_read++;
                        } else {
                            if (headers.match (line, RegexMatchFlags.NOTEMPTY, out matches)) {
                                if (matches.fetch (1).ascii_down().chug ().chomp () == "title") {
                                    temp_title = matches.fetch (2).replace ("\"", "").chomp ().chug ();
                                    markdown.append (((lines_read == 0) ? "" :"\n") + "# " + temp_title);
                                    lines_read++;
                                } else if (matches.fetch (1).ascii_down().chug ().chomp ().has_prefix ("date")) {
                                    temp_date = matches.fetch (2).replace ("\"", "").chomp ().chug ();
                                    markdown.append (((lines_read == 0) ? "" :"\n") + temp_date);
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

        title = temp_title;
        date = temp_date;

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

        SheetManager.save_active ();
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
