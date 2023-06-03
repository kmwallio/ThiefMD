/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified October 14, 2020
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
using ThiefMD.Controllers;

namespace ThiefMD.Widgets {
    public class MarkdownCheatSheet : Hdy.Window {
        Hdy.HeaderBar headerbar;

        public MarkdownCheatSheet () {
            build_ui ();
        }

        private void build_ui () {
            Gtk.Box vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            headerbar = new Hdy.HeaderBar ();
            headerbar.set_title ("Cheat Sheet");
            var header_context = headerbar.get_style_context ();
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);
            header_context.add_class ("thiefmd-toolbar");

            var grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.margin = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.vexpand = true;
            grid.hexpand = true;

            string hashtags = "";
            for (int h = 1; h <= 6; h++) {
                for (int i = 0; i < h; i++) {
                    hashtags += "#";
                }
                hashtags += " " + _("Heading") + " " + h.to_string() + "\n";
            }
            var heading = new Gtk.Label ("<b>" + hashtags + "</b>");
            heading.xalign = 0;
            heading.use_markup = true;
            grid.add (heading);

            //  var sp0 = new Gtk.Label (" ");
            //  grid.add (sp0);

            var bold_italic_string = new Gtk.Label ("<b>**Strong**</b>\n<i>*Emphasis*</i>\n~~<s>Deleted</s>~~\n`<tt>Code</tt>`");
            bold_italic_string.use_markup = true;
            bold_italic_string.xalign = 0;
            grid.add (bold_italic_string);

            //  var sp1 = new Gtk.Label (" ");
            //  grid.add (sp1);

            var url = new Gtk.Label ("[Link](<u>http://to-site.com</u>)\n<b>!</b>[Image Description](<u>/path/to/image.png</u>)");
            url.use_markup = true;
            url.xalign = 0;
            grid.add (url);

            //  var sp2 = new Gtk.Label (" ");
            //  grid.add (sp2);

            var ul = new Gtk.Label ("<b>*</b> List Item 1\n<b>*</b> List Item 2");
            ul.use_markup = true;
            ul.xalign = 0;
            grid.add (ul);

            var ol = new Gtk.Label ("<b>1.</b> List Item 1\n<b>2.</b> List Item 2");
            ol.use_markup = true;
            ol.xalign = 0;
            grid.add (ol);

            //  var sp3 = new Gtk.Label (" ");
            //  grid.add (sp3);

            var blockquote = new Gtk.Label ("<b>&gt;</b> Blockquote");
            blockquote.use_markup = true;
            blockquote.xalign = 0;
            grid.add (blockquote);

            //  var sp4 = new Gtk.Label (" ");
            //  grid.add (sp4);

            var code_block = new Gtk.Label ("```python\n<tt>print (\"Hello World!\")</tt>\n```");
            code_block.use_markup = true;
            code_block.xalign = 0;
            grid.add (code_block);

            //  var sp5 = new Gtk.Label (" ");
            //  grid.add (sp5);

            var hr = new Gtk.Label ("<b>***</b> (Horizontal Rule)");
            hr.use_markup = true;
            hr.xalign = 0;
            grid.add (hr);


            headerbar.set_show_close_button (true);
            transient_for = ThiefApp.get_instance ();
            destroy_with_parent = true;
            vbox.add (headerbar);
            vbox.add (grid);
            add (vbox);

            int w, h;
            ThiefApp.get_instance ().get_size (out w, out h);

            show_all ();

            delete_event.connect (() => {
                return false;
            });
        }
   }
}