/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified August 29, 2020
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
    /**
     * Sheet
     * 
     * Button Widget pointing to a file on the system.
     */
    public class Sheet : Gtk.ToggleButton {
        private string _sheet_path;
        private Gtk.Label _label;
        private string _label_buffer;
        private Sheets _parent;
        private int _word_count;
        private string _sheet_title;
        private string _sheet_date;
        private string _notes_path;
        private bool _preview_loaded;
        public ThiefNotes metadata;
        private Gtk.PopoverMenu? _context_menu;
        private GLib.SimpleActionGroup _context_actions;
        private Gdk.Rectangle _last_menu_rect;

        // Change style depending on sheet available in the editor
        public bool active_sheet {
            set {
                var header_context = this.get_style_context ();
                if (value) {
                    header_context.add_class ("thief-list-sheet-active");
                } else {
                    header_context.remove_class ("thief-list-sheet-active");
                }
                redraw ();
                active = value;
            }

            get {
                var header_context = this.get_style_context ();
                return header_context.has_class ("thief-list-sheet-active");
            }
        }

        public Sheet (string sheet_path, Sheets parent) {
            _sheet_path = sheet_path;
            _parent = parent;
            _sheet_title = "";
            _sheet_date = "";

            // Default to filename
            _label_buffer = "<b>" + sheet_path.substring(sheet_path.last_index_of(Path.DIR_SEPARATOR_S) + 1) + "</b>";
            _label = new Gtk.Label(_label_buffer);
            _label.use_markup = true;
            _label.set_ellipsize (Pango.EllipsizeMode.END);
            _label.xalign = 0;
            set_child (_label);

            var header_context = this.get_style_context ();
            header_context.add_class ("thief-list-sheet");

            clicked.connect (() => {
                debug ("Loading %s\n", _sheet_path);
                SheetManager.load_sheet (this);
                active = active_sheet;
            });

            // Drag source for moving/reordering sheets
            var drag_source = new Gtk.DragSource ();
            // Capture events before the toggle button consumes them so active sheets still drag
            drag_source.set_propagation_phase (Gtk.PropagationPhase.CAPTURE);
            drag_source.actions = Gdk.DragAction.MOVE;
            drag_source.prepare.connect ((x, y) => {
                Value v = Value (typeof (string));
                v.set_string (_sheet_path);
                return new Gdk.ContentProvider.for_value (v);
            });
            add_controller (drag_source);

            // Drop target to accept moved sheets
            var drop_target = new Gtk.DropTarget (typeof (string), Gdk.DragAction.MOVE);
            drop_target.drop.connect ((value, x, y) => {
                string? source_path = (string?) value;
                if (source_path == null) {
                    return false;
                }
                return handle_drop (source_path, y);
            });
            add_controller (drop_target);

            _context_actions = new GLib.SimpleActionGroup ();
            insert_action_group ("sheet", _context_actions);
            setup_context_actions ();
            setup_context_menu_controller ();

            // Deferred preview generation to avoid reading large files at startup
            _preview_loaded = false;
            _word_count = -1; // Mark as not yet calculated
            set_visible (true);
            
            // Generate preview when sheet becomes visible
            map.connect (() => {
                if (!_preview_loaded) {
                    lazy_load_preview ();
                }
            });

            // Load file ordering information
            metadata = null;
            _notes_path = sheet_path + ".notes";
            File metadata_file = File.new_for_path (_notes_path);
            if (metadata_file.query_exists ()) {
                try {
                    metadata = ThiefNotes.new_for_file (metadata_file.get_path ());
                } catch (Error e) {
                    warning ("Could not load metafile: %s", e.message);
                }
            }

            if (metadata == null) {
                metadata = new ThiefNotes ();
            }

            debug ("Creating %s\n", sheet_path);
        }

        private bool handle_drop (string source_path, double y) {
            if (_parent == null || source_path == "") {
                return false;
            }

            var source_file = File.new_for_path (source_path);
            if (!source_file.query_exists ()) {
                return false;
            }

            string source_dir = "";
            var parent_dir = source_file.get_parent ();
            if (parent_dir != null) {
                source_dir = parent_dir.get_path ();
            }

            string dest_dir = _parent.get_sheets_path ();
            string source_name = source_file.get_basename ();
            string dest_name = File.new_for_path (_sheet_path).get_basename ();

            // Reorder within the same folder
            if (source_dir == dest_dir) {
                if (source_name == dest_name) {
                    return false;
                }
                int halfway = get_allocated_height () / 2;
                if (y > halfway) {
                    _parent.move_sheet_after (dest_name, source_name);
                } else {
                    _parent.move_sheet_before (dest_name, source_name);
                }
                return true;
            }

            // Move across folders
            string dest_path = Path.build_filename (dest_dir, source_name);
            try {
                source_file.move (File.new_for_path (dest_path), FileCopyFlags.OVERWRITE, null, null);
            } catch (Error e) {
                warning ("Could not move %s to %s: %s", source_path, dest_path, e.message);
                return false;
            }

            // Remove from the origin sheets view/metadata if we can find it
            var library = ThiefApp.get_instance ().library;
            Sheets? origin_sheets = library.find_sheets_for_path (source_dir);
            if (origin_sheets != null && origin_sheets != _parent) {
                Sheet? origin_sheet = library.find_sheet_for_path (source_path);
                if (origin_sheet != null) {
                    origin_sheets.remove_sheet (origin_sheet);
                    origin_sheets.persist_metadata ();
                } else {
                    origin_sheets.refresh ();
                }
            }

            // Reload destination and order near the drop target
            _parent.refresh ();
            if (FileUtils.test (dest_path, FileTest.IS_REGULAR)) {
                if (y > (get_allocated_height () / 2)) {
                    _parent.move_sheet_after (dest_name, source_name);
                } else {
                    _parent.move_sheet_before (dest_name, source_name);
                }
            }
            _parent.persist_metadata ();

            return true;
        }

        public Sheets get_parent_sheets () {
            return _parent;
        }

        public string file_path () {
            return _sheet_path;
        }

        public string file_name () {
            return _sheet_path.substring (_sheet_path.last_index_of (Path.DIR_SEPARATOR_S) + 1);
        }

        private void lazy_load_preview () {
            // Use idle callback to avoid blocking UI during startup
            GLib.Idle.add (() => {
                load_preview_sync ();
                return false;
            });
        }
        
        private void load_preview_sync () {
            if (_preview_loaded) {
                return;
            }
            
            var settings = AppSettings.get_default ();
            string file_contents = FileManager.get_file_lines_yaml (_sheet_path, settings.num_preview_lines, true, out _sheet_title, out _sheet_date);
            string file_title = "<b>" + _sheet_path.substring(_sheet_path.last_index_of (Path.DIR_SEPARATOR_S) + 1) + "</b>";

            // Only calculate word count if needed (negative value means not calculated)
            if (_word_count < 0) {
                _word_count = FileManager.get_word_count (_sheet_path);
            }
            
            if (file_contents.chomp() != "" && settings.num_preview_lines != 0) {
                string content_preview = "<small>" + SheetManager.mini_mark(file_contents) + "</small>";
                if (settings.show_sheet_filenames) {
                    _label_buffer = file_title + "\n" + content_preview;
                } else {
                    _label_buffer = content_preview;
                }
            } else {
                _label_buffer = file_title;
            }

            _label.set_label (_label_buffer);
            _label.width_request = settings.view_sheets_width - 10;
            width_request = settings.view_sheets_width;
            _preview_loaded = true;
        }

        public void redraw () {
            // Force reload of preview
            _preview_loaded = false;
            load_preview_sync ();
            
            var settings = AppSettings.get_default ();
            settings.writing_changed ();
        }

        public void save_notes () {
            File metadata_file = File.new_for_path (_notes_path);
            if (metadata.notes == "" && metadata.tags.is_empty) {
                if (metadata_file.query_exists ()) {
                    try {
                        metadata_file.trash ();
                    } catch (Error e) {
                        warning ("Could not remove empty notes file: %s", e.message);
                    }
                }
            } else {
                try {
                    ThiefNotesSerializable cereal = new ThiefNotesSerializable (metadata);
                    Json.Node root = Json.gobject_serialize (cereal);
                    Json.Generator generate = new Json.Generator ();
                    generate.set_root (root);
                    generate.set_pretty (true);
                    if (metadata_file.query_exists ()) {
                        metadata_file.delete ();
                    }
                    debug ("Saving to: %s", metadata_file.get_path ());
                    FileManager.save_file (metadata_file, generate.to_data (null).data);
                } catch (Error e) {
                    warning ("Could not serialize notes data: %s", e.message);
                }
            }
        }

        public int get_word_count () {
            // Lazy load word count if not yet calculated
            if (_word_count < 0) {
                _word_count = FileManager.get_word_count (_sheet_path);
            }
            return _word_count;
        }

        public string get_title () {
            return _sheet_title;
        }

        public string get_date () {
            return _sheet_date;
        }

        //
        // Click Menu Options
        //

        private void setup_context_menu_controller () {
            var right_click = new Gtk.GestureClick ();
            right_click.set_button (3);
            right_click.released.connect ((n_press, x, y) => {
                show_context_menu (x, y);
            });
            add_controller (right_click);
        }

        private void show_context_menu (double x, double y) {
            var menu_model = build_context_menu_model ();
            if (menu_model == null) {
                return;
            }

            _last_menu_rect = Gdk.Rectangle ();
            _last_menu_rect.x = (int) x;
            _last_menu_rect.y = (int) y;
            _last_menu_rect.width = 1;
            _last_menu_rect.height = 1;
            if (_context_menu != null) {
                _context_menu.popdown ();
                _context_menu.unparent ();
                _context_menu = null;
            }

            _context_menu = new Gtk.PopoverMenu.from_model (menu_model);
            _context_menu.set_has_arrow (true);
            _context_menu.set_pointing_to (_last_menu_rect);
            _context_menu.set_parent (this);
            _context_menu.set_autohide (true);
            _context_menu.set_flags (Gtk.PopoverMenuFlags.NESTED);
            _context_menu.popup ();
        }

        private MenuModel? build_context_menu_model () {
            if (_parent == null) {
                return null;
            }

            var root = new GLib.Menu ();

            var sort_menu = new GLib.Menu ();
            var sort_name_section = new GLib.Menu ();
            sort_name_section.append (_("Sort by Filename Ascending"), "sheet.sort_filename_asc");
            sort_name_section.append (_("Sort by Filename Descending"), "sheet.sort_filename_desc");
            sort_menu.append_section (null, sort_name_section);

            var sort_title_section = new GLib.Menu ();
            sort_title_section.append (_("Sort by Title Ascending"), "sheet.sort_title_asc");
            sort_title_section.append (_("Sort by Title Descending"), "sheet.sort_title_desc");
            sort_menu.append_section (null, sort_title_section);

            var sort_date_section = new GLib.Menu ();
            sort_date_section.append (_("Sort by Date Ascending"), "sheet.sort_date_asc");
            sort_date_section.append (_("Sort by Date Descending"), "sheet.sort_date_desc");
            sort_menu.append_section (null, sort_date_section);

            var sort_item = new GLib.MenuItem (_("Sort by"), null);
            sort_item.set_submenu (sort_menu);
            root.append_item (sort_item);

            var actions_section = new GLib.Menu ();
            actions_section.append (_("Preview"), "sheet.preview");
            actions_section.append (_("Publisher Preview"), "sheet.publisher_preview");
            actions_section.append (_("Copy File Path"), "sheet.copy_path");
            root.append_section (null, actions_section);

            var danger_section = new GLib.Menu ();
            var danger_item = new GLib.MenuItem (_("Danger Zone"), null);
            danger_item.set_attribute_value ("enabled", new GLib.Variant.boolean (false));
            danger_section.append_item (danger_item);
            danger_section.append (_("Move to Trash"), "sheet.move_to_trash");
            root.append_section (null, danger_section);

            return root;
        }

        private void setup_context_actions () {
            var sort_filename_asc = new GLib.SimpleAction ("sort_filename_asc", null);
            sort_filename_asc.activate.connect ((parameter) => {
                _parent.sort_sheets_by_name ();
            });
            _context_actions.add_action (sort_filename_asc);

            var sort_filename_desc = new GLib.SimpleAction ("sort_filename_desc", null);
            sort_filename_desc.activate.connect ((parameter) => {
                _parent.sort_sheets_by_name (false);
            });
            _context_actions.add_action (sort_filename_desc);

            var sort_title_asc = new GLib.SimpleAction ("sort_title_asc", null);
            sort_title_asc.activate.connect ((parameter) => {
                _parent.sort_sheets_by_title ();
            });
            _context_actions.add_action (sort_title_asc);

            var sort_title_desc = new GLib.SimpleAction ("sort_title_desc", null);
            sort_title_desc.activate.connect ((parameter) => {
                _parent.sort_sheets_by_title (false);
            });
            _context_actions.add_action (sort_title_desc);

            var sort_date_asc = new GLib.SimpleAction ("sort_date_asc", null);
            sort_date_asc.activate.connect ((parameter) => {
                _parent.sort_sheets_by_date ();
            });
            _context_actions.add_action (sort_date_asc);

            var sort_date_desc = new GLib.SimpleAction ("sort_date_desc", null);
            sort_date_desc.activate.connect ((parameter) => {
                _parent.sort_sheets_by_date (false);
            });
            _context_actions.add_action (sort_date_desc);

            var preview_action = new GLib.SimpleAction ("preview", null);
            preview_action.activate.connect ((parameter) => {
                SheetManager.load_sheet (this);
                active = active_sheet;
                PreviewWindow pvw = PreviewWindow.get_instance ();
                pvw.show ();
            });
            _context_actions.add_action (preview_action);

            var publisher_preview_action = new GLib.SimpleAction ("publisher_preview", null);
            publisher_preview_action.activate.connect ((parameter) => {
                string preview_markdown = FileManager.get_file_contents (_sheet_path);
                PublisherPreviewWindow ppw = new PublisherPreviewWindow (preview_markdown, is_fountain (_sheet_path));
                ppw.show ();
            });
            _context_actions.add_action (publisher_preview_action);

            var copy_path_action = new GLib.SimpleAction ("copy_path", null);
            copy_path_action.activate.connect ((parameter) => {
                string file_path = _sheet_path;
                var display = Gdk.Display.get_default ();
                if (display != null) {
                    var copy = display.get_clipboard ();
                    copy.set_text (file_path);
                }
            });
            _context_actions.add_action (copy_path_action);

            var move_to_trash_action = new GLib.SimpleAction ("move_to_trash", null);
            move_to_trash_action.activate.connect ((parameter) => {
                debug ("Got remove for sheet %s", _sheet_path);
                _parent.remove_sheet (this);
                SheetManager.close_active_file (_sheet_path);
                FileManager.move_to_trash (_sheet_path);
                File metadata_file = File.new_for_path (_notes_path);
                if (metadata_file.query_exists ()) {
                    FileManager.move_to_trash (_notes_path);
                }
            });
            _context_actions.add_action (move_to_trash_action);
        }

        public static bool areEqual (Sheet a, Sheet b) {
            if ((b == null && a != null) || (a == null && b != null)) {
                return false;
            }

            return (a._parent.get_sheets_path () == b._parent.get_sheets_path ()) &&
                (a._sheet_path == b._sheet_path) &&
                (a._label_buffer == b._label_buffer);
        }
    }

    public class ThiefNotesSerializable : Object {
        public string[] tags { get; set; }
        public string notes { get; set; }

        public ThiefNotesSerializable (ThiefNotes thief_notes) {
            tags = new string[thief_notes.tags.size];
            for(int i = 0; i < thief_notes.tags.size; i++) {
                tags[i] = thief_notes.tags.get (i);
            }

            notes = string_or_empty_string (thief_notes.notes);
        }
    }

    public class ThiefNotes : Object {
        public Gee.List<string> tags;
        public string notes { get; set; }

        public ThiefNotes () {
            tags = new Gee.ArrayList<string> ();
        }

        public static ThiefNotes new_for_file (string file) throws Error {
            ThiefNotes t_notes = new ThiefNotes ();

            Json.Parser parser = new Json.Parser ();
            parser.load_from_file (file);
            Json.Node data = parser.get_root ();
            ThiefNotesSerializable thief_notes = Json.gobject_deserialize (typeof (ThiefNotesSerializable), data) as ThiefNotesSerializable;
            if (thief_notes != null) {
                foreach (var s in thief_notes.tags) {
                    t_notes.add_tag (s);
                }

                t_notes.notes = string_or_empty_string (thief_notes.notes);
            }

            return t_notes;
        }

        public void add_tag (string tag_name) {
            if (!tags.contains (tag_name)) {
                tags.add (tag_name);
            }
        }

        public void remove_tag (string tag_name) {
            int index = tags.index_of (tag_name);
            if (index != -1) {
                tags.remove_at (index);
            }
        }
    }
}
