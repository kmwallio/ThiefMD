/*
 * Copyright (C) 2017 Lains
 * 
 * Modified July 5, 2018
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

using GLib;

namespace ThiefMD.Controllers.Dialogs {
    private Gtk.FileDialog build_dialog (string title) {
        var dialog = new Gtk.FileDialog ();
        dialog.set_title (title);
        return dialog;
    }

    private void apply_filter (Gtk.FileDialog dialog, Gtk.FileFilter filter) {
            var filters = new GLib.ListStore (typeof (Gtk.FileFilter));
        filters.append (filter);
        dialog.set_filters (filters);
        dialog.set_default_filter (filter);
    }

    private File? run_open_dialog (Gtk.FileDialog dialog) {
        File? file = null;
        var loop = new GLib.MainLoop ();
        dialog.open.begin (ThiefApp.get_instance (), null, (obj, res) => {
            try {
                file = dialog.open.end (res);
            } catch (Error e) {
                warning ("Open dialog failed: %s", e.message);
            }
            loop.quit ();
        });
        loop.run ();
        return file;
    }

    private File? run_save_dialog (Gtk.FileDialog dialog) {
        File? file = null;
        var loop = new GLib.MainLoop ();
        dialog.save.begin (ThiefApp.get_instance (), null, (obj, res) => {
            try {
                file = dialog.save.end (res);
            } catch (Error e) {
                warning ("Save dialog failed: %s", e.message);
            }
            loop.quit ();
        });
        loop.run ();
        return file;
    }

    private File? run_folder_dialog (Gtk.FileDialog dialog) {
        File? file = null;
        var loop = new GLib.MainLoop ();
        dialog.select_folder.begin (ThiefApp.get_instance (), null, (obj, res) => {
            try {
                file = dialog.select_folder.end (res);
            } catch (Error e) {
                warning ("Folder dialog failed: %s", e.message);
            }
            loop.quit ();
        });
        loop.run ();
        return file;
    }

    public File? get_target_save_file_with_extension (
        string title,
        Gtk.FileFilter filter,
        string ext)
    {
        var dialog = build_dialog (title);
        if (ext != "") {
            dialog.set_initial_name ("my-great-work." + ext);
        }
        if (filter != null) {
            apply_filter (dialog, filter);
        }
        return run_save_dialog (dialog);
    }

    public string select_folder_dialog () {
        var dialog = build_dialog (_("Add to Library"));
        dialog.set_modal (true);
        var file = run_folder_dialog (dialog);
        return (file != null) ? file.get_path () : "";
    }

    public File? display_open_dialog (string ext = "") {
        var dialog = build_dialog (_("Open file"));
        if (ext != "") {
            var filter = new Gtk.FileFilter ();
            filter.set_filter_name (_("Supported files"));
            foreach (unowned string pattern in ext.split (";")) {
                if (pattern != "") {
                    filter.add_pattern (pattern);
                }
            }
            apply_filter (dialog, filter);
        }
        return run_open_dialog (dialog);
    }

    public File? display_save_dialog (bool epub_ext = true) {
        var dialog = build_dialog (_("Save file"));

        var pdf = new Gtk.FileFilter ();
        pdf.set_filter_name (_("PDF file"));
        pdf.add_mime_type ("application/pdf");
        pdf.add_pattern ("*.pdf");

        var epub_filter = new Gtk.FileFilter ();
        epub_filter.set_filter_name (_("ePUB file"));
        epub_filter.add_mime_type ("application/epub+zip");
        epub_filter.add_pattern ("*.epub");

            var filters = new GLib.ListStore (typeof (Gtk.FileFilter));
        filters.append (pdf);
        filters.append (epub_filter);
        dialog.set_filters (filters);
        dialog.set_default_filter (epub_ext ? epub_filter : pdf);
        dialog.set_initial_name (epub_ext ? "my-great-novel.epub" : "my-great-work.pdf");

        return run_save_dialog (dialog);
    }

    public class Dialog : Adw.MessageDialog {
        public Dialog.display_save_confirm (Gtk.Window parent) {
            Object (transient_for: parent, modal: true);
            set_heading (_("There are unsaved changes to the file. Do you want to save?"));
            set_body (_("If you don't save, changes will be lost forever."));

            add_response ("close-without-saving", _("Close without saving"));
            add_response ("cancel", _("_Cancel"));
            add_response ("save", _("_Save"));

            set_response_appearance ("save", Adw.ResponseAppearance.SUGGESTED);
            set_default_response ("save");
            set_close_response ("cancel");
        }
    }
}
