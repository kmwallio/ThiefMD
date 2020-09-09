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

        public Preview () {
            Object(user_content_manager: new UserContentManager());
            visible = true;
            vexpand = true;
            hexpand = true;
            var settingsweb = get_settings();
            settingsweb.enable_plugins = false;
            settingsweb.enable_page_cache = false;
            settingsweb.enable_developer_extras = false;
            settingsweb.javascript_can_open_windows_automatically = false;

            update_html_view ();
            var settings = AppSettings.get_default ();
            settings.changed.connect (update_html_view);
            connect_signals ();
        }

        public static void update_view () {
            PreviewWindow.update_preview_title ();
            get_instance ().update_html_view ();
        }

        public static Preview get_instance () {
            if (instance == null) {
                instance = new Widgets.Preview ();
            }

            return instance;
        }

        protected override bool context_menu (
            ContextMenu context_menu,
            Gdk.Event event,
            HitTestResult hit_test_result
        ) {
            return true;
        }

        private string set_stylesheet () {
            var settings = AppSettings.get_default ();
            var style = "";
                style += """<link rel="stylesheet" type="text/css" href='""";
                style += Build.PKGDATADIR + "/styles/preview.css";
                style += "' />\n";
                style += """<link rel="stylesheet" type="text/css" href='""";
                style += Build.PKGDATADIR + "/styles/highlight.css";
                style += "' />\n";
                style += """<link rel="stylesheet" type="text/css" href='""";
                style += Build.PKGDATADIR + "/styles/katex.min.css";
                style += "' />\n";

                // If typewriter scrolling is enabled, add padding to match editor
            bool typewriter_active = settings.typewriter_scrolling;
            if (typewriter_active) {
                style = style + """<style>
                .markdown-body{padding-top:40%;padding-bottom:40%}
                </style>""";
            } else {
                style = style + """<style>
                .markdown-body{padding-bottom:10%}
                </style>""";
            }

            return style;
        }

        private void connect_signals () {
            create.connect ((navigation_action) => {
                launch_browser (navigation_action.get_request().get_uri ());
                return (Gtk.Widget) null;
            });

            decide_policy.connect ((decision, type) => {
                switch (type) {
                    case WebKit.PolicyDecisionType.NEW_WINDOW_ACTION:
                        if (decision is WebKit.ResponsePolicyDecision) {
                            launch_browser ((decision as WebKit.ResponsePolicyDecision).request.get_uri ());
                        }
                    break;
                    case WebKit.PolicyDecisionType.RESPONSE:
                        if (decision is WebKit.ResponsePolicyDecision) {
                            var policy = (WebKit.ResponsePolicyDecision) decision;
                            launch_browser (policy.request.get_uri ());
                            return false;
                        }
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
        }

        private void launch_browser (string url) {
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
            processed_mk = FileManager.get_yamlless_markdown(raw_mk, 0, true, true, false);

            return (processed_mk.chomp () != "");
        }

        private string find_file (string url) {
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
                Sheet search_sheet = SheetManager.get_sheet ();
                string sheet_path = (search_sheet != null) ? Path.get_dirname (search_sheet.file_path ()) : "";
                int idx = 0;
                while (sheet_path != "") {
                    file = Path.build_filename (sheet_path, url);
                    if (FileUtils.test (file, FileTest.EXISTS)) {
                        result = file;
                        break;
                    }

                    idx = sheet_path.last_index_of_char ('/');
                    if (idx != -1) {
                        sheet_path = sheet_path[0:idx];
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

        private string process () {
            string text = Widgets.Editor.scroll_text; // buffer.text;
            string processed_mk;

            Regex url_search = new Regex ("\\((.+?)\\)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex src_search = new Regex ("src=['\"](.+?)['\"]", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            Regex css_url_search = new Regex ("url\\(['\"]?(.+?)['\"]?\\)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);

            get_preview_markdown (text, out processed_mk);
            processed_mk = url_search.replace_eval (
                processed_mk,
                (ssize_t) processed_mk.length,
                0,
                RegexMatchFlags.NOTEMPTY,
                (match_info, result) =>
                {
                    result.append ("(");
                    var url = match_info.fetch (1);
                    result.append (find_file (url));
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
                    result.append (find_file (url));
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
                        result.append (find_file (url));
                        result.append ("\"");
                        return false;
                    });

            var mkd = new Markdown.Document.from_gfm_string (processed_mk.data, 0x00200000 + 0x00004000 + 0x02000000 + 0x01000000 + 0x04000000 + 0x00400000 + 0x10000000 + 0x40000000);
            mkd.compile (0x00200000 + 0x00004000 + 0x02000000 + 0x01000000 + 0x00400000 + 0x04000000 + 0x40000000 + 0x10000000);

            string result;
            mkd.get_document (out result);

            return result;
        }

        private string get_javascript () {
            var settings = AppSettings.get_default ();
            string script;

            // If typewriter scrolling is enabled, add padding to match editor
            bool typewriter_active = settings.typewriter_scrolling;

            // Find our ThiefMark and move it to the same position of the cursor
            script = """<script>
            const element = document.getElementById('thiefmark');
            const textOnTop = element.offsetTop;
            const middle = textOnTop - (window.innerHeight * %f);
            window.scrollTo(0, middle);
            </script>
            <script>
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
            <script>hljs.initHighlightingOnLoad();</script>""".printf((typewriter_active) ? Constants.TYPEWRITER_POSITION : Editor.cursor_position);

            return script;
        }

        private string get_javascript_header () {
            string script;

               // Find our ThiefMark and move it to the same position of the cursor
            script = "<script src='";
            script += Build.PKGDATADIR + "/scripts/highlight.js";
            script += "'></script>\n";
            script += """<script src='""";
            script += Build.PKGDATADIR + "/scripts/katex.min.js";
            script += "'></script>";
            script += "<script src='";
            script += Build.PKGDATADIR + "/scripts/auto-render.min.js";
            script += "'></script>";

            return script;
        }

        public void update_html_view () {
            string stylesheet = set_stylesheet ();
            string markdown = process ();
            string script = get_javascript ();
            string headerscript = get_javascript_header ();
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
            </html>""".printf(stylesheet, headerscript, markdown, script);
            adjust_thief_mark ();
            this.load_html (html, "file:///");
        }

        private void adjust_thief_mark () {
            html = html.replace (ThiefProperties.THIEF_MARK_CONST, ThiefProperties.THIEF_MARK);
        }
    }
}
