/*
 * Copyright (C) 2021 kmwallio
 * 
 * Modified March 20, 2021
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
using ThiefMD.Widgets;
using ThiefMD.Controllers;

namespace ThiefMD.Widgets {
    public class Notes : Gtk.Box {
        public Gtk.Stack notes_stack;
        private Sheets? current_project;
        private Sheet? current_sheet;
        private Gtk.TextBuffer file_notes_buffer;
        private Gtk.TextBuffer project_notes_buffer;

        public Notes () {
            this.orientation = Gtk.Orientation.VERTICAL;
            build_ui ();
        }

        private void build_ui () {
            var notes_grid = build_notes_grid ();
            add (notes_grid);
        }

        public static int get_notes_width () {
            var settings = AppSettings.get_default ();

            return settings.view_library_width + settings.view_sheets_width - 30;
        }

        private Gtk.Widget build_notes_grid () {
            var settings = AppSettings.get_default ();

            Gtk.ScrolledWindow s_win = new Gtk.ScrolledWindow (null, null);
            Gtk.Grid notes_grid = new Gtk.Grid ();
            notes_grid.margin = 12;
            notes_grid.row_spacing = 12;
            notes_grid.column_spacing = 12;
            notes_grid.orientation = Gtk.Orientation.VERTICAL;

            var file_notes_label = new Gtk.Label ("<b>" + _("Sheet Notes") + "</b>");
            file_notes_label.xalign = 0;
            file_notes_label.use_markup = true;
            file_notes_buffer = new Gtk.TextBuffer (null);
            var file_notes_view = new Gtk.TextView.with_buffer (file_notes_buffer);
            file_notes_view.width_request = settings.view_library_width + settings.view_sheets_width - 30;
            file_notes_view.height_request = (settings.view_library_width + settings.view_sheets_width) / 2;
            file_notes_view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
            var project_notes_label = new Gtk.Label ("<b>" + _("Project Notes") + "</b>");
            project_notes_label.xalign = 0;
            project_notes_label.use_markup = true;
            project_notes_buffer = new Gtk.TextBuffer (null);
            var project_notes_view = new Gtk.TextView.with_buffer (project_notes_buffer);
            project_notes_view.width_request = settings.view_library_width + settings.view_sheets_width - 30;
            project_notes_view.height_request = (settings.view_library_width + settings.view_sheets_width) / 2;
            project_notes_view.wrap_mode = Gtk.WrapMode.WORD_CHAR;

            int h = 0;
            notes_grid.attach (file_notes_label, 0, h, 1, 1);
            h += 1;
            notes_grid.attach (file_notes_view, 0, h, 1, 4);
            h += 4;
            notes_grid.attach (project_notes_label, 0, h, 1, 1);
            h += 1;
            notes_grid.attach (project_notes_view, 0, h, 1, 4);
            h += 4;

            settings.sheet_changed.connect (load_notes);
            load_notes ();
            s_win.add (notes_grid);
            s_win.width_request = settings.view_library_width + settings.view_sheets_width;
            s_win.vexpand = true;

            return s_win;
        }

        public void save_notes () {
            if (current_project != null) {
                current_project.metadata.notes = string_or_empty_string (project_notes_buffer.text);
                current_project.save_notes ();
            }

            if (current_sheet != null) {
                current_sheet.metadata.notes = string_or_empty_string (file_notes_buffer.text);
                current_sheet.save_notes ();
            }
        }

        private void load_notes () {
            Sheets? next_project = SheetManager.get_sheets ();
            Sheet? next_sheet = SheetManager.get_sheet ();
            save_notes ();
            if (next_project != current_project) {
                if (next_project == null) {
                    project_notes_buffer.text = "";
                } else {
                    if (next_project.metadata.notes != null) {
                        project_notes_buffer.text = string_or_empty_string (next_project.metadata.notes);
                    } else {
                        project_notes_buffer.text = "";
                    }
                }
            }
            current_project = next_project;

            if (next_sheet != current_sheet) {
                if (next_sheet == null) {
                    file_notes_buffer.text = "";
                } else {
                    file_notes_buffer.text = string_or_empty_string(next_sheet.metadata.notes);
                }
            }
            current_sheet = next_sheet;
        }
    }
}