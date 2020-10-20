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

namespace ThiefMD.Controllers.Dialogs {
    public File get_target_save_file_with_extension (
        string title,
        Gtk.FileFilter filter,
        string ext)
    {
        string accept = _("_Save");
        string cancel = _("_Cancel");
        Gtk.FileChooserAction action = Gtk.FileChooserAction.SAVE;

        var chooser = new Gtk.FileChooserNative (title, null, action, accept, cancel);
        chooser.action = action;
        chooser.set_do_overwrite_confirmation (true);

        if (filter != null) {
            chooser.add_filter (filter);
        }

        if (ext != "") {
            chooser.set_current_name ("my-great-work." + ext);
        }

        File file = null;
        if (chooser.run () == Gtk.ResponseType.ACCEPT) {
            file = chooser.get_file ();
        }

        chooser.destroy ();
        return file;
    }

    public Gtk.FileChooserNative create_file_chooser (string title,
            Gtk.FileChooserAction action, string ext = "") {

        string accept = "";
        string cancel = _("_Cancel");
        if (action == Gtk.FileChooserAction.OPEN) {
            accept = _("_Open");
        } else if (action == Gtk.FileChooserAction.SAVE) {
            accept = _("_Save");
        } else if (action == Gtk.FileChooserAction.SELECT_FOLDER) {
            accept = _("_Add to Library");
        }

        var chooser = new Gtk.FileChooserNative (title, null, action, accept, cancel);
        chooser.action = action;

        if (action == Gtk.FileChooserAction.SAVE) {
            chooser.set_do_overwrite_confirmation (true);
            var pdf = new Gtk.FileFilter ();
            pdf.set_filter_name (_("PDF file"));
            pdf.add_mime_type ("application/pdf");
            pdf.add_pattern ("*.pdf");
            chooser.add_filter (pdf);

            var epub_filter = new Gtk.FileFilter ();
            epub_filter.set_filter_name (_("ePUB file"));
            epub_filter.add_mime_type ("application/epub+zip");
            epub_filter.add_pattern ("*.epub");
            chooser.add_filter (epub_filter);

            var docx_filter = new Gtk.FileFilter ();
            docx_filter.set_filter_name (_("docx file"));
            docx_filter.add_mime_type ("application/vnd.openxmlformats-officedocument.wordprocessingml.document");
            docx_filter.add_pattern ("*.docx");
            chooser.add_filter (docx_filter);

            var markdown_filter = new Gtk.FileFilter ();
            markdown_filter.set_filter_name (_("Markdown files"));
            markdown_filter.add_mime_type ("text/markdown");
            markdown_filter.add_pattern ("*.md");
            markdown_filter.add_pattern ("*.markdown");
            chooser.add_filter (markdown_filter);

            var html_filter = new Gtk.FileFilter ();
            html_filter.set_filter_name (_("HTML files"));
            html_filter.add_mime_type ("text/html");
            html_filter.add_pattern ("*.html");
            html_filter.add_pattern ("*.htm");
            chooser.add_filter (html_filter);

            var mhtml_filter = new Gtk.FileFilter ();
            mhtml_filter.set_filter_name (_("MHTML files"));
            mhtml_filter.add_mime_type ("application/x-mimearchive");
            mhtml_filter.add_pattern ("*.mhtml");
            mhtml_filter.add_pattern ("*.mht");
            chooser.add_filter (mhtml_filter);

            var tex_filter = new Gtk.FileFilter ();
            tex_filter.set_filter_name (_("LaTeX file"));
            tex_filter.add_mime_type ("application/x-tex");
            tex_filter.add_pattern ("*.tex");
            chooser.add_filter (tex_filter);

            if (ext == "epub") {
                chooser.set_current_name ("my-great-novel.epub");
                chooser.set_filter (epub_filter);
            } else if (ext == "pdf") {
                chooser.set_current_name ("my-great-work.pdf");
                chooser.set_filter (pdf);
            }

            chooser.selection_changed.connect (() => {
                string current_file = chooser.get_current_name ();
                string filter_name = chooser.filter.get_filter_name ().down ();
                string filter_ext = "md";
                if (filter_name.contains ("markdown")) {
                    filter_ext = "md";
                } else if (filter_name.contains ("epub")) {
                    filter_ext = "epub";
                } else if (filter_name.contains ("pdf")) {
                    filter_ext = "pdf";
                } else if (filter_name.contains ("doc")) {
                    filter_ext = "docx";
                } else if (filter_name.contains ("mhtml")) {
                    filter_ext = "mhtml";
                } else if (filter_name.contains ("html")) {
                    filter_ext = "html";
                } else if (filter_name.contains ("latex")) {
                    filter_ext = "tex";
                }

                if (current_file.last_index_of (".") != -1) {
                    current_file = current_file.substring (0, current_file.last_index_of (".") + 1) + filter_ext;
                } else {
                    current_file += filter_ext;
                }
                chooser.set_current_name (current_file);
            });

        } else if (action != Gtk.FileChooserAction.SELECT_FOLDER) {
            if (ext == "") {
                var filter1 = new Gtk.FileFilter ();
                filter1.set_filter_name (_("Markdown files"));
                filter1.add_pattern ("*.md");
                filter1.add_pattern ("*.markdown");
                chooser.add_filter (filter1);
            }

            var filter = new Gtk.FileFilter ();
            filter.set_filter_name (_("All files"));
            filter.add_pattern ("*");
            chooser.add_filter (filter);
        }

        return chooser;
    }

    public string select_folder_dialog () {
        var chooser = create_file_chooser (_("Add to Library"), Gtk.FileChooserAction.SELECT_FOLDER);
        string path = "";
        if (chooser.run () == Gtk.ResponseType.ACCEPT) {
            path = chooser.get_file ().get_path ();
        }
        chooser.destroy ();
        return path;
    }

    public File display_open_dialog (string ext = "") {
        var chooser = create_file_chooser (_("Open file"),
                Gtk.FileChooserAction.OPEN, ext);
        File file = null;

        if (chooser.run () == Gtk.ResponseType.ACCEPT)
            file = chooser.get_file ();

        chooser.destroy ();
        return file;
    }

    public File display_save_dialog (bool epub_ext = true) {
        var chooser = create_file_chooser (_("Save file"),
                Gtk.FileChooserAction.SAVE, epub_ext ? "epub" : "pdf");
        File file = null;

        if (chooser.run () == Gtk.ResponseType.ACCEPT)
            file = chooser.get_file ();

        chooser.destroy ();
        return file;
    }

    public class Dialog : Gtk.MessageDialog {
        public Dialog.display_save_confirm (Gtk.Window parent) {
            set_markup ("<b>" +
                    _("There are unsaved changes to the file. Do you want to save?") + "</b>" +
                    "\n\n" + _("If you don't save, changes will be lost forever."));
            use_markup = true;
            type_hint = Gdk.WindowTypeHint.DIALOG;
            set_transient_for (parent);

            var button = new Gtk.Button.with_label (_("Close without saving"));
            button.show ();
            add_action_widget (button, Gtk.ResponseType.NO);
            add_button ("_Cancel", Gtk.ResponseType.CANCEL);
            add_button ("_Save", Gtk.ResponseType.YES);
            message_type = Gtk.MessageType.WARNING;
        }
    }
}
