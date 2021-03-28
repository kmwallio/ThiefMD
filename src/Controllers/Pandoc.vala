/*
 * Copyright (C) 2020 kmwallio
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the “Software”), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall
 * be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

using ThiefMD;
using ThiefMD.Widgets;

namespace ThiefMD.Controllers.Pandoc {
    public class PandocThinking : GLib.Object {
        private int wait_time;
        private Cancellable cancellable;
        private bool done;
        public PandocThinking (int timeout_millseconds = 3000) {
            wait_time = timeout_millseconds;
        }

        public bool run_pandoc_std_in_out_command (ref string[] command, ref string input, out string output) {
            bool res = false;
            done = false;
            StringBuilder output_builder = new StringBuilder ();
            try {
                cancellable = new Cancellable ();
                Subprocess pandoc = new Subprocess.newv (command, SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDIN_PIPE);
                var input_stream = pandoc.get_stdin_pipe ();
                if (input_stream != null) {
                    DataOutputStream flush_buffer = new DataOutputStream (input_stream);
                    if (!flush_buffer.put_string (input)) {
                        warning ("Could not set buffer");
                    }
                    flush_buffer.flush ();
                    flush_buffer.close ();
                }
                var output_stream = pandoc.get_stdout_pipe ();
                bool pandoc_done = false;

                // Before we wait, setup watchdogs
                Thread<void> watchdog = null;
                if (Thread.supported ()) {
                    watchdog = new Thread<void> ("pandoc_watchdog", this.watch_dog);
                } else {
                    int now = 0;
                    Timeout.add (5, () => {
                        now += 5;
                        if (now > wait_time && !done) {
                            cancellable.cancel ();
                        }
                        return done;
                    });
                }

                res = pandoc.wait_check (cancellable);
                done = true;
                if (watchdog != null) {
                    watchdog.join ();
                }

                if (output_stream != null) {
                    var proc_input = new DataInputStream (output_stream);
                    string line = "";
                    while ((line = proc_input.read_line (null)) != null) {
                        output_builder.append (line + "\n");
                    }
                }

                output = output_builder.str;
            } catch (Error e) {
                warning ("Failed to run pandoc: %s", e.message);
            }

            return res;
        }

        private void watch_dog () {
            int now = 0;
            while (now < wait_time && !done) {
                Thread.usleep (5000);
                now += 5;
            }

            if (!done) {
                cancellable.cancel ();
                warning ("Had to terminate pandoc");
            }

            Thread.exit (0);
            return;
        }

    }

    private bool has_citeproc () {
        bool found = false;
        bool res;
        try {
            string[] command = {
                "pandoc",
                "-h"
            };
            Subprocess pandoc = new Subprocess.newv (command, SubprocessFlags.STDOUT_PIPE);
            var output_stream = pandoc.get_stdout_pipe ();
            res = pandoc.wait ();
            if (output_stream != null) {
                var input = new DataInputStream (output_stream);
                string line = "";
                while ((line = input.read_line (null)) != null) {
                    if (line.down ().contains ("--citeproc")) {
                        found = true;
                    }
                }
            }
        } catch (Error e) {
            warning ("Could not check pandoc: %s", e.message);
        }
        return found;
    }

    public bool make_preview (out string output, string markdown, string citation_file = "") {
        output = "";
        var settings = AppSettings.get_default ();
        string mk_input = "";
        if (settings.export_resolve_paths) {
            mk_input = resolve_paths (markdown);
        } else {
            mk_input = markdown;
        }

        bool res = false;
        bool work_bib = citation_file != "" || needs_bibtex (markdown);
        if (mk_input != "") {
            try {
                string[] command = {
                    "pandoc",
                };
                if (work_bib) {
                    debug ("Activating citations %s", citation_file);
                    command +=  has_citeproc () ? "--citeproc" : "--filter=pandoc-citeproc";
                }
                if (settings.preview_css != "") {
                    File css_file = null;
                    if (settings.preview_css == "modest-splendor") {
                        css_file = File.new_for_path (Path.build_filename(Build.PKGDATADIR, "styles", "preview.css"));
                    } else if (settings.preview_css != "") {
                        css_file = File.new_for_path (Path.build_filename(UserData.css_path, settings.preview_css,"preview.css"));
                    }
                    if (css_file != null && css_file.query_exists ()) {
                        command += "--css";
                        command += css_file.get_path ();
                    }
                }
                if (citation_file != "") {
                    command += "--bibliography=" + citation_file;
                }
                PandocThinking runner = new PandocThinking (300);
                if (!runner.run_pandoc_std_in_out_command (ref command, ref mk_input, out output)) {
                    generate_discount_html (mk_input, out output);
                }
            } catch (Error e) {
                warning ("Could not generate preview: %s", e.message);
            }
        }

        return res;
    }

    public bool make_epub (string output_file, string markdown) {
        var settings = AppSettings.get_default ();
        string resolved_mkd = resolve_paths (markdown);
        string temp_file = FileManager.save_temp_file (resolved_mkd);
        bool res = false;
        if (temp_file != "") {
            try {
                bool work_bib =  needs_bibtex (markdown);
                string[] command = {
                    "pandoc",
                    temp_file,
                    "-o",
                    output_file
                };
                if (work_bib) {
                    command +=  has_citeproc () ? "--citeproc" : "--filter=pandoc-citeproc";
                }
                if (settings.preview_css != "") {
                    File css_file = null;
                    if (settings.preview_css == "modest-splendor") {
                        css_file = File.new_for_path (Path.build_filename(Build.PKGDATADIR, "styles", "preview.css"));
                    } else if (settings.preview_css != "") {
                        css_file = File.new_for_path (Path.build_filename(UserData.css_path, settings.preview_css,"preview.css"));
                    }
                    if (css_file != null && css_file.query_exists ()) {
                        command += "--css";
                        command += css_file.get_path ();
                    }
                }
                Subprocess pandoc = new Subprocess.newv (command, SubprocessFlags.STDERR_MERGE);
                res = pandoc.wait ();
                File temp = File.new_for_path (temp_file);
                temp.delete ();
            } catch (Error e) {
                warning ("Could not generate epub: %s", e.message);
            }
        }

        return res;
    }

    public bool make_docx (string output_file, string markdown) {
        string temp_file = FileManager.save_temp_file (resolve_paths (markdown));
        bool res = false;
        if (temp_file != "") {
            try {
                bool work_bib = needs_bibtex (markdown);
                string[] command = {
                    "pandoc",
                    "-s",
                    temp_file,
                    "-o",
                    output_file
                };
                if (work_bib) {
                    command +=  has_citeproc () ? "--citeproc" : "--filter=pandoc-citeproc";
                }
                Subprocess pandoc = new Subprocess.newv (command, SubprocessFlags.STDERR_MERGE);
                res = pandoc.wait ();
                File temp = File.new_for_path (temp_file);
                temp.delete ();
            } catch (Error e) {
                warning ("Could not generate epub: %s", e.message);
            }
        }

        return res;
    }

    public bool make_md_from_file (string output_file_path, string input_file_path) {
        File output_file = File.new_for_path (output_file_path);
        File input_file = File.new_for_path (input_file_path);
        bool res = false;
        if (output_file.query_exists ()) {
            warning ("%s already exists, exiting", output_file_path);
            return res;
        }

        if (!input_file.query_exists ()) {
            warning ("%s does not exist, exiting", output_file_path);
            return res;
        }

        try {
            string[] command = {
                "pandoc",
                "-o",
                output_file.get_path (),
                input_file.get_path ()
            };
            Subprocess pandoc = new Subprocess.newv (command, SubprocessFlags.STDERR_MERGE);
            res = pandoc.wait ();
        } catch (Error e) {
            warning ("Could not generate epub: %s", e.message);
        }

        return res;
    }

    public bool make_tex (string output_file, string markdown) {
        var settings = AppSettings.get_default ();
        string temp_file = "";
        if (settings.export_resolve_paths) {
            temp_file = FileManager.save_temp_file (resolve_paths (markdown));
        } else {
            temp_file = FileManager.save_temp_file (markdown);
        }

        bool res = false;
        if (temp_file != "") {
            try {
                bool work_bib = markdown.contains ("bibliography:");
                string[] command = {
                    "pandoc",
                    "-s",
                    temp_file,
                    "-o",
                    output_file
                };
                if (work_bib) {
                    command +=  has_citeproc () ? "--citeproc" : "--filter=pandoc-citeproc";
                }
                Subprocess pandoc = new Subprocess.newv (command, SubprocessFlags.STDERR_MERGE);
                res = pandoc.wait ();
                File temp = File.new_for_path (temp_file);
                temp.delete ();
            } catch (Error e) {
                warning ("Could not generate epub: %s", e.message);
            }
        }

        return res;
    }

    public Gee.Map<string, string> file_image_map (string markdown, string path = "") {
        Gee.Map<string, string> sub_files = new Gee.HashMap<string, string> ();

        RegexEvalCallback add_upload_paths = (match_info, result) =>
        {
            if (match_info.get_match_count () > 2) {
                var url = match_info.fetch (2);
                string abs_path = "";
                if (!url.contains (":") && find_file_to_upload (url, "", out abs_path) && abs_path != "") {
                    sub_files.set (url, abs_path);
                }
            } else {
                var url = match_info.fetch (1);
                string abs_path = "";
                if (!url.contains (":") && find_file_to_upload (url, "", out abs_path) && abs_path != "") {
                    sub_files.set (url, abs_path);
                }
            }
            return false;
        };
        manipulate_markdown_local_paths (markdown, path,
            add_upload_paths,
            add_upload_paths,
            add_upload_paths,
            add_upload_paths);

            return sub_files;
    }

    public Gee.LinkedList<string> file_import_paths (string markdown) {
        Gee.LinkedList<string> sub_files = new Gee.LinkedList<string> ();

        RegexEvalCallback add_import_paths = (match_info, result) =>
        {
            warning ("Found: %d", match_info.get_match_count ());
            if (match_info.get_match_count () > 2) {
                var url = match_info.fetch (2);
                string abs_path = "";
                if (!url.contains (":")) {
                    sub_files.add (url);
                    warning ("adding: %s", url);
                }
            } else {
                var url = match_info.fetch (1);
                string abs_path = "";
                if (!url.contains (":")) {
                    sub_files.add (url);
                    warning ("adding: %s", url);
                }
            }
            return false;
        };
        manipulate_markdown_local_paths (markdown, "",
            add_import_paths,
            add_import_paths,
            add_import_paths,
            add_import_paths);

        return sub_files;
    }

    public string manipulate_markdown_local_paths (
        string markdown,
        string path,
        RegexEvalCallback markdown_img_callback,
        RegexEvalCallback css_url_callback,
        RegexEvalCallback src_callback,
        RegexEvalCallback cover_callback) {

        string processed_mk = markdown;
        try {
            Regex url_search = new Regex ("\\((.+?)\\)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex src_search = new Regex ("src=['\"](.+?)['\"]", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex css_url_search = new Regex ("url\\(['\"]?(.+?)['\"]?\\)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex cover_image_search = new Regex ("(cover-image|coverimage|feature_image|featureimage|featured_image|csl|featuredimage|bibliography):\\s*['\"]?(.+?)['\"]?\\s*$", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);

            processed_mk = url_search.replace_eval (
                processed_mk,
                (ssize_t) processed_mk.length,
                0,
                RegexMatchFlags.NOTEMPTY,
                markdown_img_callback);

            processed_mk = css_url_search.replace_eval (
                processed_mk,
                (ssize_t) processed_mk.length,
                0,
                RegexMatchFlags.NOTEMPTY,
                css_url_callback);

            processed_mk = src_search.replace_eval (
                processed_mk,
                (ssize_t) processed_mk.length,
                0,
                RegexMatchFlags.NOTEMPTY,
                src_callback);

            processed_mk = cover_image_search.replace_eval (
                processed_mk,
                (ssize_t) processed_mk.length,
                0,
                RegexMatchFlags.NOTEMPTY,
                cover_callback);
        } catch (Error e) {
            warning ("Error generating preview: %s", e.message);
        }

        return processed_mk;
    }

    public string resolve_paths (string markdown, string path = "") {
        return manipulate_markdown_local_paths (markdown, path,
            (match_info, result) =>
                {
                    result.append ("(");
                    var url = match_info.fetch (1);
                    result.append (find_file (url, path));
                    result.append (")");
                    return false;
                },
            (match_info, result) =>
                {
                    result.append ("url(");
                    var url = match_info.fetch (1);
                    result.append (find_file (url, path));
                    result.append (")");
                    return false;
                },
            (match_info, result) =>
                {
                    result.append ("src=\"");
                    var url = match_info.fetch (1);
                    result.append (find_file (url, path));
                    result.append ("\"");
                    return false;
                },
            (match_info, result) =>
                {
                    var key = match_info.fetch (1);
                    result.append (key + ": ");
                    var url = match_info.fetch (2);
                    result.append (find_file (url, path));
                    return false;
                });
    }

    private bool find_file_to_upload (string url, string path, out string absolute_path) {
        string result = "";
        string file = Path.build_filename (".", url);
        if (url.index_of_char (':') != -1) {
            result = url;
        } else if (url.index_of_char ('.') == -1) {
            result = url;
        } else if (FileUtils.test (url, FileTest.EXISTS)) {
            File res_file = File.new_for_path (url);
            result = res_file.get_path ();
        } else if (FileUtils.test (file, FileTest.EXISTS)) {
            File res_file = File.new_for_path (file);
            result = res_file.get_path ();
        } else {
            string search_path = "";
            if (path == "") {
                Sheet? search_sheet = SheetManager.get_sheet ();
                search_path = (search_sheet != null) ? Path.get_dirname (search_sheet.file_path ()) : "";
            } else {
                search_path = path;
            }
            int idx = 0;
            while (search_path != "" && ThiefApp.get_instance ().library.file_in_library (search_path)) {
                file = Path.build_filename (search_path, url);
                if (FileUtils.test (file, FileTest.EXISTS)) {
                    File tmp = File.new_for_path (file);
                    result = tmp.get_path ();
                    break;
                }

                // Check in static folder
                file = Path.build_filename (search_path, "static", url);
                if (FileUtils.test (file, FileTest.EXISTS)) {
                    File tmp = File.new_for_path (file);
                    result = tmp.get_path ();
                    break;
                }

                idx = search_path.last_index_of_char (Path.DIR_SEPARATOR);
                if (idx != -1) {
                    search_path = search_path[0:idx];
                } else {
                    result = url;
                    break;
                }
            }
        }

        if (result != "") {
            absolute_path = result;
            return true;
        } else {
            absolute_path = "";
            return false;
        }
    }

    public string find_file (string url, string path = "") {
        string result = "";
        if (find_file_to_upload (url, path, out result)) {
            return result;
        } else {
            return url;
        }
    }

    public bool needs_bibtex (string markdown) {
        string temp = "";
        return get_bibtex_path (markdown, ref temp);
    }

    public bool get_bibtex_path (string markdown, ref string bibtex_path) {
        string buffer = markdown;
        Regex headers = null;
        try {
            headers = new Regex ("^\\s*(.+)\\s*:\\s+(.*)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
        } catch (Error e) {
            warning ("Could not compile regex: %s", e.message);
        }

        MatchInfo matches;

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
                        if (matches.fetch (1).ascii_down() == "bibliography") {
                            string temp_bibliography = matches.fetch (2);
                            if (temp_bibliography.has_prefix ("\"") && temp_bibliography.has_suffix ("\"")) {
                                temp_bibliography = temp_bibliography.substring (1, temp_bibliography.length - 2);
                            }
                            bibtex_path = temp_bibliography;
                            return true;
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
                    if (quick_parse.has_prefix ("bibliography")) {
                        string temp_bibliography = quick_parse.substring (quick_parse.index_of (":") + 1);
                        if (temp_bibliography.has_prefix ("\"") && temp_bibliography.has_suffix ("\"")) {
                            temp_bibliography = temp_bibliography.substring (1, temp_bibliography.length - 2);
                        }
                        bibtex_path = temp_bibliography;
                        return true;
                    }
                }

                i++;
            }
        }

        return false;
    }
}