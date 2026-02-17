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
using Adw;

namespace ThiefMD.Widgets {
    public class MarkdownCheatSheet : Gtk.ApplicationWindow {
        Adw.HeaderBar headerbar;
        Adw.WindowTitle title_widget;

        public MarkdownCheatSheet () {
            build_ui ();
        }

        private void build_ui () {
            set_titlebar (null);
            Gtk.Box vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            show_menubar = false;
            headerbar = new Adw.HeaderBar ();
            title_widget = new Adw.WindowTitle ("Cheat Sheet", "");
            headerbar.set_title_widget (title_widget);
            var header_context = headerbar.get_style_context ();
            header_context.add_class ("flat");
            header_context.add_class ("thiefmd-toolbar");
            set_titlebar (headerbar);

            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
            box.margin_top = 12;
            box.margin_bottom = 12;
            box.margin_start = 12;
            box.margin_end = 12;
            box.vexpand = true;
            box.hexpand = true;

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
            box.append (heading);

            //  var sp0 = new Gtk.Label (" ");
            //  grid.add (sp0);

            var bold_italic_string = new Gtk.Label ("<b>**Strong**</b>\n<i>*Emphasis*</i>\n~~<s>Deleted</s>~~\n`<tt>Code</tt>`");
            bold_italic_string.use_markup = true;
            bold_italic_string.xalign = 0;
            box.append (bold_italic_string);

            //  var sp1 = new Gtk.Label (" ");
            //  grid.add (sp1);

            var url = new Gtk.Label ("[Link](<u>http://to-site.com</u>)\n<b>!</b>[Image Description](<u>/path/to/image.png</u>)");
            url.use_markup = true;
            url.xalign = 0;
            box.append (url);

            //  var sp2 = new Gtk.Label (" ");
            //  grid.add (sp2);

            var ul = new Gtk.Label ("<b>*</b> List Item 1\n<b>*</b> List Item 2");
            ul.use_markup = true;
            ul.xalign = 0;
            box.append (ul);

            var ol = new Gtk.Label ("<b>1.</b> List Item 1\n<b>2.</b> List Item 2");
            ol.use_markup = true;
            ol.xalign = 0;
            box.append (ol);

            //  var sp3 = new Gtk.Label (" ");
            //  grid.add (sp3);

            var blockquote = new Gtk.Label ("<b>&gt;</b> Blockquote");
            blockquote.use_markup = true;
            blockquote.xalign = 0;
            box.append (blockquote);

            //  var sp4 = new Gtk.Label (" ");
            //  grid.add (sp4);

            var code_block = new Gtk.Label ("```python\n<tt>print (\"Hello World!\")</tt>\n```");
            code_block.use_markup = true;
            code_block.xalign = 0;
            box.append (code_block);

            //  var sp5 = new Gtk.Label (" ");
            //  grid.add (sp5);

            var hr = new Gtk.Label ("<b>***</b> (Horizontal Rule)");
            hr.use_markup = true;
            hr.xalign = 0;
            box.append (hr);


            headerbar.set_show_start_title_buttons (true);
            headerbar.set_show_end_title_buttons (true);
            transient_for = ThiefApp.get_instance ();
            vbox.append (headerbar);
            vbox.append (box);
            set_child (vbox);

            close_request.connect (() => false);
        }
   }
}