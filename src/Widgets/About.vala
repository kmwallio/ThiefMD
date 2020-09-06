/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified September 2, 2020
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
using Gtk;
using Gdk;

namespace ThiefMD.Widgets {
    public class About : Dialog {
        private Gtk.Stack stack;

        public About () {
            set_transient_for (ThiefApp.get_instance ().main_window);
            parent = ThiefApp.get_instance ().main_window;
            set_destroy_with_parent (true);
            resizable = false;
            deletable = false;
            modal = true;
            build_ui ();
        }

        private void build_ui () {
            this.set_border_width (20);
            title = _("About ThiefMD");
            window_position = WindowPosition.CENTER;
            set_size_request (450, 350);

            stack = new Stack ();
            stack.add_titled (about_grid (), "about", _("About"));
            var credits_view = new Gtk.ScrolledWindow (null, null);
            credits_view.add (credits_grid ());
            stack.add_titled (credits_view, "credits", _("Credits"));

            StackSwitcher switcher = new StackSwitcher ();
            switcher.set_stack (stack);
            switcher.halign = Align.CENTER;

            Box box = new Box (Orientation.VERTICAL, 0);

            box.add (switcher);
            box.add (stack);
            this.get_content_area().add (box);

            add_button (_("Thanks"), Gtk.ResponseType.CLOSE);
            response.connect (() =>
            {
                destroy ();
            });

            show_all ();
        }

        private Grid about_grid () {
            Grid grid = new Grid ();
            grid.margin = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.orientation = Orientation.VERTICAL;

            IconTheme icon_theme = IconTheme.get_default();
            var pixbuf_icon = icon_theme.load_icon("com.github.kmwallio.thiefmd", 128, IconLookupFlags.FORCE_SVG);
            Image thief_icon = new Image.from_pixbuf(pixbuf_icon);
            thief_icon.hexpand = true;

            var thief_header = new Label (_("<b>ThiefMD</b>\n"));
            thief_header.use_markup = true;
            thief_header.hexpand = true;

            var thief_desc = new Label (_("The <a href='https://daringfireball.net/projects/markdown'>Markdown</a> editor worth stealing.\n"));
            thief_desc.use_markup = true;
            thief_desc.hexpand = true;

            var about_url = new Label (_("<a href='https://thiefmd.com'>https://thiefmd.com</a>\n"));
            about_url.use_markup = true;
            about_url.hexpand = true;

            var disclosure = new Label (_("<small>This program comes with absolutely no warranty.</small>"));
            disclosure.use_markup = true;
            disclosure.hexpand = true;

            grid.add (thief_icon);
            grid.add (thief_header);
            grid.add (thief_desc);
            grid.add (about_url);
            grid.add (disclosure);
            grid.show_all ();

            return grid;
        }

        private Grid credits_grid () {
            Grid grid = new Grid ();
            grid.margin = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.orientation = Orientation.VERTICAL;
            grid.hexpand = true;

            var quilter_credits = new Label (_("<b>Original Code:</b>\nBased on <a href='https://github.com/lainsce/quilter'>Quilter</a>.\nCopyright © 2017 Lains.\n<a href='https://github.com/lainsce/quilter/blob/master/LICENSE'>GNU General Public License v3.0</a>.\n"));
            quilter_credits.use_markup = true;
            quilter_credits.hexpand = true;
            quilter_credits.set_justify (Gtk.Justification.CENTER);

            var font_credits = new Label (_("<b>Font:</b>\n<a href='https://github.com/iaolo/iA-Fonts'>iA Writer Duospace</a>.\nCopyright © 2018 Information Architects Inc.\nwith Reserved Font Name \"iA Writer\"\n<a href='https://github.com/iaolo/iA-Fonts/blob/master/iA%20Writer%20Duospace/LICENSE.md'>SIL OPEN FONT LICENSE Version 1.1</a>.\n"));
            font_credits.use_markup = true;
            font_credits.hexpand = true;
            font_credits.set_justify (Gtk.Justification.CENTER);

            var css_credits = new Label (_("<b>Preview CSS:</b>\n<a href='https://github.com/markdowncss'>Mash up of Splendor and Modest</a>.\nCopyright © 2014-2015 John Otander.\n<a href='https://github.com/markdowncss/splendor/blob/master/LICENSE'>The MIT License (MIT)</a>.\n"));
            css_credits.use_markup = true;
            css_credits.hexpand = true;
            css_credits.set_justify (Gtk.Justification.CENTER);

            var markdown_credits = new Label (_("<b>Markdown Parsing:</b>\n<a href='http://www.pell.portland.or.us/~orc/Code/discount/'>libmarkdown2</a>.\nCopyright © 2007 David Loren Parsons.\n<a href='http://www.pell.portland.or.us/~orc/Code/discount/COPYRIGHT.html'>BSD-style License</a>.\n"));
            markdown_credits.use_markup = true;
            markdown_credits.hexpand = true;
            markdown_credits.set_justify (Gtk.Justification.CENTER);

            var highlight_credits = new Label (_("<b>Syntax Highlighting:</b>\n<a href='https://highlightjs.org/'>highlight.js</a>.\nCopyright © 2006 Ivan Sagalaev.\n<a href='https://github.com/highlightjs/highlight.js/blob/master/LICENSE'>BSD-3-Clause License</a>.\n"));
            highlight_credits.use_markup = true;
            highlight_credits.hexpand = true;
            highlight_credits.set_justify (Gtk.Justification.CENTER);

            var katex_credits = new Label (_("<b>KaTeX:</b>\n<a href='https://katex.org/)'>KaTeX</a>.\n2013-2020 Khan Academy and other contributors.\n<a href='https://github.com/KaTeX/KaTeX/blob/master/LICENSE'>MIT License</a>.\n"));
            katex_credits.use_markup = true;
            katex_credits.hexpand = true;
            katex_credits.set_justify (Gtk.Justification.CENTER);

            grid.add (quilter_credits);
            grid.add (font_credits);
            grid.add (css_credits);
            grid.add (markdown_credits);
            grid.add (highlight_credits);
            grid.add (katex_credits);
            grid.show_all ();

            return grid;
        }
    }
}