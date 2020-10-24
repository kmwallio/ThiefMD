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
    public class ThiefProperties {
        public const string NAME = "ThiefMD";
        public const string URL = "https://thiefmd.com";
        public const string COPYRIGHT = "Copyright © 2020 kmwallio";
        public const string TAGLINE = "The Markdown editor worth stealing";
        public const string THIEF_MARK_CONST = "THIEFMDa63471e6ec1b4f35b7ca635f3ca39a85";
        public const string THIEF_MARK = "<span id='thiefmark'></span>";
        public const string VERSION = Build.VERSION;
        public const Gtk.License LICENSE_TYPE = Gtk.License.GPL_3_0;
        public const string[] GIANTS = {
            "<a href='https://github.com/kmwallio/ThiefMD/graphs/contributors'>Contributors who help make ThiefMD awesome</a>\n",
            "Original Code:\nBased on <a href='https://github.com/lainsce/quilter'>Quilter</a>\nCopyright © 2017 Lains.\n<a href='https://github.com/lainsce/quilter/blob/master/LICENSE'>GNU General Public License v3.0</a>\n",
            "Font:\n<a href='https://github.com/iaolo/iA-Fonts'>iA Writer Duospace</a>\nCopyright © 2018 Information Architects Inc.\nwith Reserved Font Name \"iA Writer\"\n<a href='https://github.com/iaolo/iA-Fonts/blob/master/iA%20Writer%20Duospace/LICENSE.md'>SIL OPEN FONT LICENSE Version 1.1</a>\n",
            "Font:\n<a href='https://quoteunquoteapps.com/courierprime'>Courier Prime</a>\nCopyright © 2013 Quote-Unquote Apps\n<a href='https://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&amp;id=OFL'>SIL OPEN FONT LICENSE Version 1.1</a>\n",
            "Preview CSS:\n<a href='https://github.com/markdowncss'>Mash up of Splendor and Modest</a>\nCopyright © 2014-2015 John Otander.\n<a href='https://github.com/markdowncss/splendor/blob/master/LICENSE'>The MIT License (MIT)</a>\n",
            "Markdown Parsing:\n<a href='http://www.pell.portland.or.us/~orc/Code/discount/'>libmarkdown2</a>\nCopyright © 2007 David Loren Parsons.\n<a href='http://www.pell.portland.or.us/~orc/Code/discount/COPYRIGHT.html'>BSD-style License</a>\n",
            "Syntax Highlighting:\n<a href='https://highlightjs.org/'>highlight.js</a>\nCopyright © 2006 Ivan Sagalaev.\n<a href='https://github.com/highlightjs/highlight.js/blob/master/LICENSE'>BSD-3-Clause License</a>\n",
            "Math Rendering:\n<a href='https://katex.org/'>KaTeX</a>\nCopyright © 2013-2020 Khan Academy and other contributors.\n<a href='https://github.com/KaTeX/KaTeX/blob/master/LICENSE'>MIT License</a>\n",
            "XML Parsing:\n<a href='http://xmlsoft.org/'>libxml2</a>\nCopyright © 1998-2012 Daniel Veillard.\n<a href='https://gitlab.gnome.org/GNOME/libxml2/-/blob/master/Copyright'>MIT License</a>\n",
            "Pandoc Export:\n<a href='https://pandoc.org/'>Pandoc</a>\nCopyright © 2006-2020 John MacFarlane and others\n<a href='https://github.com/jgm/pandoc/blob/master/COPYRIGHT'>GNU General Public License v2.0</a>\n",
            "libwritegood-vala based on:\n<a href='https://github.com/btford/write-good'>write-good: Naive linter for English prose</a>\nCopyright © 2014-2019 Brian Ford\n<a href='https://github.com/btford/write-good/blob/master/LICENSE'>The MIT License (MIT)</a>\n",
          };

        public const string[] PAPER_SIZES_FRIENDLY_NAME = {
          "A3 (11.7 x 16.5 inches)",
          "A4 (8 x 11 inches)",
          "A5 (5.8 x 8.3 inches)",
          "B5 (6.93 x 9.84 inches)",
          "Executive (7 x 10 inches)",
          "Legal (8.5 x 14 inches)",
          "Letter (8.5 x 11 inches)"
        };

        public const string[] PAPER_SIZES_GTK_NAME = {
          Gtk.PAPER_NAME_A3,
          Gtk.PAPER_NAME_A4,
          Gtk.PAPER_NAME_A5,
          Gtk.PAPER_NAME_B5,
          Gtk.PAPER_NAME_EXECUTIVE,
          Gtk.PAPER_NAME_LEGAL,
          Gtk.PAPER_NAME_LETTER
        };

        public const string[] THIEF_TIPS = {
          "Don't like what you see? Hit `Ctrl+,` to access the preferences.",
          "No built in dark mode? Dark themes are available at https://themes.thiefmd.com. Add more in the Preferences (`Ctrl+,`).",
          "Don't like the preview? Hit `Ctrl+,` to access the preferences and click Export.",
          "Want to import a ePub, HTML, or DocX? Add a folder to the library, then drag the file onto the folder.",
          "Ready to publish your great work? Right-click on the folder and choose \"Export Preview\"",
          "Want to block out the world? Full-screen is just an `F11` away.",
          "Quickly switch view modes with `Ctrl+1`, `Ctrl+2`, and `Ctrl+3`."
        };

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

        public const string DYNAMIC_CSS = """@define-color colorPrimary %s;
        @define-color colorPrimaryActive %s;
        @define-color textColorPrimary %s;
        @define-color textColorActive %s;
        @define-color textColorGlobal %s;
        
        .thief-toolbar, .thiefmd-toolbar, .thief-search-box {
            border-bottom-color: transparent;
            border-bottom-width: 1px;
            background: @colorPrimary;
            color: @textColorGlobal;
            box-shadow: 0 1px transparent inset;
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
        
        placessidebar, treeview {
            background: lighter(@colorPrimaryActive);
            color: @textColorGlobal;
        }
        
        treeview.view header button {
            background: @colorPrimary;
            color: @textColorGlobal;
        }
        
        placessidebar *:selected, treeview.view:selected {
            background: lighter(@colorPrimary);
            color: @textColorGlobal;
        }""";

        public const string NO_CSS_CSS = """
        @media print {
          tr,
          img {
            page-break-inside: avoid;
            max-width: 100%;
          }

          img {
            max-width: 100% !important;
          }
        }

        img {
          max-width: 100%;
        }
        """;

        public const string PRINT_CSS = """@media print {
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
              content: "";
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
          }

          img {
            max-width: 100%;
          }""";
    }
}
