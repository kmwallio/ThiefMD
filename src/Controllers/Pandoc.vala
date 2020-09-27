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
    public bool make_epub (string output_file, string markdown) {
        string resolved_mkd = resolve_paths (markdown);
        string temp_file = FileManager.save_temp_file (resolved_mkd);
        bool res = false;
        if (temp_file != "") {
            try {
                string[] command = {
                    "pandoc",
                    temp_file,
                    "-o",
                    output_file
                };
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
                string[] command = {
                    "pandoc",
                    "-s",
                    temp_file,
                    "-o",
                    output_file
                };
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
                string[] command = {
                    "pandoc",
                    "-s",
                    temp_file,
                    "-o",
                    output_file
                };
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

    public string resolve_paths (string markdown, string path = "") {
        string processed_mk = markdown;

        try {
            Regex url_search = new Regex ("\\((.+?)\\)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex src_search = new Regex ("src=['\"](.+?)['\"]", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex css_url_search = new Regex ("url\\(['\"]?(.+?)['\"]?\\)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex cover_image_search = new Regex ("cover-image:\\s*['\"]?(.+?)['\"]?\\s*$", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);

            processed_mk = url_search.replace_eval (
                processed_mk,
                (ssize_t) processed_mk.length,
                0,
                RegexMatchFlags.NOTEMPTY,
                (match_info, result) =>
                {
                    result.append ("(");
                    var url = match_info.fetch (1);
                    result.append (find_file (url, path));
                    result.append (")");
                    return false;
                });

            processed_mk = css_url_search.replace_eval (
                processed_mk,
                (ssize_t) processed_mk.length,
                0,
                RegexMatchFlags.NOTEMPTY,
                (match_info, result) =>
                {
                    result.append ("url(");
                    var url = match_info.fetch (1);
                    result.append (find_file (url, path));
                    result.append (")");
                    return false;
                });

            processed_mk = src_search.replace_eval (
                    processed_mk,
                    (ssize_t) processed_mk.length,
                    0,
                    RegexMatchFlags.NOTEMPTY,
                    (match_info, result) =>
                    {
                        result.append ("src=\"");
                        var url = match_info.fetch (1);
                        result.append (find_file (url, path));
                        result.append ("\"");
                        return false;
                    });

            processed_mk = cover_image_search.replace_eval (
                processed_mk,
                (ssize_t) processed_mk.length,
                0,
                RegexMatchFlags.NOTEMPTY,
                (match_info, result) =>
                {
                    result.append ("cover-image: ");
                    var url = match_info.fetch (1);
                    result.append (find_file (url, path));
                    return false;
                });
        } catch (Error e) {
            warning ("Error generating preview: %s", e.message);
        }

        return processed_mk;
    }

    private string find_file (string url, string path) {
        string result = "";
        string file = Path.build_filename (".", url);
        if (url.index_of_char (':') != -1) {
            result = url;
        } else if (url.index_of_char ('.') == -1) {
            result = url;
        } else if (FileUtils.test (url, FileTest.EXISTS)) {
            result = url;
        } else if (FileUtils.test (file, FileTest.EXISTS)) {
            result = file;
        } else {
            string search_path = "";
            if (path == "") {
                Sheet? search_sheet = SheetManager.get_sheet ();
                search_path = (search_sheet != null) ? Path.get_dirname (search_sheet.file_path ()) : "";
            } else {
                search_path = path;
            }
            int idx = 0;
            while (search_path != "") {
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

                idx = search_path.last_index_of_char ('/');
                if (idx != -1) {
                    search_path = search_path[0:idx];
                } else {
                    result = url;
                    break;
                }
            }
        }

        if (result != "") {
            return result;
        } else {
            return url;
        }
    }
}