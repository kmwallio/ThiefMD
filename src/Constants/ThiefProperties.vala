/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified September 6, 2020
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

namespace ThiefMD {
    public class ThiefProperties : Object {
        public const string NAME = "ThiefMD";
        public const string URL = "https://thiefmd.com";
        public const string COPYRIGHT = "Copyright © 2020-2022 kmwallio";
        public const string TAGLINE = _("The Markdown editor worth stealing");
        public const string THIEF_MARK_CONST = "THIEFMDa63471e6ec1b4f35b7ca635f3ca39a85";
        public const string THIEF_MARK = "<span id='thiefmark'></span>";
        public const string SUPPORTED_IMPORT_FILES = "*.docx;*.odt;*.html;*.tex;*.epub;*.textile;*.html;*.fb2;*.dbk;*.xml;*.opml;*.rst;*.md;*.markdown;*.fountain;*.fou;*.spmd;*.textpack;*.highland;*.fdx;*.bear2bk";
        public const string SUPPORTED_OPEN_FILES = "*.md;*.markdown;*.fountain;*.fou;*.spmd";
        public const string VERSION = Build.VERSION;
        public const Gtk.License LICENSE_TYPE = Gtk.License.GPL_3_0;

        public static Gee.List<string> GIANTS {
          get {
            if (instance == null) {
              instance = new ThiefProperties ();
            }
            return instance.giants;
          }
        }
        private Gee.LinkedList<string> giants;

        public static Gee.List<string> PAPER_SIZES_FRIENDLY_NAME {
          get {
            if (instance == null) {
              instance = new ThiefProperties ();
            }
            return instance.friendly_paper;
          }
        }
        private Gee.ArrayList<string> friendly_paper;

        public static Gee.List<string> THIEF_TIPS {
          get {
            if (instance == null) {
              instance = new ThiefProperties ();
            }
            return instance.thief_tips;
          }
        }
        private Gee.ArrayList<string> thief_tips;

        public const string[] PAPER_SIZES_GTK_NAME = {
          Gtk.PAPER_NAME_A3,
          Gtk.PAPER_NAME_A4,
          Gtk.PAPER_NAME_A5,
          Gtk.PAPER_NAME_B5,
          Gtk.PAPER_NAME_EXECUTIVE,
          Gtk.PAPER_NAME_LEGAL,
          Gtk.PAPER_NAME_LETTER
        };

        public const string [] PAPER_SIZES_CSS_NAME = {
          "A3",
          "A4",
          "A5",
          "B5",
          "Executive",
          "Legal",
          "Letter"
        };

        private static ThiefProperties instance;
        public ThiefProperties () {
          if (instance == null) {
            giants = new Gee.LinkedList<string> ();
            giants.add ("<a href='https://github.com/kmwallio/ThiefMD/graphs/contributors'>" + _("Contributors who help make ThiefMD awesome") + "</a>\n");
            giants.add (_("Czech Translation Contributors") + ":\n<a href='https://github.com/pervoj'>Vojtěch Perník</a>\n");
            giants.add (_("French Translation Contributors") + ":\n<a href='https://github.com/davidbosman'>David Bosman</a>\n");
            giants.add (_("Slovak Translation Contributors") + ":\n<a href='https://github.com/marek-lach'>Marek L'ach</a>\n");
            giants.add (_("Swedish Translation Contributors") + ":\n<a href='https://github.com/eson57'>Åke Engelbrektson</a>\n");
            giants.add (_("German Translation Contributors") + ":\nHelix and Fish\n");
            giants.add (_("Finnish Translation Contributors") + ":\nJiri Grönroos\n");
            giants.add (_("Polish Translation Contributors") + ":\nŁukasz Horodecki\n");
            giants.add (_("Turkish Translation Contributors") + ":\nSabri Ünal\n");
            giants.add (_("Original Code") + ":\n" + _("Based on <a href='https://github.com/lainsce/quilter'>Quilter</a>") + "\n" + _("Copyright") + " © 2017 Lains.\n<a href='https://github.com/lainsce/quilter/blob/master/LICENSE'>" + _("GNU General Public License v3.0") + "</a>" + "\n");
            giants.add (_("Stolen Victory Font") + ":\nModified <a href='https://github.com/iaolo/iA-Fonts'>iA Writer Duospace</a>\n" + _("Copyright") + " © 2018 Information Architects Inc.\nwith Reserved Font Name \"iA Writer\"\n<a href='https://github.com/iaolo/iA-Fonts/blob/master/iA%20Writer%20Duospace/LICENSE.md'>" + _("SIL OPEN FONT LICENSE Version 1.1") + "</a>");
            giants.add ("Modified <a href='https://rubjo.github.io/victor-mono/'>Victor Mono</a>\n" + _("Copyright") + " © 2019 Rune Bjørnerås\n<a href='https://github.com/rubjo/victor-mono/blob/master/LICENSE'>" + _("MIT License") + "</a>");
            giants.add ("Modified <a href='https://github.com/IBM/plex'>IBM Plex Sans</a>\n" + _("Copyright") + " © 2017 IBM Corp.\nwith Reserved Font Name \"Plex\"\n<a href='https://github.com/IBM/plex/blob/master/LICENSE.txt'>" + _("SIL OPEN FONT LICENSE Version 1.1") + "</a>\n");
            giants.add (_("Font") + ":\n<a href='https://github.com/iaolo/iA-Fonts'>iA Writer Duospace</a>\n" + _("Copyright") + " © 2018 Information Architects Inc.\nwith Reserved Font Name \"iA Writer\"\n<a href='https://github.com/iaolo/iA-Fonts/blob/master/iA%20Writer%20Duospace/LICENSE.md'>" + _("SIL OPEN FONT LICENSE Version 1.1") + "</a>\n");
            giants.add (_("Font") + ":\n<a href='https://quoteunquoteapps.com/courierprime'>Courier Prime</a>\n" + _("Copyright") + " © 2013 Quote-Unquote Apps\n<a href='https://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&amp;id=OFL'>" + _("SIL OPEN FONT LICENSE Version 1.1") + "</a>\n");
            giants.add (_("Preview CSS") + ":\n<a href='https://github.com/markdowncss'>" + _("Mash up of Splendor and Modest") + "</a>\n" + _("Copyright") + " © 2014-2015 John Otander.\n<a href='https://github.com/markdowncss/splendor/blob/master/LICENSE'>" + _("The MIT License (MIT)") + "</a>\n");
            giants.add (_("Fountain Preview and Export") + ":\n<a href='https://github.com/thombruce/fountain.js/'>fountain.js</a>\n" + _("Copyright") + " © 2020 Thom Bruce.\n<a href='https://github.com/thombruce/fountain.js/blob/master/LICENSE'>" + _("MIT License") + "</a>\n");
            giants.add (_("Markdown Parsing") + ":\n<a href='http://www.pell.portland.or.us/~orc/Code/discount/'>libmarkdown (Discount)</a>\n" + _("Copyright") + " © 2007 David Loren Parsons.\n<a href='http://www.pell.portland.or.us/~orc/Code/discount/COPYRIGHT.html'>" + _("BSD-style License") + "</a>\n");
            giants.add (_("Syntax Highlighting") + ":\n<a href='https://highlightjs.org/'>highlight.js</a>\n" + _("Copyright") + " © 2006 Ivan Sagalaev.\n<a href='https://github.com/highlightjs/highlight.js/blob/master/LICENSE'>" + _("BSD-3-Clause License") + "</a>\n");
            giants.add (_("Math Rendering") + ":\n<a href='https://katex.org/'>KaTeX</a>\n" + _("Copyright") + " © 2013-2020 " + _("Khan Academy and other contributors.") + "\n<a href='https://github.com/KaTeX/KaTeX/blob/master/LICENSE'>" + _("MIT License") + "</a>\n");
            giants.add (_("XML Parsing") + ":\n<a href='http://xmlsoft.org/'>libxml2</a>\n" + _("Copyright") + " © 1998-2012 Daniel Veillard.\n<a href='https://gitlab.gnome.org/GNOME/libxml2/-/blob/master/Copyright'>" + _("MIT License") + "</a>\n");
            giants.add (_("Pandoc Export") + ":\n<a href='https://pandoc.org/'>Pandoc</a>\n" + _("Copyright") + " © 2006-2020 " + _("John MacFarlane and others") + "\n<a href='https://github.com/jgm/pandoc/blob/master/COPYRIGHT'>" + _("GNU General Public License v2.0") + "</a>\n");
            giants.add (_("PDF Export") + ":\n<a href='https://weasyprint.org/'>weasyprint</a>\n" + _("Copyright") + " © 2011-2021 " + _("Simon Sapin and contributors") + "\n<a href='https://github.com/Kozea/WeasyPrint/blob/master/LICENSE'>" + _("BSD-3-Clause License") + "</a>\n");
            giants.add (_("Grammar Check") + ":\n<a href='https://www.abisource.com/projects/link-grammar/'>Link Grammar Parser</a>\n" + _("Copyright") + " © 1998-2017 " + _("the AbiSource Community") + "\n<a href='https://github.com/opencog/link-grammar/blob/master/LICENSE'>" + _("GNU Lesser General Public License v2.1") + "</a>\n");
            giants.add (_("libwritegood-vala based on") + ":\n<a href='https://github.com/btford/write-good'>" + _("write-good: Naive linter for English prose") + "</a>\n" + _("Copyright") + " © 2014-2019 Brian Ford\n<a href='https://github.com/btford/write-good/blob/master/LICENSE'>" + _("The MIT License (MIT)") + "</a>\n");

            // Needs to be kept in sync with PAPER_SIZES_GTK_NAME
            friendly_paper = new Gee.ArrayList<string>();
            friendly_paper.add (_("A3 (11.7 x 16.5 inches)"));
            friendly_paper.add (_("A4 (8 x 11 inches)"));
            friendly_paper.add (_("A5 (5.8 x 8.3 inches)"));
            friendly_paper.add (_("B5 (6.93 x 9.84 inches)"));
            friendly_paper.add (_("Executive (7 x 10 inches)"));
            friendly_paper.add (_("Legal (8.5 x 14 inches)"));
            friendly_paper.add (_("Letter (8.5 x 11 inches)"));

            thief_tips = new Gee.ArrayList<string> ();
            thief_tips.add (_("Don't like what you see? Hit `Ctrl+,` to access the preferences."));
            thief_tips.add (_("No built in dark mode? Dark themes are available at https://themes.thiefmd.com. Add more in the Preferences (`Ctrl+,`)."));
            thief_tips.add (_("Don't like how the preview looks? Hit `Ctrl+,` to access the preferences and click Export."));
            thief_tips.add (_("Want to import a ePub, HTML, or DocX? Click Import from the New Sheet prompt."));
            thief_tips.add (_("Ready to publish your great work? Right-click on the folder and choose \"Export Preview\""));
            thief_tips.add (_("Want to block out distractions? Full-screen is just an `F11` away."));
            thief_tips.add (_("Quickly switch view modes with `Ctrl+1`, `Ctrl+2`, and `Ctrl+3`."));
            thief_tips.add (_("Working with a lot of links? Turn on Experimental Mode to make your markdown more readable `Ctrl+Shift+M`."));

            instance = this;
          }
        }

        public const string PREVIEW_TEXT = """# %s
The `markdown` editor worth stealing. *Focus* more on **writing**.
> It's the best thing since sliced bread
[ThiefMD](https://thiefmd.com)
""";

        public const string PREVIEW_CSS_MARKDOWN = """# %s
The `markdown` editor worth stealing. *Focus* more on **writing**.
## Users Say:
> It's the best thing since sliced bread
[ThiefMD](https://thiefmd.com)
""";

        public const string FONT_SETTINGS = """
      .undershoot.top, .undershoot.right, .undershoot.bottom, .undershoot.left {
          background-image: none;
          border: 0;
      }
      
      .undershoot, .undershoottop, .undershootright, .undershootbottom, .undershootleft {
          background-image: none;
          border: 0;
      }
      
      .small-text {
          %s;
          font-size: %dpt;
      }
      
      .focus-text {
          %s;
          font-size: %dpt;
      }
      
      .full-text {
          %s;
          font-size: %dpt;
      }""";

        public const string BUTTON_CSS = """@define-color borderColor %s;
        .thief-drop-above {
            margin-bottom: 1.5rem;
        }

        .thief-drop-below {
            margin-top: 1.5rem;
        }

        .thief-list-sheet {
            border-bottom: 1px solid alpha(@borderColor, 0.22);
            border-radius: 0;
        }
        
        .thief-list-sheet-active,
        .thief-search-input,
        .thief-search-results *:hover,
        .thief-search-results *:active,
        .thief-search-results *:hover:active {
          border-bottom: 1px solid alpha(lighter(@borderColor), 0.22);
        }
        """;

        public const string DYNAMIC_CSS = """@define-color colorPrimary %s;
        @define-color colorPrimaryActive %s;
        @define-color textColorPrimary %s;
        @define-color textColorActive %s;
        @define-color textColorGlobal %s;
        
        .thief-toolbar, .thiefmd-toolbar, .thief-search-box {
            border-bottom-color: transparent;
            border-bottom-width: 1px;
            background: @colorPrimary;
            background-image: linear-gradient(lighter(@colorPrimary), @colorPrimary 3%%);
            color: @textColorGlobal;
            box-shadow: 0 1px transparent inset;
        }

        .thief-notes {
            background: @colorPrimary;
            color: @textColorPrimary;
        }

        .thief-drop-above {
            margin-bottom: 1.5rem;
        }

        .thief-drop-below {
            margin-top: 1.5rem;
        }

        .thief-sheets {
            border-right: 1px solid alpha(@textColorGlobal, 0.2);
        }

        .thiefmd-toolbar button,
        .thief-search-button,
        .thief-search-matches {
          background: @colorPrimary;
          color: @textColorGlobal;
        }

        .quickprefs togglebutton:checked,
        .quickprefs button.toggle:checked {
            background: lighter(@colorPrimary);
            color: @textColorPrimary;
            border-left: 3px solid @selectionColor;
        }

        .thiefmd-toolbar:backdrop, .thief-toolbar:backdrop, .thiefmd-toolbar:backdrop button {
          background-image: linear-gradient(lighter(@colorPrimary), @colorPrimary 50%%);
          color: mix(@textColorGlobal, @colorPrimary, 0.5);
        }

        .thiefmd-toolbar button:active,
        .thiefmd-toolbar button:hover,
        .thiefmd-toolbar button:hover:active,
        .thief-search-button:hover,
        .thief-search-button:active,
        .thief-search-button:hover:active {
          background: lighter(@colorPrimary);
          color: @textColorGlobal;
        }

        actionbar,
        .action-bar {
            border-top-color: transparent;
            background: @colorPrimary;
            color: @textColorPrimary;
            box-shadow: 0 1px transparent inset;
        }

        .thief-search-results {
          padding: 0;
          margin: 0;
        }

        .thief-search-results * {
          margin: 0px;
          padding: 0px;
        }

        .thief-list-sheet {
            background: @colorPrimary;
            border-bottom: 1px solid @textColorGlobal;
            color: @textColorGlobal;
            border-radius: 0;
        }
        
        .thief-list-sheet-active,
        .thief-search-input,
        .thief-search-results *:hover,
        .thief-search-results *:active,
        .thief-search-results *:hover:active {
            background: lighter(@colorPrimary);
            color: @textColorPrimary;
            border-bottom: 0px solid @textColorPrimary;
            border-top: 0px solid @textColorPrimary;
            border-left: 5px solid @textColorPrimary;
            border-right: 0px;
        }

        .thief-search-input:focus {
          background: @colorPrimaryActive;
          color: @textColorActive;
        }

        filechooser {
            background: @windowColor;
            color: @textColorGlobal;
        }
        
        filechooser actionbar, filechooser, filechooser stack, placessidebar, window {
            background: darker(@colorPrimary);
            color: @textColorPrimary;
        }

        placessidebar, treeview, .thief-library-header {
            background: lighter(@colorPrimaryActive);
            color: @textColorGlobal;
        }

        .thief-library-header button:active,
        .thief-library-header button:hover,
        .thief-library-header button:hover:active {
          background: lighter(lighter(@colorPrimaryActive));
          color: @textColorGlobal;
        }

        .library-drop-hover treeview row:selected,
        .library-drop-hover treeview row {
          background: lighter(lighter(@colorPrimaryActive));
          color: @textColorGlobal;
        }

        .library-drop-hover {
          background: alpha(@selectionColor, 0.2);
          border-left: 3px solid @selectionColor;
        }

        /* Match list view container background to the library header */
        listview,
        listview > overlay,
        listview > viewport,
        listview > stack,
        listview > revealer,
        listview > scrolledwindow,
        listview > scrollbar {
            background: lighter(@colorPrimaryActive);
        }

        /* Library list (Gtk.ListView) styling */
        listview row .library-row {
            background: lighter(@colorPrimaryActive);
            color: @textColorGlobal;
        }

        listview row:hover .library-row {
            background: lighter(@colorPrimary);
            color: @textColorPrimary;
        }

        listview row:selected .library-row,
        listview row:focus-within .library-row {
            background: lighter(@colorPrimary);
            color: @textColorGlobal;
        }

        treeview.view header button, .thief-library-header button {
            background: lighter(@colorPrimaryActive);
            color: @textColorGlobal;
        }

        placessidebar *:selected, treeview.view:selected {
            background: lighter(@colorPrimary);
            color: @textColorGlobal;
        }""";

        public const string NO_CSS_CSS = """
        @media print {
          tr,
          img,
          figure {
            page-break-inside: avoid;
            max-width: 100%;
          }

          img {
            max-width: 100% !important;
          }
        }

        img,
        figure {
          max-width: 100%;
        }
        """;

        public const string PRINT_CSS = """
            *,
            *:before,
            *:after {
              background: transparent !important;
              color: #000 !important;
              box-shadow: none !important;
              text-shadow: none !important;
            }

            a,
            a:visited {
              text-decoration: underline;
            }

            abbr[title]:after {
              content: " (" attr(title) ")";
            }

            a[href^="#"]:after,
            a[href^="javascript:"]:after {
              content: " (" attr(href) ")";
            }

            pre,
            blockquote {
              border: 1px solid #999;
              page-break-inside: avoid;
            }

            thead {
              display: table-header-group;
            }

            tr,
            img {
              page-break-inside: avoid;
              max-width: 100%;
            }

            img {
              max-width: 100% !important;
            }

            p,
            h2,
            h3 {
              orphans: 3;
              widows: 3;
            }

            h2,
            h3 {
              page-break-after: avoid;
            }

          img,
          figure {
            max-width: 100%;
          }""";
    }
}
