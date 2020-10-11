/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified October 9, 2020
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
    public class SearchResult {
        public string search_term;
        public string file_path;
        public Sheet file_sheet;
        public string text_highlight;
        public int occurrences;
    }

    public class SearchDisplay {
        public string search_term;
        public string file_path;
        public Sheet file_sheet;
        public Gtk.Button result;
        public int occurrences;
    }

    public class SearchThread {
        string search_term;
        Sheets to_check;
        SearchWindow to_update;
        public SearchThread (string term, Sheets path, SearchWindow parent) {
            search_term = term;
            to_check = path;
            to_update = parent;
        }

        public void search () {
            debug ("Thread entered");
            GLib.List<Sheet> files = to_check.get_sheets ();
            int res_count = 0;
            for (int i = 0; i < files.length () && to_update.searching; i++) {
                string contents = FileManager.get_file_contents (files.nth_data (i).file_path ());
                int index = contents.down ().index_of (search_term.down ());
                if (index != -1) {
                    int start = (index - 10) >= 0 ? (index - 10) : 0;
                    int end = (index + 50) < contents.length ? 50 : -1;
                    SearchResult res = new SearchResult ();
                    res.occurrences = contents.down ().split (search_term.down ()).length - 1;
                    res.file_path = files.nth_data (i).file_path ();
                    res.search_term = search_term;
                    res.text_highlight = contents.substring (start, end);
                    res.text_highlight = res.text_highlight.replace ("\n", " ");
                    res.text_highlight = res.text_highlight.replace ("&", "&amp;");
                    res.text_highlight = res.text_highlight.replace ("<", "&lt;").replace (">", "&gt;");
                    res.text_highlight = SheetManager.mini_mark (FileManager.get_file_lines_yaml (files.nth_data (i).file_path (), Constants.SHEET_PREVIEW_LINES)) + "\n..." + res.text_highlight + "...";
                    res.text_highlight = res.text_highlight.down ().replace (search_term.down (), "<b>" + search_term + "</b>");
                    res.file_sheet = files.nth_data (i);
                    to_update.results.add (res);
                    res_count++;
                    debug ("Found: %s", res.file_path + " (" + res.occurrences.to_string () + " matches)");
                }
            }
            debug ("Thread done, %d found", res_count);
            to_update.remove_thread ();
            return;
        }
    }

    public class SearchWindow : Gtk.Window {
        Gtk.HeaderBar headerbar;
        public Gee.ConcurrentList<SearchResult> results;
        Gee.ConcurrentList<SearchDisplay> displayed;
        Gtk.Entry search;
        string active_search_term;
        Mutex start_search;
        Mutex ui_update;
        Mutex ui_remove;
        Mutex thread_update;
        public int running_threads;
        public bool searching = false;
        Gtk.Grid search_results;
        Gee.ArrayList<Sheets> searchable;
        TimedMutex one_click;

        public class SearchWindow () {
            ui_update = Mutex ();
            ui_remove = Mutex ();
            thread_update = Mutex ();
            start_search = Mutex ();
            results = new Gee.ConcurrentList<SearchResult> ();
            displayed = new Gee.ConcurrentList<SearchDisplay> ();
            build_ui ();
            one_click = new TimedMutex (750);
        }

        private void build_ui () {
            var settings = AppSettings.get_default ();
            headerbar = new Gtk.HeaderBar ();
            headerbar.set_title (_("Library Search"));
            var header_context = headerbar.get_style_context ();
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);
            header_context.add_class ("thief-toolbar");
            search = new Gtk.Entry ();
            search.placeholder_text = "Enter search";

            search_results = new Gtk.Grid ();
            search_results.orientation = Gtk.Orientation.VERTICAL;

            var scroller = new Gtk.ScrolledWindow (null, null);
            scroller.hexpand = true;
            scroller.vexpand = true;
            scroller.set_policy (Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.AUTOMATIC);
            header_context = scroller.get_style_context ();
            header_context.add_class ("thief-sheets");
            search_results.hexpand = true;
            scroller.add (search_results);

            add (scroller);

            headerbar.pack_start (search);
            headerbar.set_show_close_button (true);
            set_titlebar (headerbar);
            transient_for = ThiefApp.get_instance ().main_window;
            destroy_with_parent = true;

            int w, h;
            ThiefApp.get_instance ().main_window.get_size (out w, out h);

            set_default_size(w / 3, h - 50);

            search.activate.connect (update_terms);

            var live_reload_switch = new Gtk.Switch ();
            live_reload_switch.set_active (false);
            live_reload_switch.tooltip_text = _("Monitor for Library changes");
            headerbar.pack_end (live_reload_switch);
            live_reload_switch.notify["active"].connect (() => {
                if (live_reload_switch.active) {
                    settings.writing_changed.connect (live_reload);
                } else {
                    settings.writing_changed.disconnect (live_reload);
                }
            });

            
            delete_event.connect (() => {
                searching = false;
                if (live_reload_switch.active) {
                    settings.writing_changed.disconnect (live_reload);
                }
                return false;
            });
        }

        public void live_reload () {
            if (active_search_term != search.text) {
                active_search_term = search.text;
            }

            if (active_search_term == null || active_search_term.chomp ().chug () == "") {
                return;
            }

            if (!start_search.trylock ()) {
                return;
            }

            if (!searching) {
                if (ui_remove.trylock ()) {
                    if (ui_update.trylock ()) {
                        while (!displayed.is_empty) {
                            SearchDisplay dis = displayed.get (0);
                            displayed.remove (dis);
                            search_results.remove (dis.result);
                        }
                        ui_update.unlock ();
                        searching = true;
                        create_searchers ();
                        GLib.Idle.add (update_search);
                        GLib.Idle.add (remove_search);
                    }
                    ui_remove.unlock ();
                }
            }
            start_search.unlock ();
        }

        public void update_terms () {
            debug ("Updating search term");
            bool respawn = active_search_term != search.text;
            active_search_term = search.text;

            start_search.lock ();
            // stop all current threads
            if (searching) {
                searching = false;
            }

            while (running_threads > 0) {
                searching = false;
            }
            start_search.unlock ();

            live_reload ();
        }

        public void create_searchers () {
            debug ("spawning seachers");
            searchable = ThiefApp.get_instance ().library.get_all_sheets ();
            if (!Thread.supported ()) {
                debug ("Thread support not available...");
                foreach (var search in searchable) {
                    if (!searching) {
                        break;
                    }
                    SearchThread not_a_thread = new SearchThread (active_search_term, search, this);
                    not_a_thread.search ();
                }
            } else {
                foreach (var search in searchable) {
                    SearchThread thread = new SearchThread (active_search_term, search, this);
                    add_thread ();
                    var nt = new Thread<void> ("search_thread" + search.get_sheets_path (), thread.search);
                }
            }
        }

        public bool remove_search () {
            if (ui_remove.trylock ()) {
                for (int i = 0; i < displayed.size; i++) {
                    if (i < 0 || i > displayed.size) {
                        break;
                    }
                    SearchDisplay dis = displayed.get (i);
                    if (dis.search_term != active_search_term) {
                        displayed.remove (dis);
                        search_results.remove (dis.result);
                        i--;
                    }
                }
                ui_remove.unlock ();
            }

            return searching;
        }

        public void remove_thread () {
            thread_update.lock ();
            running_threads--;
            thread_update.unlock ();
        }

        public void add_thread () {
            thread_update.lock ();
            running_threads++;
            thread_update.unlock ();
        }

        public bool update_search () {
            var settings = AppSettings.get_default ();
            if (ui_update.trylock ()) {
                while (!results.is_empty) {
                    SearchResult res = results.remove_at (0);
                    if (res.search_term == active_search_term) {
                        SearchDisplay dis = new SearchDisplay ();
                        dis.file_path = res.file_path;
                        dis.search_term = res.search_term;
                        dis.result = new Gtk.Button ();
                        string lib_path = get_base_library_path (res.file_path);
                        if (lib_path == "") {
                            lib_path = res.file_path;
                        }
                        var label = new Gtk.Label ("<b>" + lib_path + " (" + res.occurrences.to_string () + " matches)</b>\n" + res.text_highlight);
                        label.xalign = 0;
                        label.set_ellipsize (Pango.EllipsizeMode.END);
                        label.use_markup = true;
                        dis.result.add (label);
                        dis.occurrences = res.occurrences;
                        dis.result.hexpand = true;
                        dis.file_sheet = res.file_sheet;
                        dis.result.clicked.connect (() => {
                            if (one_click.can_do_action ()) {
                                debug ("Opening %s", dis.file_path);
                                // any other method I try crashes everying...
                                dis.file_sheet.clicked ();
                                ThiefApp.get_instance ().search_bar.activate_search ();
                                ThiefApp.get_instance ().search_bar.search_for (dis.search_term);
                            }
                        });

                        SearchDisplay? above = null;
                        int row = 1;
                        foreach (var already in displayed) {
                            if (res.occurrences <= already.occurrences) {
                                above = already;
                                row++;
                            }
                        }

                        search_results.insert_row (row);
                        search_results.attach (dis.result, 1, row);
                        displayed.add (dis);
                        search_results.show_all ();
                        debug ("added result");
                    }
                }
                ui_update.unlock ();
            }

            if (thread_update.trylock ()) {
                if (running_threads == 0) {
                    searching = false;
                }
                thread_update.unlock ();
            }

            return searching;
        }
    }
}