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
        private Regex? url_regex = null;
        // Holds the URL under the last right-click so the menu action can open it
        private string? active_link_url = null;
        // GLib source IDs for pending re-tag idle callbacks (0 = none queued)
        private uint file_tag_source = 0;
        private uint project_tag_source = 0;

        public Notes () {
            this.orientation = Gtk.Orientation.VERTICAL;
            try {
                // Match http/https/ftp URLs in plain text.
                // The last character class excludes common trailing punctuation
                // so "See https://example.com." does not highlight the period.
                url_regex = new Regex ("(https?|ftp)://[^\\s]*[^\\s.,;:!?)\\]'\">]",
                                       RegexCompileFlags.CASELESS, 0);
            } catch (Error e) {
                warning ("Could not compile URL regex: %s", e.message);
            }
            build_ui ();
        }

        private void build_ui () {
            var notes_grid = build_notes_grid ();
            append (notes_grid);
        }

        public static int get_notes_width () {
            var settings = AppSettings.get_default ();

            return settings.view_library_width + settings.view_sheets_width - 30;
        }

        private Gtk.Widget build_notes_grid () {
            var settings = AppSettings.get_default ();

            Gtk.ScrolledWindow s_win = new Gtk.ScrolledWindow ();
            Gtk.Grid notes_grid = new Gtk.Grid ();
            notes_grid.margin_top = 12;
            notes_grid.margin_bottom = 12;
            notes_grid.margin_start = 12;
            notes_grid.margin_end = 12;
            notes_grid.row_spacing = 12;
            notes_grid.column_spacing = 12;

            var file_notes_label = new Gtk.Label ("<b>" + _("Sheet Notes") + "</b>");
            file_notes_label.xalign = 0;
            file_notes_label.use_markup = true;
            file_notes_buffer = new Gtk.TextBuffer (null);
            var file_url_tag = make_url_tag (file_notes_buffer);
            var file_notes_view = new Gtk.TextView.with_buffer (file_notes_buffer);
            file_notes_view.width_request = settings.view_library_width + settings.view_sheets_width - 30;
            file_notes_view.height_request = (settings.view_library_width + settings.view_sheets_width) / 2;
            file_notes_view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
            var project_notes_label = new Gtk.Label ("<b>" + _("Project Notes") + "</b>");
            project_notes_label.xalign = 0;
            project_notes_label.use_markup = true;
            project_notes_buffer = new Gtk.TextBuffer (null);
            var project_url_tag = make_url_tag (project_notes_buffer);
            var project_notes_view = new Gtk.TextView.with_buffer (project_notes_buffer);
            project_notes_view.width_request = settings.view_library_width + settings.view_sheets_width - 30;
            project_notes_view.height_request = (settings.view_library_width + settings.view_sheets_width) / 2;
            project_notes_view.wrap_mode = Gtk.WrapMode.WORD_CHAR;

            // Re-tag URLs whenever the user edits the notes.
            // Cancel any already-queued idle so we only ever have one pending at a time.
            file_notes_buffer.changed.connect (() => {
                if (file_tag_source != 0) {
                    GLib.Source.remove (file_tag_source);
                }
                file_tag_source = GLib.Idle.add (() => {
                    tag_urls (file_notes_buffer, file_url_tag);
                    file_tag_source = 0;
                    return false;
                });
            });
            project_notes_buffer.changed.connect (() => {
                if (project_tag_source != 0) {
                    GLib.Source.remove (project_tag_source);
                }
                project_tag_source = GLib.Idle.add (() => {
                    tag_urls (project_notes_buffer, project_url_tag);
                    project_tag_source = 0;
                    return false;
                });
            });

            // Wire up Ctrl+Click and right-click "Open Link" for each view
            setup_link_features (file_notes_view, file_notes_buffer, file_url_tag);
            setup_link_features (project_notes_view, project_notes_buffer, project_url_tag);

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
            s_win.set_child (notes_grid);
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

        // Create a text tag styled as a clickable link (blue + underline)
        private Gtk.TextTag make_url_tag (Gtk.TextBuffer buffer) {
            var tag = buffer.create_tag ("notes-url");
            tag.underline = Pango.Underline.SINGLE;
            tag.foreground = "#3584e4";
            tag.foreground_set = true;
            return tag;
        }

        // Scan the buffer and paint any URLs with the link tag
        private void tag_urls (Gtk.TextBuffer buffer, Gtk.TextTag url_tag) {
            if (url_regex == null) {
                return;
            }

            Gtk.TextIter buf_start, buf_end;
            buffer.get_bounds (out buf_start, out buf_end);
            // Wipe any old URL highlights before re-applying
            buffer.remove_tag (url_tag, buf_start, buf_end);

            string text = buffer.get_text (buf_start, buf_end, false);
            MatchInfo match_info;
            try {
                if (url_regex.match (text, 0, out match_info)) {
                    do {
                        int start_byte, end_byte;
                        if (match_info.fetch_pos (0, out start_byte, out end_byte)) {
                            // Convert byte offsets to character offsets for multibyte safety
                            int start_char = text.char_count (start_byte);
                            int end_char   = text.char_count (end_byte);
                            Gtk.TextIter tag_start, tag_end;
                            buffer.get_iter_at_offset (out tag_start, start_char);
                            buffer.get_iter_at_offset (out tag_end, end_char);
                            buffer.apply_tag (url_tag, tag_start, tag_end);
                        }
                    } while (match_info.next ());
                }
            } catch (Error e) {
                warning ("URL tag matching failed: %s", e.message);
            }
        }

        // Return the URL string under pixel position (x, y) inside the view, or null
        private string? get_url_at_xy (Gtk.TextView view, Gtk.TextBuffer buffer,
                                       Gtk.TextTag url_tag, double x, double y) {
            int buffer_x, buffer_y;
            view.window_to_buffer_coords (Gtk.TextWindowType.WIDGET, (int)x, (int)y,
                                          out buffer_x, out buffer_y);
            Gtk.TextIter iter;
            view.get_iter_at_location (out iter, buffer_x, buffer_y);

            if (!iter.has_tag (url_tag)) {
                return null;
            }

            // Walk to the start and end of the tagged run
            var tag_start = iter.copy ();
            if (!tag_start.starts_tag (url_tag)) {
                tag_start.backward_to_tag_toggle (url_tag);
            }
            var tag_end = iter.copy ();
            if (!tag_end.ends_tag (url_tag)) {
                tag_end.forward_to_tag_toggle (url_tag);
            }

            return buffer.get_text (tag_start, tag_end, false);
        }

        // Open a URL with the system default browser/handler
        private void open_url (string url) {
            try {
                AppInfo.launch_default_for_uri (url, null);
            } catch (Error e) {
                warning ("Could not open URL %s: %s", url, e.message);
            }
        }

        // Attach Ctrl+Click and right-click "Open Link" behaviour to a notes TextView
        private void setup_link_features (Gtk.TextView view, Gtk.TextBuffer buffer,
                                          Gtk.TextTag url_tag) {
            // Build the action that will be triggered by the right-click menu
            var actions = new GLib.SimpleActionGroup ();
            var open_action = new GLib.SimpleAction ("open-link", null);
            open_action.set_enabled (false);
            open_action.activate.connect (() => {
                if (active_link_url != null) {
                    open_url (active_link_url);
                }
            });
            actions.add_action (open_action);
            view.insert_action_group ("notes", actions);

            // Add "Open Link" to the TextView's built-in right-click menu
            var link_menu = new GLib.Menu ();
            link_menu.append (_("Open Link"), "notes.open-link");
            view.set_extra_menu (link_menu);

            // Capture right-clicks before the default menu appears so we can
            // record which URL (if any) is under the pointer and enable/disable
            // the menu item accordingly
            var right_click = new Gtk.GestureClick ();
            right_click.set_button (3);
            right_click.set_propagation_phase (Gtk.PropagationPhase.CAPTURE);
            right_click.pressed.connect ((n_press, x, y) => {
                active_link_url = get_url_at_xy (view, buffer, url_tag, x, y);
                open_action.set_enabled (active_link_url != null);
            });
            view.add_controller (right_click);

            // Ctrl+Click opens the link directly without a menu
            var left_click = new Gtk.GestureClick ();
            left_click.set_button (1);
            left_click.released.connect ((n_press, x, y) => {
                var event = left_click.get_current_event ();
                if (event == null) {
                    return;
                }
                var state = event.get_modifier_state ();
                if ((state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    string? url = get_url_at_xy (view, buffer, url_tag, x, y);
                    if (url != null) {
                        open_url (url);
                    }
                }
            });
            view.add_controller (left_click);
        }
    }
}