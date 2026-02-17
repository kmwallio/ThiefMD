/*
 * Copyright (C) 2026
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

using ThiefMD.Controllers;

namespace ThiefMD.Widgets {
    // Context menufunctionality for Editor - split out to avoid modifying existing code structure
    public class EditorContextMenu : Object {
        private unowned Editor editor;
        private GLib.SimpleActionGroup context_actions;
        private Gtk.GestureClick? menu_refresh_controller = null;

        public EditorContextMenu (Editor ed) {
            editor = ed;
            context_actions = new GLib.SimpleActionGroup ();
            editor.insert_action_group ("editor", context_actions);
            
            setup_actions ();
            setup_context_menu_signal ();
        }

        public void refresh_context_menu () {
            debug ("refresh_context_menu called");
            update_extra_menu ();
        }

        private void setup_actions () {
            var split_action = new GLib.SimpleAction ("split_file", null);
            split_action.activate.connect ((parameter) => {
                split_file_at_cursor ();
            });
            context_actions.add_action (split_action);

            var insert_datetime_action = new GLib.SimpleAction ("insert_datetime", null);
            insert_datetime_action.activate.connect ((parameter) => {
                editor.insert_datetime ();
            });
            context_actions.add_action (insert_datetime_action);

            var insert_frontmatter_action = new GLib.SimpleAction ("insert_frontmatter", null);
            insert_frontmatter_action.activate.connect ((parameter) => {
                editor.insert_yaml_frontmatter ();
            });
            context_actions.add_action (insert_frontmatter_action);

            var insert_citation_action = new GLib.SimpleAction ("insert_citation", GLib.VariantType.STRING);
            insert_citation_action.activate.connect ((parameter) => {
                if (parameter == null) {
                    return;
                }
                editor.insert_citation (parameter.get_string ());
            });
            context_actions.add_action (insert_citation_action);
        }

        private void setup_context_menu_signal () {
            // Note: We'll set the extra menu once on startup
            // GTK4's set_extra_menu() handles context menu extension for us
            update_extra_menu ();
            debug ("Context menu initialized");
        }

        private void update_extra_menu () {
            debug ("update_extra_menu called!");
            if (!editor.editable) {
                debug ("update_extra_menu: editor not editable");
                editor.set_extra_menu (null);
                return;
            }

            var menu_model = build_extra_menu_model ();
            debug ("update_extra_menu: menu_model = %s, n_items = %u", 
                menu_model != null ? "not null" : "null",
                menu_model != null ? menu_model.get_n_items () : 0);
            editor.set_extra_menu (menu_model);
        }

        private MenuModel? build_extra_menu_model () {
            var root = new GLib.Menu ();

            // Add spelling corrections if a misspelled word is at cursor
            // Use libspelling's built-in menu model for corrections
            var spell_adapter = editor.get_spell_adapter ();
            debug ("build_extra_menu: spell_adapter = %s", spell_adapter != null ? "not null" : "null");
            
            if (spell_adapter != null && spell_adapter.get_enabled ()) {
                debug ("build_extra_menu: spell adapter is enabled, getting menu model...");
                var spell_menu = spell_adapter.get_menu_model ();
                debug ("build_extra_menu: spell_menu = %s", spell_menu != null ? "not null" : "null");
                if (spell_menu != null) {
                    debug ("build_extra_menu: spell menu has %u items", spell_menu.get_n_items ());
                }
                
                if (spell_menu != null) {
                    root.append_section (null, spell_menu);
                }

                editor.insert_action_group ("spelling", spell_adapter);
            }

            var insert_section = new GLib.Menu ();
            insert_section.append (_("Insert Datetime"), "editor.insert_datetime");
            insert_section.append (_("Insert YAML Frontmatter"), "editor.insert_frontmatter");
            root.append_section (null, insert_section);

            var citations = editor.get_citation_labels ();
            if (citations.size > 0) {
                debug ("build_extra_menu: found %u citations", citations.size);
                var citation_menu = new GLib.Menu ();
                foreach (var label in citations.keys) {
                    string title = citations.get (label);
                    var citation_item = new GLib.MenuItem (label, "editor.insert_citation");
                    citation_item.set_attribute_value ("target", new GLib.Variant.string (label));
                    if (title != null && title != "") {
                        citation_item.set_attribute_value ("tooltip", new GLib.Variant.string (title));
                    }
                    citation_menu.append_item (citation_item);
                }

                var citation_item_root = new GLib.MenuItem (_("Insert Citation"), null);
                citation_item_root.set_submenu (citation_menu);

                var citation_section = new GLib.Menu ();
                citation_section.append_item (citation_item_root);
                root.append_section (null, citation_section);
            }

            var file_section = new GLib.Menu ();
            file_section.append (_("Split File Here..."), "editor.split_file");
            root.append_section (null, file_section);

            debug ("build_extra_menu: final root menu has %u items", root.get_n_items ());
            return root;
        }

        private void split_file_at_cursor () {
            var file = File.new_for_path (editor.file_path);
            if (editor.file_path == "" || !file.query_exists ()) {
                return;
            }

            // Get cursor position
            var cursor_mark = editor.buffer.get_insert ();
            Gtk.TextIter cursor;
            editor.buffer.get_iter_at_mark (out cursor, cursor_mark);

            // Get text before and after cursor
            Gtk.TextIter start, end;
            editor.buffer.get_bounds (out start, out end);

            string text_before = editor.buffer.get_text (start, cursor, true);
            string text_after = editor.buffer.get_text (cursor, end, true);

            // Prompt for new filename
            var settings = AppSettings.get_default ();
            settings.menu_active = true;

            var dialog = new Adw.MessageDialog (
                ThiefApp.get_instance (),
                _("Split File"),
                _("Enter a name for the new file that will contain the text after the cursor:")
            );

            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("split", _("Split"));
            dialog.set_response_appearance ("split", Adw.ResponseAppearance.SUGGESTED);
            dialog.set_default_response ("split");

            var entry = new Gtk.Entry ();
            entry.set_placeholder_text (_("new-file.md"));
            entry.set_activates_default (true);

            // Suggest a filename based on current file with smart numbering
            string base_name = file.get_basename ();
            string ext = "";
            int dot_pos = base_name.last_index_of (".");
            if (dot_pos > 0) {
                ext = base_name.substring (dot_pos);
                base_name = base_name.substring (0, dot_pos);
            }

            // Check if filename ends with -N pattern (e.g., "chapter-5")
            string suggested_name = base_name + "-2" + ext;
            try {
                var num_pattern = new Regex ("^(.+)-(\\d+)$");
                MatchInfo match;
                if (num_pattern.match (base_name, 0, out match)) {
                    // Extract the base and number
                    string name_part = match.fetch (1);
                    string num_part = match.fetch (2);
                    int current_num = int.parse (num_part);
                    int next_num = current_num + 1;
                    suggested_name = "%s-%d%s".printf (name_part, next_num, ext);
                }
            } catch (Error e) {
                warning ("Regex error: %s", e.message);
            }

            entry.set_text (suggested_name);
            entry.select_region (0, -1);

            var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
            content_box.append (entry);
            dialog.set_extra_child (content_box);

            dialog.response.connect ((response) => {
                if (response == "split") {
                    string new_filename = entry.get_text ().strip ();
                    if (new_filename != "") {
                        perform_split (file, text_before, text_after, new_filename);
                    }
                }
                settings.menu_active = false;
                dialog.close ();
            });

            dialog.present ();
        }

        private void perform_split (File file, string text_before, string text_after, string new_filename) {
            if (!file.query_exists ()) {
                return;
            }

            var parent_dir = file.get_parent ();
            if (parent_dir == null || !parent_dir.query_exists ()) {
                return;
            }

            // Create the new file
            var new_file = parent_dir.get_child (new_filename);
            if (new_file.query_exists ()) {
                var warning_dialog = new Adw.MessageDialog (
                    ThiefApp.get_instance (),
                    _("File Exists"),
                    _("A file with that name already exists. Please choose a different name.")
                );
                warning_dialog.add_response ("ok", _("OK"));
                warning_dialog.present ();
                return;
            }

            try {
                // Save the "before" text to the current file
                FileManager.save_file (file, text_before.data);
                editor.buffer.text = text_before;

                // Create and save the new file with the "after" text
                FileManager.save_file (new_file, text_after.data);

                // Find the current sheet and its parent Sheets widget
                var instance = ThiefApp.get_instance ();
                var library = instance.library;
                var current_sheet = library.find_sheet_for_path (editor.file_path);
                
                if (current_sheet != null) {
                    var sheets = current_sheet.get_parent_sheets ();
                    if (sheets != null) {
                        // Refresh to show the new file
                        sheets.refresh ();
                        
                        // Try to reorder so new file appears after current file
                        string current_basename = file.get_basename ();
                        sheets.move_sheet_after (current_basename, new_filename);
                    }
                }

                // Show success message
                var success_dialog = new Adw.MessageDialog (
                    ThiefApp.get_instance (),
                    _("File Split"),
                    _("File split successfully. The new file has been created.")
                );
                success_dialog.add_response ("ok", _("OK"));
                success_dialog.present ();

            } catch (Error e) {
                warning ("Could not split file: %s", e.message);
                var error_dialog = new Adw.MessageDialog (
                    ThiefApp.get_instance (),
                    _("Error"),
                    _("Could not split file: %s").printf (e.message)
                );
                error_dialog.add_response ("ok", _("OK"));
                error_dialog.present ();
            }
        }

        private void replace_misspelled_word (string replacement) {
            // Get the cursor position
            var cursor_mark = editor.buffer.get_insert ();
            Gtk.TextIter cursor;
            editor.buffer.get_iter_at_mark (out cursor, cursor_mark);

            // Move to start of word
            var word_start = cursor;
            var word_end = cursor;
            
            if (!word_start.backward_word_start ()) {
                word_start = cursor;
            }
            if (!word_end.forward_word_end ()) {
                word_end = cursor;
            }

            // Replace the word if we found it
            if (!word_start.equal (word_end)) {
                editor.buffer.begin_user_action ();
                editor.buffer.delete (ref word_start, ref word_end);
                editor.buffer.insert (ref word_start, replacement, -1);
                editor.buffer.end_user_action ();
            }
        }
    }
}
