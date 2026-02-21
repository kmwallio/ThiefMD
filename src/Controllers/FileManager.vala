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
    // AE_IFREG from libarchive: regular file mode for archive entries
    private const uint ARCHIVE_IFREG = 0100000;
    // Shared info.json content for TextBundle-compliant archives
    private const string TEXTBUNDLE_INFO_JSON = """{"version":2,"type":"net.daringfireball.markdown","transient":false,"creatorURL":"https://thiefmd.com","creatorIdentifier":"com.github.kmwallio.thiefmd"}""";
    // info.json for fountain screenplay textpacks
    private const string TEXTBUNDLE_FOUNTAIN_INFO_JSON = """{"version":2,"type":"com.secondgearsoftware.fountain","transient":false,"creatorURL":"https://thiefmd.com","creatorIdentifier":"com.github.kmwallio.thiefmd"}""";

    public void import_file (string file_path, Sheets parent) {
        File import_f = File.new_for_path (file_path);
        string ext = file_path.substring (file_path.last_index_of (".") + 1).down ();
        string match_ext = ext;
        warning ("Importing (%s): %s", ext, import_f.get_path ());

        // TextPack has its own import logic
        if (ext == "textpack") {
            import_textpack (file_path, parent);
            return;
        }

        if (match_ext.length >= 3) {
            match_ext = "*." + match_ext + ";";
        }

        // Supported import file extensions
        if (ThiefProperties.SUPPORTED_IMPORT_FILES.index_of (match_ext) >= 0) {
            Gee.List<string> importSayings = new Gee.LinkedList<string> ();
            importSayings.add(_("Stealing file contents..."));
            importSayings.add(_("This isn't plagiarism, it's a remix!"));
            importSayings.add(_("NYT Best Seller, here we come!"));

            Thinking worker = new Thinking (_("Importing File"), () => {
                string dest_name = import_f.get_basename ();
                dest_name = dest_name.substring (0, dest_name.last_index_of ("."));
                if (is_fountain (import_f.get_basename ())) {
                    dest_name += ".fountain";
                } else {
                    dest_name += ".md";
                }
                debug ("Attempt to create: %s", dest_name);
                string dest_path = Path.build_filename (parent.get_sheets_path (), dest_name);
                if (can_open_file (import_f.get_basename ())) {
                    File copy_to = File.new_for_path (dest_path);
                    try {
                        import_f.copy (copy_to, FileCopyFlags.NONE);
                    } catch (Error e) {
                        warning ("Could not add file to library: %s", e.message);
                    }
                } else if (Pandoc.make_md_from_file (dest_path, import_f.get_path ())) {
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
            },
            importSayings,
            ThiefApp.get_instance ());
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
        place_file_at = "";
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

    public string save_temp_file (string text, string ext = "md") {
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
        string random_name = "%d.%s".printf (probably_a_better_solution_than_this.int_range (100000, 999999), ext);
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
            editor = null;
            debug ("File does not exist\n");
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

    public int get_word_count_from_string (string text) {
        int word_count = 0;
        bool in_yaml = false;
        bool in_code_block = false;
        bool in_html_tag = false;
        StringBuilder current_word = new StringBuilder ();
        
        string[] lines = text.split ("\n");
        
        foreach (string line in lines) {
            // Skip YAML frontmatter
            if (line == "---" || line == "+++") {
                if (in_yaml) {
                    in_yaml = false;
                    continue;
                } else if (word_count == 0) {
                    in_yaml = true;
                    continue;
                }
            }
            
            if (in_yaml) {
                continue;
            }
            
            // Skip code blocks
            if (line.has_prefix ("```") || line.has_prefix ("~~~")) {
                in_code_block = !in_code_block;
                continue;
            }
            
            if (in_code_block) {
                continue;
            }
            
            // Process line character by character for word counting (respect UTF-8 boundaries)
            int index = 0;
            unichar c = 0;
            while (line.get_next_char (ref index, out c)) {
                
                // Skip HTML tags (simple detection)
                if (c == '<') {
                    in_html_tag = true;
                    continue;
                } else if (c == '>') {
                    in_html_tag = false;
                    continue;
                }
                
                if (in_html_tag) {
                    continue;
                }
                
                // Skip markdown formatting characters
                if (c == '*' || c == '#' || c == '_' || c == '`' || c == '>' || 
                    c == '|' || c == '=' || c == '+' || c == '[' || c == ']' ||
                    c == '(' || c == ')') {
                    continue;
                }
                
                // Word boundary detection
                if (c.isspace () || c.ispunct ()) {
                    if (current_word.len > 0) {
                        word_count++;
                        current_word.erase ();
                    }
                } else if (c.isalnum ()) {
                    current_word.append_unichar (c);
                }
            }
            
            // Handle word at end of line
            if (current_word.len > 0) {
                word_count++;
                current_word.erase ();
            }
        }
        
        return word_count;
    }

    public int get_word_count (string file_path) {
        DataInputStream? input = null;
        try {
            var file = File.new_for_path (file_path);
            if (!file.query_exists ()) {
                return 0;
            }

            input = new DataInputStream (file.read ());
            int word_count = 0;
            string? line;
            bool in_yaml = false;
            bool in_code_block = false;
            bool in_html_tag = false;
            StringBuilder current_word = new StringBuilder ();
            
            while ((line = input.read_line (null)) != null) {
                // Skip YAML frontmatter
                if (line == "---" || line == "+++") {
                    if (in_yaml) {
                        in_yaml = false;
                        continue;
                    } else if (word_count == 0) {
                        in_yaml = true;
                        continue;
                    }
                }
                
                if (in_yaml) {
                    continue;
                }
                
                // Skip code blocks
                if (line.has_prefix ("```") || line.has_prefix ("~~~")) {
                    in_code_block = !in_code_block;
                    continue;
                }
                
                if (in_code_block) {
                    continue;
                }
                
                // Process line character by character for word counting (respect UTF-8 boundaries)
                int index = 0;
                unichar c = 0;
                while (line.get_next_char (ref index, out c)) {
                    
                    // Skip HTML tags (simple detection)
                    if (c == '<') {
                        in_html_tag = true;
                        continue;
                    } else if (c == '>') {
                        in_html_tag = false;
                        continue;
                    }
                    
                    if (in_html_tag) {
                        continue;
                    }
                    
                    // Skip markdown formatting characters
                    if (c == '*' || c == '#' || c == '_' || c == '`' || c == '>' || 
                        c == '|' || c == '=' || c == '+' || c == '[' || c == ']' ||
                        c == '(' || c == ')') {
                        continue;
                    }
                    
                    // Word boundary detection
                    if (c.isspace () || c.ispunct ()) {
                        if (current_word.len > 0) {
                            word_count++;
                            current_word.erase ();
                        }
                    } else if (c.isalnum ()) {
                        current_word.append_unichar (c);
                    }
                }
                
                // Handle word at end of line
                if (current_word.len > 0) {
                    word_count++;
                    current_word.erase ();
                }
            }
            
            return word_count;
        } catch (Error e) {
            warning ("Could not get word count for %s: %s", file_path, e.message);
        } finally {
            if (input != null) {
                try {
                    input.close ();
                } catch (Error e) {
                    warning ("Could not close word count stream: %s", e.message);
                }
            }
        }

        return 0;
    }

    public bool get_parsed_markdown (string raw_mk, out string processed_mk) {
        return Pandoc.generate_discount_html (raw_mk, out processed_mk);
    }

    public Gee.Map<string, string> get_yaml_kvp (string markdown) {
        Gee.Map<string, string> kvps = new Gee.HashMap<string, string> ();
        string buffer = markdown;

        Regex headers = null;
        try {
            headers = new Regex ("^\\s*(.+?)\\s*[=:]\\s+(.*)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
        } catch (Error e) {
            warning ("Could not compile regex: %s", e.message);
        }
        
        if (buffer.has_prefix ("---" + ThiefProperties.THIEF_MARK_CONST) || buffer.has_prefix ("+++" + ThiefProperties.THIEF_MARK_CONST)) {
            buffer = buffer.replace (ThiefProperties.THIEF_MARK_CONST, "");
        }

        string buffer_prefix = (buffer.length > 4) ? buffer[0:4] : "";
        if (buffer.length > 4 && (buffer_prefix == "---\n" || buffer_prefix == "+++\n")) {
            int i = 0;
            int last_newline = 3;
            int next_newline;
            bool valid_frontmatter = true;
            string line = "";

            while (valid_frontmatter) {
                next_newline = buffer.index_of_char('\n', last_newline + 1);
                if (next_newline == -1 && !((buffer.length > last_newline + 1) && (buffer.substring (last_newline + 1).has_prefix("---") || buffer.substring (last_newline + 1).has_prefix("+++")))) {
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

                if (line == "---" || line == "+++") {
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
                    int split = quick_parse.index_of (":") != -1 ? quick_parse.index_of (":") : quick_parse.index_of ("=");
                    if (split != -1) {
                        string match = quick_parse.substring (0, split);
                        string key = quick_parse.substring (0, split).chug ().chomp ();
                        string value = quick_parse.substring (split + 1).chug ().chomp ();
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
            headers = new Regex ("^\\s*(.+?)\\s*[=:]\\s+(.*)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
        } catch (Error e) {
            warning ("Could not compile regex: %s", e.message);
        }

        string temp_title = "";
        string temp_date = "";

        MatchInfo matches;
        var markout = new StringBuilder ();
        int mklines = 0;

        if (buffer.has_prefix ("---" + ThiefProperties.THIEF_MARK_CONST) || buffer.has_prefix ("+++" + ThiefProperties.THIEF_MARK_CONST)) {
            buffer = buffer.replace (ThiefProperties.THIEF_MARK_CONST, "");
        }

        string buffer_prefix = (buffer.length > 4) ? buffer[0:4] : "";
        if (buffer.length > 4 && ((buffer_prefix == "---\n") || (buffer_prefix == "+++\n"))) {
            int i = 0;
            int last_newline = 3;
            int next_newline;
            bool valid_frontmatter = true;
            string line = "";

            while (valid_frontmatter) {
                next_newline = buffer.index_of_char('\n', last_newline + 1);
                if (next_newline == -1 && !((buffer.length > last_newline + 1) && (buffer.substring (last_newline + 1).has_prefix("---") || buffer.substring (last_newline + 1).has_prefix("+++")))) {
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

                if (line == "---" || line == "+++") {
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

    // Static regex to avoid recompilation on every call
    private static Regex? yaml_headers_regex = null;
    
    public string get_file_lines_yaml (
        string file_path,
        int lines,
        bool non_empty_lines_only,
        out string title,
        out string date)
    {
        // var lock = new FileLock ();
        var markdown = new StringBuilder ();
        string temp_title = "";
        string temp_date = "";
        DataInputStream? input = null;

        try {
            // Compile regex once
            if (yaml_headers_regex == null) {
                yaml_headers_regex = new Regex ("^\\s*(.+?)\\s*[=:]\\s+(.+)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            }

            var file = File.new_for_path (file_path);
            if (!file.query_exists ()) {
                warning ("File does not exist: %s", file_path);
                title = temp_title;
                date = temp_date;
                return "";
            }

            debug ("Reading %s", file.get_path ());
            input = new DataInputStream (file.read ());
            int lines_read = 0;
            string? line;
            bool in_yaml = false;
            bool first_line = true;

            while ((line = input.read_line (null)) != null) {
                // Early termination if we have enough lines
                if (lines > 0 && lines_read >= lines) {
                    break;
                }

                string trimmed = line.chomp ();
                
                // Skip empty lines if requested
                if (non_empty_lines_only && trimmed == "") {
                    continue;
                }

                // Handle YAML frontmatter delimiters
                if (trimmed == "---" || trimmed == "+++") {
                    if (in_yaml) {
                        in_yaml = false;
                        continue;
                    } else if (lines_read == 0) {
                        in_yaml = true;
                        continue;
                    }
                }

                if (!in_yaml) {
                    // Regular markdown content
                    if (temp_title == "" && line.has_prefix ("#")) {
                        int space_idx = line.index_of (" ");
                        if (space_idx != -1) {
                            temp_title = line.substring (space_idx).chug ().chomp ();
                        }
                    }
                    
                    if (!first_line) {
                        markdown.append_c ('\n');
                    }
                    markdown.append (trimmed);
                    lines_read++;
                    first_line = false;
                } else {
                    // Parse YAML frontmatter
                    MatchInfo matches;
                    if (yaml_headers_regex.match (trimmed, RegexMatchFlags.NOTEMPTY, out matches)) {
                        string key = matches.fetch (1).chug ().chomp ().ascii_down ();
                        string value = matches.fetch (2).chug ().chomp ();
                        
                        // Remove quotes
                        if (value.has_prefix ("\"") && value.has_suffix ("\"") && value.length >= 2) {
                            value = value.substring (1, value.length - 2);
                        }
                        
                        if (key == "title") {
                            temp_title = value;
                            if (!first_line) {
                                markdown.append_c ('\n');
                            }
                            markdown.append ("# ").append (temp_title);
                            lines_read++;
                            first_line = false;
                        } else if (key.has_prefix ("date")) {
                            temp_date = value;
                            if (!first_line) {
                                markdown.append_c ('\n');
                            }
                            markdown.append (temp_date);
                            lines_read++;
                            first_line = false;
                        }
                    }
                }
            }

            if (lines_read == 1) {
                markdown.append_c ('\n');
            }

        } catch (Error e) {
            warning ("Error reading %s: %s", file_path, e.message);
        } finally {
            if (input != null) {
                try {
                    input.close ();
                } catch (Error e) {
                    warning ("Could not close file lines stream: %s", e.message);
                }
            }
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
        DataInputStream? input = null;

        if (lines <= 0) {
            return get_file_contents(file_path);
        }

        try {
            var file = File.new_for_path (file_path);

            if (file.query_exists ()) {
                string filename = file.get_path ();
                debug ("Reading %s\n", filename);

                input = new DataInputStream (file.read ());
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
        } finally {
            if (input != null) {
                try {
                    input.close ();
                } catch (Error e) {
                    warning ("Could not close file lines internal stream: %s", e.message);
                }
            }
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

    // Import a TextPack (.textpack) archive into a library folder.
    // TextBundle spec: https://textbundle.org/spec/
    public void import_textpack (string textpack_path, Sheets parent) {
        File textpack_file = File.new_for_path (textpack_path);
        if (!textpack_file.query_exists ()) {
            return;
        }

        Gee.List<string> importSayings = new Gee.LinkedList<string> ();
        importSayings.add (_("Unpacking your stories..."));
        importSayings.add (_("Liberating your words!"));
        importSayings.add (_("TextPack, meet ThiefMD!"));

        Thinking worker = new Thinking (_("Importing TextPack"), () => {
            // Use the textpack file name (without extension) as the output file name
            string bundle_name = textpack_file.get_basename ();
            bundle_name = bundle_name.substring (0, bundle_name.last_index_of ("."));

            try {
                var archive = new Archive.Read ();
                throw_on_failure (archive.support_filter_all ());
                throw_on_failure (archive.support_format_all ());
                throw_on_failure (archive.open_filename (textpack_file.get_path (), 10240));

                string imported_text_path = "";

                unowned Archive.Entry entry;
                while (archive.next_header (out entry) == Archive.Result.OK) {
                    string entry_path = entry.pathname ();

                    // Strip a leading bundle folder prefix (e.g. "mybundle/text.md" -> "text.md"),
                    // but keep the "assets/" prefix intact since that's part of the spec
                    if (entry_path.contains ("/")) {
                        string first_comp = entry_path.substring (0, entry_path.index_of ("/"));
                        string rest = entry_path.substring (entry_path.index_of ("/") + 1);
                        if (first_comp != "assets" && rest != "") {
                            entry_path = rest;
                        }
                    }

                    // Check for the main text file
                    bool is_text = (entry_path == "text.md" ||
                        entry_path == "text.markdown" ||
                        entry_path == "text.fountain" ||
                        entry_path == "text.fou");

                    // Assets go in the same folder as the markdown file
                    bool is_asset = entry_path.has_prefix ("assets/") &&
                        !entry_path.has_suffix ("/");

                    if (is_text || is_asset) {
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
                            string dest_path;
                            if (is_text) {
                                string ext = entry_path.substring (entry_path.last_index_of ("."));
                                dest_path = Path.build_filename (parent.get_sheets_path (), bundle_name + ext);
                                imported_text_path = dest_path;
                            } else {
                                // Assets go right next to the markdown file, no subfolder
                                string asset_name = Path.get_basename (entry_path);
                                dest_path = Path.build_filename (parent.get_sheets_path (), asset_name);
                            }

                            File dest_file = File.new_for_path (dest_path);
                            try {
                                save_file (dest_file, bin_buffer.data);
                            } catch (Error e) {
                                warning ("Could not save extracted file: %s", e.message);
                            }
                        }
                    } else {
                        archive.read_data_skip ();
                    }
                }

                // Rewrite "assets/" image paths to flat paths since assets live next to the .md.
                // TextBundle-compliant tools only use "assets/" as a path prefix (not in prose),
                // so a direct replace is safe here.
                if (imported_text_path != "") {
                    string markdown = get_file_contents (imported_text_path);
                    string fixed = markdown.replace ("assets/", "");
                    if (fixed != markdown) {
                        File md_file = File.new_for_path (imported_text_path);
                        try {
                            save_file (md_file, fixed.data);
                        } catch (Error e) {
                            warning ("Could not update image paths: %s", e.message);
                        }
                    }
                }
            } catch (Error e) {
                warning ("Could not import textpack: %s", e.message);
            }
        }, importSayings, ThiefApp.get_instance ());

        worker.run ();
        parent.refresh ();
        ThiefApp.get_instance ().library.refresh_dir (parent);
    }

    // Export a folder's markdown files as a TextPack (.textpack) archive.
    // TextBundle spec: https://textbundle.org/spec/
    public bool export_textpack (string folder_path, string textpack_path) {
        try {
            // Gather all markdown files from the folder, in order
            var md_files = new Gee.LinkedList<string> ();
            collect_exportable_files (folder_path, md_files);

            // Combine all markdown into a single string
            var combined = new StringBuilder ();
            foreach (string file_path in md_files) {
                string content = get_file_contents (file_path);
                combined.append (content);
                combined.append ("\n\n");
            }
            string markdown_content = combined.str;

            // Find all local image files referenced by the markdown
            Gee.Map<string, string> images = Pandoc.file_image_map (markdown_content, folder_path);

            // Rewrite image references to use assets/ prefix inside the bundle
            string textbundle_markdown = markdown_content;
            foreach (var img_entry in images.entries) {
                string asset_name = "assets/" + Path.get_basename (img_entry.value);
                textbundle_markdown = textbundle_markdown.replace (img_entry.key, asset_name);
            }

            // Create the ZIP archive
            var writer = new Archive.Write ();
            if (writer.set_format_zip () != Archive.Result.OK) {
                warning ("Could not set zip format for textpack");
                return false;
            }
            if (writer.open_filename (textpack_path) != Archive.Result.OK) {
                warning ("Could not open textpack for writing: %s", textpack_path);
                return false;
            }

            // Add info.json
            textpack_add_string (writer, "info.json", TEXTBUNDLE_INFO_JSON);

            // Add text.md with the combined content
            textpack_add_string (writer, "text.md", textbundle_markdown);

            // Add asset files to the assets/ folder
            foreach (var img_entry in images.entries) {
                string abs_path = img_entry.value;
                string asset_name = "assets/" + Path.get_basename (abs_path);
                textpack_add_file (writer, asset_name, abs_path);
            }

            writer.close ();
            return true;
        } catch (Error e) {
            warning ("Could not create textpack: %s", e.message);
            return false;
        }
    }

    // Export a pre-built markdown string as a TextPack (.textpack) archive.
    // Finds locally referenced images relative to base_path, bundles them in assets/,
    // and rewrites image paths in the markdown to point to assets/<filename>.
    // Set is_fountain to true when the content is a Fountain screenplay.
    public bool export_textpack_from_markdown (string markdown_content, string textpack_path, string base_path = "", bool is_fountain = false) {
        try {
            // Find all local image/asset references in the markdown
            Gee.Map<string, string> images = Pandoc.file_image_map (markdown_content, base_path);

            // Rewrite image references to use assets/ prefix inside the bundle
            string bundle_markdown = markdown_content;
            foreach (var img_entry in images.entries) {
                string asset_name = "assets/" + Path.get_basename (img_entry.value);
                bundle_markdown = bundle_markdown.replace (img_entry.key, asset_name);
            }

            var writer = new Archive.Write ();
            if (writer.set_format_zip () != Archive.Result.OK) {
                warning ("Could not set zip format for textpack");
                return false;
            }
            if (writer.open_filename (textpack_path) != Archive.Result.OK) {
                warning ("Could not open textpack for writing: %s", textpack_path);
                return false;
            }

            // Fountain scripts use a different info.json type and file name
            if (is_fountain) {
                textpack_add_string (writer, "info.json", TEXTBUNDLE_FOUNTAIN_INFO_JSON);
                textpack_add_string (writer, "text.fountain", bundle_markdown);
            } else {
                textpack_add_string (writer, "info.json", TEXTBUNDLE_INFO_JSON);
                textpack_add_string (writer, "text.md", bundle_markdown);
            }

            // Add each referenced image into the assets/ folder
            foreach (var img_entry in images.entries) {
                string asset_name = "assets/" + Path.get_basename (img_entry.value);
                textpack_add_file (writer, asset_name, img_entry.value);
            }

            writer.close ();
            return true;
        } catch (Error e) {
            warning ("Could not create textpack from markdown: %s", e.message);
            return false;
        }
    }

    // Recursively collect exportable markdown/fountain files from a folder, in order.
    private void collect_exportable_files (string folder_path, Gee.LinkedList<string> files) {
        try {
            Dir dir = Dir.open (folder_path, 0);
            string? name = null;
            var file_list = new Gee.LinkedList<string> ();
            var dir_list = new Gee.LinkedList<string> ();

            while ((name = dir.read_name ()) != null) {
                if (name.has_prefix (".")) {
                    continue;
                }
                string full_path = Path.build_filename (folder_path, name);
                if (FileUtils.test (full_path, FileTest.IS_DIR)) {
                    dir_list.add (full_path);
                } else if (exportable_file (name)) {
                    file_list.add (full_path);
                }
            }

            file_list.sort ((a, b) => a.collate (b));
            foreach (string f in file_list) {
                files.add (f);
            }

            dir_list.sort ((a, b) => a.collate (b));
            foreach (string d in dir_list) {
                collect_exportable_files (d, files);
            }
        } catch (Error e) {
            warning ("Could not scan folder for export: %s", e.message);
        }
    }

    // Write a string as a file entry inside a ZIP archive.
    private void textpack_add_string (Archive.Write writer, string name, string data) {
        var entry = new Archive.Entry ();
        entry.set_pathname (name);
        entry.set_size (data.length);
        entry.set_filetype (ARCHIVE_IFREG);
        entry.set_perm (0644);
        writer.write_header (entry);
        // Slice to data.length to skip the trailing null byte that Vala adds to string.data
        writer.write_data (data.data[0:data.length]);
    }

    // Write a file from disk as an entry inside a ZIP archive.
    private void textpack_add_file (Archive.Write writer, string archive_name, string file_path) {
        try {
            File f = File.new_for_path (file_path);
            if (!f.query_exists ()) {
                return;
            }
            uint8[] data;
            f.load_contents (null, out data, null);

            var entry = new Archive.Entry ();
            entry.set_pathname (archive_name);
            entry.set_size (data.length);
            entry.set_filetype (ARCHIVE_IFREG);
            entry.set_perm (0644);
            writer.write_header (entry);
            writer.write_data (data);
        } catch (Error e) {
            warning ("Could not add asset to textpack: %s", e.message);
        }
    }

    public class FileLock : Object {
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
            warning ("*** Broke out ***");
        }

        debug ("*** Lock acq");

        disable_save = true;
    }

    public static void release_lock () {
        disable_save = false;

        debug ("*** Lock rel");
    }
}
