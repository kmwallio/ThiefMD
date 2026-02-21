/*
 * Copyright (C) 2020 kmwallio
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall
 * be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
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
    // Export the current preview as a TextPack (.textpack) archive.
    // TextBundle spec: https://textbundle.org/spec/
    public class ExportTextpack : ExportBase {
        public override string export_name { get; protected set; }
        public override string export_css { get; protected set; }
        private PublisherPreviewWindow publisher_instance;

        public ExportTextpack () {
            export_name = _("TextPack");
            export_css = "preview";
            // TextPack can hold both markdown and fountain screenplays
            supports_fountain = true;
        }

        public override string update_markdown (string markdown) {
            return markdown;
        }

        public override void attach (PublisherPreviewWindow ppw) {
            publisher_instance = ppw;
        }

        public override void detach () {
            publisher_instance = null;
        }

        public override bool export () {
            var textpack_filter = new Gtk.FileFilter ();
            textpack_filter.set_filter_name (_("TextPack files"));
            textpack_filter.add_pattern ("*.textpack");

            File? save_target = Dialogs.get_target_save_file_with_extension (
                _("Export as TextPack"),
                textpack_filter,
                "textpack");

            if (save_target == null) {
                return true;
            }

            string output_path = save_target.get_path ();
            // Capture these now so they're safe to read from the worker thread
            string original_markdown = publisher_instance.get_original_markdown ();
            string base_path = publisher_instance.source_path;
            bool is_fountain = publisher_instance.render_fountain;
            bool success = false;

            Gee.List<string> pack_sayings = new Gee.LinkedList<string> ();
            pack_sayings.add (_("Bundling your brilliance..."));
            pack_sayings.add (_("Packing up the pages..."));
            pack_sayings.add (_("TextPack, incoming!"));

            Thinking worker = new Thinking (_("Exporting TextPack"), () => {
                success = FileManager.export_textpack_from_markdown (original_markdown, output_path, base_path, is_fountain);
            }, pack_sayings, publisher_instance);

            worker.run ();
            return success;
        }
    }
}
