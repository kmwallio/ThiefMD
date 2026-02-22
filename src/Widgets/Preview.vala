/*
* Copyright (c) 2017 Lains
*
* Modified July 7, 2018 for ThiefMD
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
*/

using WebKit;
using ThiefMD;
using ThiefMD.Controllers;

namespace ThiefMD.Widgets {
    public class Preview : WebKit.WebView {
        private static Preview? instance = null;
        public string html;
        public bool exporting = false;
        public bool print_only = false;
        public string? override_css = null;
        public string base_path = "";

        public Preview () {
            Object(user_content_manager: new UserContentManager());
            visible = true;
            vexpand = true;
            hexpand = true;
            var settingsweb = get_settings();
            settingsweb.enable_page_cache = false;
            settingsweb.enable_developer_extras = false;
            settingsweb.javascript_can_open_windows_automatically = false;
            connect_signals ();
        }

        public static Preview get_instance () {
            if (instance == null) {
                instance = new Widgets.Preview ();
                instance.exporting = false;
            }

            return instance;
        }

        private string set_stylesheet (bool render_fountain = false) {
            var settings = AppSettings.get_default ();
            if (!render_fountain) {
                return get_style_header (override_css != null ? override_css : settings.preview_css, override_css != null ? override_css : settings.print_css);
            } else {
                return get_fountain_header ();
            }
        }

        public string get_fountain_header () {
            var settings = AppSettings.get_default ();
            var style = "";
            if (!exporting) {
                style += """<link rel="stylesheet" type="text/css" href='""";
                style += Build.PKGDATADIR + "/styles/fountain.css";
                style += "' />\n";
                style += "\n<style>\n";
                style += """
                body {
                    max-width: 80ch;
                    margin: 0 auto 0 auto;
                }

                hr {
                    border: none;
                    visibility: visible;
                    border-top: 3px double #333;
                    color: #333;
                    overflow: visible;
                    text-align: center;
                    height: 5px;
                }
                
                hr:after {
                    background: #fff;
                    content: '§ Page Break §';
                    padding: 0 4px;
                    position: relative;
                    top: -13px;
                }
                """;
                if (settings.typewriter_scrolling && override_css == null) {
                    style += "\nbody{padding-top:60%;padding-bottom:50%}\n";
                }
                style += "\n</style>\n";
            } else {
                style += "\n<style>\n";
                style += FileManager.get_file_contents (Build.PKGDATADIR + "/styles/fountain.css");
                style += """
                p.section { display: none; visibility: invisible; }
                p.synopsis { display: none; visibility: invisible; }
                """;
                style += "\n</style>\n";
            }
            return style;
        }

        public string get_style_header (string preview_css = "", string print_css = "") {
            var settings = AppSettings.get_default ();
            var style = "";
            if (!exporting) {
                style += """<link rel="stylesheet" type="text/css" href='""";
                style += Build.PKGDATADIR + "/styles/highlight.css";
                style += "' />\n";
                style += """<link rel="stylesheet" type="text/css" href='""";
                style += Build.PKGDATADIR + "/styles/katex.min.css";
                style += "' />\n";
            } else {
                style += """<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.12.0/dist/katex.min.css" integrity="sha384-AfEj0r4/OFrOo5t7NnNe46zW/tFgW6x/bCJG8FqQCEo3+Aro6EYUG4+cU+KJWu/X" crossorigin="anonymous">""";
            }

            // If typewriter scrolling is enabled, add padding to match editor

            style += "\n<style>\n";
            if (!print_only) {
                File css_file = null;
                if (preview_css == "modest-splendor") {
                    css_file = File.new_for_path (Path.build_filename(Build.PKGDATADIR, "styles", "preview.css"));
                } else if (preview_css != "") {
                    css_file = File.new_for_path (Path.build_filename(UserData.css_path, preview_css,"preview.css"));
                }
                if (css_file != null && css_file.query_exists ()) {
                    style = style + FileManager.get_file_contents (css_file.get_path ());
                }
            }

            if (exporting) {
                style += FileManager.get_file_contents (Build.PKGDATADIR + "/styles/highlight.css");
                if (print_only) {
                    string? weasyprint_loc = Environment.find_program_in_path ("weasyprint");
                    if (weasyprint_loc != null && weasyprint_loc != "") {
                        style += "\n\n@page {\n";
                        style += "    margin: %fin %fin %fin %fin;\n".printf (
                            settings.export_top_bottom_margins,
                            settings.export_side_margins,
                            settings.export_top_bottom_margins,
                            settings.export_side_margins);
                        style += "    size: %s;\n".printf (ThiefProperties.PAPER_SIZES_CSS_NAME[array_index_of (ThiefProperties.PAPER_SIZES_GTK_NAME, settings.export_paper_size)]);
                        style += "}\n\n";
                    }
                }
            } else {
                if (settings.typewriter_scrolling && override_css == null) {
                    style += "\n.markdown-body{padding-top:60%;padding-bottom:50%}\n";
                }
            }

            if (print_css == "modest-splendor") {
                if (print_only) {
                    style += "\n" + ThiefProperties.PRINT_CSS + "\n";
                }
                style += "\n@media print {\n";
                style += ThiefProperties.PRINT_CSS;
                style += "}\n";
            } else if (print_css != "") {
                File css_file = File.new_for_path (Path.build_filename(UserData.css_path, print_css,"print.css"));
                if (css_file.query_exists ()) {
                    if (print_only) {
                        style += "\n" + FileManager.get_file_contents (css_file.get_path ()) + "\n";
                    }
                    style += "\n@media print {\n";
                    style += FileManager.get_file_contents (css_file.get_path ());
                    style += "}\n";
                }
            } else {
                style += ThiefProperties.NO_CSS_CSS;
            }
            style += "\n</style>\n";

            return style;
        }

        private void connect_signals () {
            create.connect ((navigation_action) => {
                launch_browser (navigation_action.get_request().get_uri ());
                return (WebKit.WebView?) null;
            });

            decide_policy.connect ((decision, type) => {
                switch (type) {
                    case WebKit.PolicyDecisionType.NEW_WINDOW_ACTION:
                        if (decision is WebKit.ResponsePolicyDecision) {
                            WebKit.ResponsePolicyDecision response_decision = (decision as WebKit.ResponsePolicyDecision);
                            if (response_decision != null && 
                                response_decision.request != null)
                            {
                                launch_browser (response_decision.request.get_uri ());
                            }
                        }
                    break;
                    case WebKit.PolicyDecisionType.RESPONSE:
                        if (decision is WebKit.ResponsePolicyDecision) {
                            var policy = (WebKit.ResponsePolicyDecision) decision;
                            launch_browser (policy.request.get_uri ());
                            return false;
                        }
                    break;
                    case WebKit.PolicyDecisionType.NAVIGATION_ACTION:
                    break;
                }

                return true;
            });

            load_changed.connect ((event) => {
                if (event == WebKit.LoadEvent.FINISHED) {
                    var rectangle = get_window_properties ().get_geometry ();
                    set_size_request (rectangle.width, rectangle.height);
                }
            });

            load_failed.connect ((event, uri, error) => {
                launch_browser (uri);
                return false;
            });
        }

        private string last_url;
        private void launch_browser (string url) {
            var thief_instance = ThiefApp.get_instance ();
            string decoded_url = Uri.unescape_string (url);
            warning (url);
            if (decoded_url == null || last_url == url) {
                stop_loading ();
                last_url = "";
                return;
            }

            last_url = url;

            string possible_markdown = get_possible_markdown_url (url);
            if (possible_markdown != "" && thief_instance.library.file_in_library (possible_markdown)) {
                var load_sheet = thief_instance.library.find_sheet_for_path (possible_markdown);
                if (load_sheet != null) {
                    load_sheet.clicked ();
                    Timeout.add (250, () => {
                        UI.update_preview ();
                        return false;
                    });
                }
                stop_loading ();
                return;
            }

            if (decoded_url.length > 8 && decoded_url.has_prefix ("file://") && thief_instance.library.file_in_library (decoded_url.substring (7))) {
                var load_sheet = thief_instance.library.find_sheet_for_path (decoded_url.substring (7));
                if (load_sheet != null) {
                    load_sheet.clicked ();
                    Timeout.add (250, () => {
                        UI.update_preview ();
                        return false;
                    });
                }
                stop_loading ();
                return;
            }
            
            if (!url.contains ("/embed/")) {
                try {
                    AppInfo.launch_default_for_uri (url, null);
                } catch (Error e) {
                    warning ("No app to handle urls: %s", e.message);
                }
                stop_loading ();
            }
        }

        private bool get_preview_markdown (string raw_mk, out string processed_mk) {
            var settings = AppSettings.get_default ();

            // Resolve paths to images or local files if needed
            if (!exporting || settings.export_resolve_paths) {
                string file_path = (base_path == "") ? settings.last_file.substring(0, settings.last_file.last_index_of(Path.DIR_SEPARATOR_S)) : base_path;
                processed_mk = Pandoc.resolve_paths (raw_mk, file_path);
            } else {
                processed_mk = raw_mk;
            }

            // Use fast preview if no special cases are needed
            string bib_file = (!exporting) ? find_bibtex_for_sheet (settings.last_file) : "";
            bool need_pandoc = Pandoc.needs_bibtex (raw_mk) || Pandoc.has_discount_issue (processed_mk);

            warning ("NEED PANDOC: %s", need_pandoc? "yes":"no");

            // BibTeX File
            if (!exporting && (settings.last_file.has_suffix ("bib") || settings.last_file.has_suffix ("bibtex"))) {
                BibTex.Parser bib_parser = new BibTex.Parser (bib_file);
                bib_parser.parse_file ();
                string bib_mk = "";
                foreach (var label in bib_parser.get_labels ()) {
                    bib_mk += "1. **\\@" + label + "**: *@" + label + "*\n";
                }
                return Pandoc.make_preview (out processed_mk, bib_mk, bib_file);
            }

            bool render_citations = false;
            if (bib_file != "") {
                BibTex.Parser bib_parser = new BibTex.Parser (bib_file);
                bib_parser.parse_file ();
                foreach (var label in bib_parser.get_labels ()) {
                    render_citations = render_citations || processed_mk.contains ("@" + label);
                }
            }

            if (render_citations) {
                return Pandoc.make_preview (out processed_mk, raw_mk, bib_file, exporting);
            } else {
                string title, date;
                processed_mk = FileManager.get_yamlless_markdown(
                    processed_mk,
                    0,      // Cap number of lines
                    out title,
                    out date,
                    true,   // Include empty lines
                    settings.export_include_yaml_title, // H1 title:
                    false); // Include date

                if (exporting || need_pandoc) {
                    return Pandoc.make_preview (out processed_mk, processed_mk, "", exporting);
                } else {
                    Pandoc.generate_discount_html (processed_mk, out processed_mk);
                }
            }

            return (processed_mk.chomp () != "");
        }

        private string get_javascript (bool use_thief_mark) {
            var settings = AppSettings.get_default ();
            string script = "";

            // If typewriter scrolling is enabled, add padding to match editor
            bool typewriter_active = settings.typewriter_scrolling;

            // Find our ThiefMark and move it to the same position of the cursor
            if (use_thief_mark) {
                script = """<script>
                const element = document.getElementById('thiefmark');
                const textOnTop = element.offsetTop;
                const middle = textOnTop - (window.innerHeight * %f);
                window.scrollTo(0, middle);
                </script>""".printf((typewriter_active) ? Constants.TYPEWRITER_POSITION : SheetManager.get_cursor_position ());
            }

            // Default preview javascript
            script += """<script>
            renderMathInElement(document.body,
                {
                    delimeters: [
                        {left: "$$", right: "$$", display: true},
                        {left: "$", right: "$", display: false},
                        {left: "\\(", right: "\\)", display: false},
                        {left: "\\[", right: "\\]", display: true}
                    ]
                });
            </script>
            <script>hljs.initHighlightingOnLoad();</script>""";

            return script;
        }

        private string get_javascript_header (bool render_fountain = false) {
            string script = "";

            if (!render_fountain) {
                if (!exporting) {
                    script = "<script src='";
                    script += Build.PKGDATADIR + "/scripts/highlight.js";
                    script += "'></script>\n";
                    script += """<script src='""";
                    script += Build.PKGDATADIR + "/scripts/katex.min.js";
                    script += "'></script>";
                    script += "<script src='";
                    script += Build.PKGDATADIR + "/scripts/auto-render.min.js";
                    script += "'></script>";
                } else {
                    script = """
                    <script defer src="https://cdn.jsdelivr.net/npm/katex@0.12.0/dist/katex.min.js" integrity="sha384-g7c+Jr9ZivxKLnZTDUhnkOnsh30B4H0rpLUpJ4jAIKs4fnJI+sEnkvrMWph2EDg4" crossorigin="anonymous"></script>
                    <script defer src="https://cdn.jsdelivr.net/npm/katex@0.12.0/dist/contrib/auto-render.min.js" integrity="sha384-mll67QQFJfxn0IYznZYonOWZ644AWYC+Pt2cHqMaRhXVrursRwvLnLaebdGIlYNa" crossorigin="anonymous" onload="renderMathInElement(document.body);"></script>
                    <script src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@10.2.1/build/highlight.min.js"></script>
                    """;
                }
            } else {
                script += "<script src='";
                script += Build.PKGDATADIR + "/scripts/fountain.js";
                script += "'></script>";
            }

            return script;
        }

        public void update_html_view (bool use_thief_mark = true, string markdown = "", bool render_fountain = false) {
            string stylesheet = set_stylesheet (render_fountain);
            string markdown_res = "";
            if (!render_fountain) {
                get_preview_markdown (markdown, out markdown_res);
            } else {
                markdown_res = markdown;
            }
            string script = get_javascript (use_thief_mark);
            string headerscript = get_javascript_header (render_fountain);
            if (!render_fountain) {
                html = """
                <!doctype html>
                <html>
                    <head>
                        <meta charset=utf-8>
                        %s
                        %s
                    </head>
                    <body>
                        <div class=markdown-body>
                            %s
                        </div>
                        %s
                    </body>
                </html>""".printf(stylesheet, headerscript, markdown_res, script);
            } else {
                html = """
                <!doctype html>
                <html>
                    <head>
                        <meta charset=utf-8>
                        %s
                        %s
                    </head>
                    <body>
                        <script type="text/javascript">
                            var file = `%s`;
                            fountain.parse(file, true, function (output) {
                                // output.title - 'Big Fish'
                                // output.html.title_page - '<h1>Big Fish</h1><p class="author">...'
                                // output.html.script - '<h2><span class="bold">FADE IN:</span></h2>...'
                                // output.tokens - [ ... { type: 'transition'. text: '<span class="bold">FADE IN:</span>' } ... ]
                                document.body.innerHTML = output.html.title_page + ((output.html.title_page != "") ? "<div style='clear: both'></div><div style='page-break-before: always'></div>" : "") + output.html.script;
                            });
                        </script>
                        %s
                    </body>
                </html>""".printf(stylesheet, headerscript, markdown_res.replace ("`", "\\`"), script);
            }
            adjust_thief_mark (use_thief_mark);
            this.load_html (html, "file:///");
        }

        private void adjust_thief_mark (bool use_thief_mark) {
            if (use_thief_mark) {
                html = html.replace (ThiefProperties.THIEF_MARK_CONST, ThiefProperties.THIEF_MARK);
            } else {
                html = html.replace (ThiefProperties.THIEF_MARK_CONST, "");
            }
        }
    }
}
