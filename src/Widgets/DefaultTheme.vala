/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified September 8, 2020
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
    public class DefaultTheme : Gtk.Button {
        private Gtk.SourceView view;
        private Gtk.SourceBuffer buffer;

        public DefaultTheme () {
            var manager = Gtk.SourceLanguageManager.get_default ();
            var language = manager.guess_language (null, "text/markdown");
            margin = 0;
            view = new Gtk.SourceView ();
            view.margin = 0;
            buffer = new Gtk.SourceBuffer.with_language (language);
            buffer.highlight_syntax = true;
            view.editable = false;
            view.set_buffer (buffer);
            view.set_wrap_mode (Gtk.WrapMode.NONE);
            buffer.text = ThiefProperties.PREVIEW_TEXT.printf(ThiefProperties.NAME);
            add (view);

            var style_manager = Gtk.SourceStyleSchemeManager.get_default ();
            var style = style_manager.get_scheme ("thiefmd");
            buffer.set_style_scheme (style);

            clicked.connect (() => {
                var settings = AppSettings.get_default ();
                ThiefApp.get_instance ().edit_view_content.set_scheme ("thiefmd");
                settings.theme_id = "thiefmd";
            });

            show_all ();
        }
    }
}