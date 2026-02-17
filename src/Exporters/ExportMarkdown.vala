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
using ThiefMD.Controllers;

namespace ThiefMD.Exporters {
    public class ExportMarkdown : ExportBase {
        public override string export_name { get; protected set; }
        public override string export_css { get; protected set; }
        private PublisherPreviewWindow publisher_instance;

        public ExportMarkdown () {
            export_name = "Markdown";
            export_css = "preview";
        }

        public override string update_markdown (string markdown) {
            return markdown;
        }

        public override void attach (PublisherPreviewWindow ppw) {
            publisher_instance = ppw;
            return;
        }

        public override void detach () {
            publisher_instance = null;
            return;
        }

        public override bool export () {
            var markdown_filter = new Gtk.FileFilter ();
            markdown_filter.set_filter_name (_("Markdown files"));
            markdown_filter.add_mime_type ("text/markdown");
            markdown_filter.add_pattern ("*.md");
            markdown_filter.add_pattern ("*.markdown");

            File? new_novel = Dialogs.get_target_save_file_with_extension (
                _("Export Markdown"),
                markdown_filter,
                "md");

            if (new_novel == null) {
                return true;
            }

            try {
                if (new_novel.query_exists ()) {
                    new_novel.delete ();
                }

                FileManager.save_file (
                    new_novel,
                    publisher_instance.get_export_markdown ().data);

            } catch (Error e) {
                warning ("Could not save markdown file: %s", e.message);
            }

            if (new_novel.query_exists ()) {
                return true;
            } else {
                return false;
            }
        }
    }
}