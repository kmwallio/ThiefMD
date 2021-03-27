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
    public abstract class ExportBase {
        // Name to show in Export Window Drop Down
        public abstract string export_name { get; protected set; }

        // Compatible CSS for Exporter  { "preview", "print"}
        public abstract string export_css { get; protected set; }

        // Support handling of markdown files
        public bool supports_markdown { get; protected set; default = true; }

        // Support handling of fountain files
        public bool supports_fountain { get; protected set; default = false; }

        public abstract string update_markdown (string markdown);
        public abstract void attach (PublisherPreviewWindow ppw);
        public abstract void detach ();
        public abstract bool export ();
    }
}