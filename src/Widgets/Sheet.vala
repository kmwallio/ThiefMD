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
        public ThiefNotes metadata;

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

            // @TODO: GTK4 Add ability to be dragged
            /*
            Gtk.drag_source_set (
                this,                      // widget will be drag-able
                Gdk.ModifierType.BUTTON1_MASK, // modifier that will start a drag
                target_list,               // lists of target to support
                Gdk.DragAction.MOVE            // what to do with data after dropped
            );

            // All possible source signals
            this.drag_begin.connect(on_drag_begin);
            this.drag_data_get.connect(on_drag_data_get);
            this.drag_data_delete.connect(on_drag_data_delete);
            this.drag_end.connect(on_drag_end);

            // Add ability to be dropped on
            Gtk.drag_dest_set (
                this,                          // widget will be drag-able
                DestDefaults.ALL,              // modifier that will start a drag
                target_list,                   // lists of target to support
                Gdk.DragAction.MOVE            // what to do with data after dropped
            );
            this.drag_motion.connect(this.on_drag_motion);
            this.drag_leave.connect(this.on_drag_leave);
            this.drag_drop.connect(this.on_drag_drop);
            this.drag_data_received.connect(this.on_drag_data_received);
            */

            // Load minimark if file has content
            redraw ();
            set_visible (true);

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

        public void redraw () {
            var settings = AppSettings.get_default ();
            string file_contents = FileManager.get_file_lines_yaml (_sheet_path, settings.num_preview_lines, true, out _sheet_title, out _sheet_date);
            string file_title = "<b>" + _sheet_path.substring(_sheet_path.last_index_of (Path.DIR_SEPARATOR_S) + 1) + "</b>";

            _word_count = FileManager.get_word_count (_sheet_path);
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

        // TODO: GTK4 migration - Replace Gtk.Menu with Gtk.PopoverMenu
        // This context menu functionality will be re-implemented with GMenu models
        /*
        public override bool button_press_event(Gdk.EventButton event) {
            base.button_press_event (event);

            if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) {
                Gtk.Menu menu = new Gtk.Menu ();
                menu.attach_to_widget (this, null);

                Gtk.MenuItem sort_sheets = new Gtk.MenuItem.with_label (_("Sort by"));
                Gtk.Menu sort_menu = new Gtk.Menu ();
                {
                    Gtk.MenuItem sort_sheets_by_name = new Gtk.MenuItem.with_label (_("Sort by Filename Ascending"));
                    sort_menu.add (sort_sheets_by_name);
                    sort_sheets_by_name.activate.connect (() => {
                        _parent.sort_sheets_by_name ();
                    });

                    Gtk.MenuItem sort_sheets_by_name_desc = new Gtk.MenuItem.with_label (_("Sort by Filename Descending"));
                    sort_menu.add (sort_sheets_by_name_desc);
                    sort_sheets_by_name_desc.activate.connect (() => {
                        _parent.sort_sheets_by_name (false);
                    });

                    sort_menu.add (new Gtk.SeparatorMenuItem ());
                    Gtk.MenuItem sort_sheets_by_title = new Gtk.MenuItem.with_label (_("Sort by Title Ascending"));
                    sort_menu.add (sort_sheets_by_title);
                    sort_sheets_by_title.activate.connect (() => {
                        _parent.sort_sheets_by_title ();
                    });

                    Gtk.MenuItem sort_sheets_by_title_desc = new Gtk.MenuItem.with_label (_("Sort by Title Descending"));
                    sort_menu.add (sort_sheets_by_title_desc);
                    sort_sheets_by_title_desc.activate.connect (() => {
                        _parent.sort_sheets_by_title (false);
                    });

                    sort_menu.add (new Gtk.SeparatorMenuItem ());
                    Gtk.MenuItem sort_sheets_by_date = new Gtk.MenuItem.with_label (_("Sort by Date Ascending"));
                    sort_menu.add (sort_sheets_by_date);
                    sort_sheets_by_date.activate.connect (() => {
                        _parent.sort_sheets_by_date ();
                    });

                    Gtk.MenuItem sort_sheets_by_date_desc = new Gtk.MenuItem.with_label (_("Sort by Date Descending"));
                    sort_menu.add (sort_sheets_by_date_desc);
                    sort_sheets_by_date_desc.activate.connect (() => {
                        _parent.sort_sheets_by_date (false);
                    });
                }
                sort_sheets.submenu = sort_menu;
                menu.add (sort_sheets);

                /*
                menu.add (new Gtk.SeparatorMenuItem ());

                Gtk.MenuItem menu_new_window = new Gtk.MenuItem.with_label (_("Open in Separate Window"));
                menu.add (menu_new_window);
                menu_new_window.activate.connect (() => {
                    File target = File.new_for_path (_sheet_path);
                    ThiefApplication.open_file (target);
                });
                menu.add (menu_new_window);
                */

                // TODO: GTK4 - Reimplement menu functionality
                /*
                menu.add (new Gtk.SeparatorMenuItem ());

                Gtk.MenuItem menu_preview_sheet = new Gtk.MenuItem.with_label (_("Preview"));
                menu.add (menu_preview_sheet);
                menu_preview_sheet.activate.connect (() => {
                    this.clicked ();
                    PreviewWindow pvw = PreviewWindow.get_instance ();
                    pvw.show_all ();
                });

                Gtk.MenuItem menu_export_sheet = new Gtk.MenuItem.with_label (_("Export"));
                menu.add (menu_export_sheet);
                menu_export_sheet.activate.connect (() => {
                    string preview_markdown = FileManager.get_file_contents (_sheet_path);
                    PublisherPreviewWindow ppw = new PublisherPreviewWindow (preview_markdown, is_fountain (_sheet_path));
                    ppw.show ();
                });

                Gtk.MenuItem copy_file_path = new Gtk.MenuItem.with_label (_("Copy File Path"));
                menu.add (copy_file_path);
                copy_file_path.activate.connect (() => {
                    string file_path = _sheet_path;
                    var copy = Gtk.Clipboard.get_default (Gdk.Display.get_default ());
                    copy.set_text (file_path, file_path.length);
                });

                menu.add (new Gtk.SeparatorMenuItem ());

                //  Gtk.MenuItem menu_rename = new Gtk.MenuItem.with_label (_("Rename File"));
                //  menu_rename.activate.connect (() => {

                //  });
                //  menu.add (menu_rename);

                Gtk.MenuItem menu_danger_zone = new Gtk.MenuItem.with_label (_("Danger Zone"));
                menu_danger_zone.set_sensitive (false);
                menu.add (menu_danger_zone);

                menu.add (new Gtk.SeparatorMenuItem ());

                Gtk.MenuItem menu_delete_sheet = new Gtk.MenuItem.with_label (_("Move to Trash"));
                menu_delete_sheet.activate.connect (() => {
                    debug ("Got remove for sheet %s", _sheet_path);
                    _parent.remove_sheet (this);
                    SheetManager.close_active_file (_sheet_path);
                    FileManager.move_to_trash (_sheet_path);
                    File metadata_file = File.new_for_path (_notes_path);
                    if (metadata_file.query_exists ()) {
                        FileManager.move_to_trash (_notes_path);
                    }
                });
                menu.add (menu_delete_sheet);
                menu.show_all ();
                menu.popup_at_pointer (event);
            }

            return true;
        }

        //
        // Drag Support
        //

        private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
            debug ("%s: on_drag_begin", widget.name);
        }

        private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
            Gtk.SelectionData selection_data,
            uint target_type, uint time)
        {
            debug ("%s: on_drag_data_get for %s", widget.name, _sheet_path);

            switch (target_type) {
                case Target.STRING:
                    selection_data.set (
                        selection_data.get_target(),
                        BYTE_BITS,
                        (uchar [])_sheet_path.to_utf8());
                break;
                default:
                    debug ("No known action to take.");
                break;
            }

            debug ("Done moving");
        }

        private void on_drag_data_delete (Gtk.Widget widget, Gdk.DragContext context) {
            debug ("%s: on_drag_data_delete for %s", widget.name, _sheet_path);
        }

        private void on_drag_end (Gtk.Widget widget, Gdk.DragContext context) {
            debug ("%s: on_drag_end for %s", widget.name, _sheet_path);
        }

        //
        // Drop support
        //

        private bool on_drag_motion (
            Widget widget,
            DragContext context,
            int x,
            int y,
            uint time)
        {
            int mid =  get_allocated_height () / 2;
            // warning ("%s: motion (m: %d, %d)", widget.name, mid, y);
            var header_context = this.get_style_context ();

            if (y < mid && !header_context.has_class ("thief-drop-below")) {
                if (header_context.has_class ("thief-drop-above")) {
                    header_context.remove_class ("thief-drop-above");
                }
                header_context.add_class ("thief-drop-below");
            }

            if (y > mid && !header_context.has_class ("thief-drop-above")) {
                if (header_context.has_class ("thief-drop-below")) {
                    header_context.remove_class ("thief-drop-below");
                }
                header_context.add_class ("thief-drop-above");
            }

            return false;
        }

        private void on_drag_leave (Widget widget, DragContext context, uint time) {
            debug ("%s: on_drag_leave", widget.name);
            var header_context = this.get_style_context ();
            if (header_context.has_class ("thief-drop-above")) {
                header_context.remove_class ("thief-drop-above");
            }

            if (header_context.has_class ("thief-drop-below")) {
                header_context.remove_class ("thief-drop-below");
            }
        }

        private bool on_drag_drop (
            Widget widget,
            DragContext context,
            int x,
            int y,
            uint time)
        {
            debug ("%s: drop (%d, %d)", widget.name, x, y);
            var target_type = (Atom) context.list_targets().nth_data (Target.STRING);

            // Request the data from the source.
            Gtk.drag_get_data (
                widget,         // will receive 'drag_data_received' signal
                context,        // represents the current state of the DnD
                target_type,    // the target type we want
                time            // time stamp
                );

            bool is_valid_drop_site = target_type.name ().ascii_up ().contains ("STRING");

            return is_valid_drop_site;
        }

        private void on_drag_data_received (
            Widget widget,
            DragContext context,
            int x,
            int y,
            SelectionData selection_data,
            uint target_type,
            uint time)
        {
            var header_context = this.get_style_context ();

            int mid =  get_allocated_height () / 2;
            debug ("%s: data (m: %d, %d)", widget.name, mid, y);

            if (header_context.has_class ("thief-drop-above")) {
                header_context.remove_class ("thief-drop-above");
            }

            if (header_context.has_class ("thief-drop-below")) {
                header_context.remove_class ("thief-drop-below");
            }

            File file = dnd_get_file (selection_data, target_type);
            debug ("Got file: %s", file.get_path ());
            if (!file.query_exists ()) {
                Gtk.drag_finish (context, false, false, time);
                return;
            }

            if (ThiefApp.get_instance ().library.file_in_library (file.get_path ())) {
                if (y > mid) {
                    _parent.move_sheet_after (this.file_name (), file.get_basename ());
                } else {
                    _parent.move_sheet_before (this.file_name (), file.get_basename ());
                }
            } else {
                debug ("Importing file");
                FileManager.import_file (file.get_path (), _parent);
            }


            Gtk.drag_finish (context, false, false, time);
            return;
        }
            */

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
