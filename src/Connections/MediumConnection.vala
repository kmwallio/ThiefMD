/*
 * Copyright (C) 2022 kmwallio
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the “Software”), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall
 * be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

using ThiefMD;
using ThiefMD.Widgets;
using ThiefMD.Controllers;
using ThiefMD.Exporters;

namespace ThiefMD.Connections {
    public class MediumConnection : ConnectionBase {
        public const string CONNECTION_TYPE = "medium";
        public override string export_name { get; protected set; }
        public override ExportBase exporter { get; protected  set; }
        public Medium.Client connection;
        private string access_token;
        private string alias;
        public string conf_endpoint;
        public string conf_alias;

        public MediumConnection (string username, string password, string endpoint = "https://api.medium.com/v1/") {
            conf_alias = username;
            conf_endpoint = endpoint;
            string api_endpoint = conf_endpoint;

            connection = new Medium.Client ();
            alias = "";

            try {
                connection.authenticate (username, password, out access_token);
                string temp;
                if (connection.get_authenticated_user (out temp)) {
                    alias = temp;
                    export_name = "https://medium.com/" + alias;
                    exporter = new MediumExporter (connection);
                }
            } catch (Error e) {
                warning ("Could not establish connection: %s", e.message);
            }
        }

        public override bool connection_valid () {
            if (connection.get_authenticated_user (out alias)) {
                return true;
            }

            return false;
        }

        public override void connection_close () {
        }

        public static ConnectionData? create_connection (Gtk.Window? parent) {
            Gtk.Grid grid = new Gtk.Grid ();
            grid.margin = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.hexpand = true;
            grid.vexpand = true;

            Gtk.Label username_label = new Gtk.Label (_("Username"));
            username_label.xalign = 0;
            Gtk.Entry username_entry = new Gtk.Entry ();

            Gtk.Label password_label = new Gtk.Label ("<a href='https://medium.com/me/settings'>" + _("Integration Token") + "</a>");
            password_label.use_markup = true;
            password_label.xalign = 0;
            Gtk.Entry password_entry = new Gtk.Entry ();
            password_entry.set_visibility (false);

            grid.attach (username_label, 1, 1, 1, 1);
            grid.attach (username_entry, 2, 1, 2, 1);
            grid.attach (password_label, 1, 2, 1, 1);
            grid.attach (password_entry, 2, 2, 2, 1);

            grid.show_all ();

            var dialog = new Gtk.Dialog.with_buttons (
                            _("New Medium Connection"),
                            (parent != null) ? parent : ThiefApp.get_instance (),
                            Gtk.DialogFlags.MODAL,
                            _("_Add Account"),
                            Gtk.ResponseType.ACCEPT,
                            _("_Cancel"),
                            Gtk.ResponseType.REJECT,
                            null);

            dialog.get_content_area ().add (grid);

            ConnectionData data = null;

            dialog.response.connect ((response_id) => {
                if (response_id == Gtk.ResponseType.ACCEPT) {
                    debug ("Data from callback");
                    data = new ConnectionData ();
                    data.connection_type = CONNECTION_TYPE;
                    data.user = username_entry.text;
                    data.auth = password_entry.text;
                    data.endpoint = "https://api.medium.com/v1/";
                }
                dialog.destroy ();
            });
            if (dialog.run () == Gtk.ResponseType.ACCEPT) {
                debug ("Data from block");
                data = new ConnectionData ();
                data.connection_type = CONNECTION_TYPE;
                data.user = username_entry.text;
                data.auth = password_entry.text;
                data.endpoint = "https://api.medium.com/v1/";
            }

            return data;
        }
    }

    private class MediumExporter : ExportBase {
        public override string export_name { get; protected set; }
        public override string export_css { get; protected set; }
        private PublisherPreviewWindow publisher_instance;
        public Medium.Client connection;
        private Gtk.ComboBoxText publish_state;

        public MediumExporter (Medium.Client connected) {
            export_name = "medium";
            export_css = "preview";
            connection = connected;

            publish_state = new Gtk.ComboBoxText ();
            publish_state.append_text ("draft");
            publish_state.append_text ("public");
            publish_state.append_text ("unlisted");
            publish_state.set_active (0);
        }

        public override string update_markdown (string markdown) {
            return markdown;
        }

        public override void attach (PublisherPreviewWindow ppw) {
            publisher_instance = ppw;
            publisher_instance.headerbar.pack_end (publish_state);
            return;
        }

        public override void detach () {
            publisher_instance.headerbar.remove (publish_state);
            publisher_instance = null;
            return;
        }

        public override bool export () {
            bool non_collected_post = true;
            bool published = false;
            string temp;
            string title;
            string date;
            string url = "";
            string id = "";
            Gee.Map<string, string> metadata = FileManager.get_yaml_kvp (publisher_instance.get_export_markdown ());
            string body = FileManager.get_yamlless_markdown (
                publisher_instance.get_export_markdown (),
                0,
                out title,
                out date,
                true,
                false, // Override as theme will probably display?
                false);

            if (metadata.has_key ("bibliography")) {
                body = publisher_instance.get_export_markdown ();
            }

            if (metadata.has_key ("title")) {
                title = metadata.get ("title");
            }

            Gee.Map<string, string> images_to_upload = Pandoc.file_image_map (publisher_instance.get_export_markdown ());
            Gee.HashMap<string, string> replacements = new Gee.HashMap<string, string> ();

            Gee.List<string> mediumSaying = new Gee.LinkedList<string> ();
            mediumSaying.add(_("You're writing is kind of... medium..."));
            mediumSaying.add(_("So hip, so cool, so medium"));
            mediumSaying.add(_("Taking your writing to the mainstream"));

            if (images_to_upload.keys.size > 0) {
                Thinking worker = new Thinking (_("Uploading images"), () => {
                    foreach (var images in images_to_upload) {
                        File img_file = File.new_for_path (images.value);
                        if (img_file.query_exists () && !FileUtils.test (images.value, FileTest.IS_DIR)) {
                            string upload_url;
                            if (connection.upload_image_simple (
                                out upload_url,
                                img_file.get_path ()))
                            {
                                replacements.set (images.key, upload_url);
                            } else {
                                warning ("Could not upload image %s", img_file.get_basename ());
                            }
                        }
                    }
                },
                mediumSaying,
                publisher_instance);
                worker.run ();
            }

            foreach (var replacement in replacements) {
                body = body.replace ("(" + replacement.key, "(" + replacement.value);
                body = body.replace ("\"" + replacement.key, "\"" + replacement.value);
                body = body.replace ("'" + replacement.key, "'" + replacement.value);
                warning ("Replaced %s with %s", replacement.key, replacement.value);
            }

            string published_state = publish_state.get_active_text ();

            if (metadata.has_key ("bibliography")) {
                string html = "";
                generate_html (body, out html);
                body = html;
            }

            // Unauthenticated post
            if (connection.publish_post (
                out url,
                out id,
                body,
                title,
                published_state,
                metadata.has_key ("bibliography") ? "html" : "markdown"))
            {
                published = true;
            }

            if (published) {
                Gtk.Label label = new Gtk.Label (
                    "<b>Post URL:</b> <a href='%s'>%s</a>\nID: %s\n".printf (
                        url,
                        url,
                        id));

                label.xalign = 0;
                label.use_markup = true;
                PublishedStatusWindow status = new PublishedStatusWindow (
                    publisher_instance,
                    (title != "") ? title + _(" Published") : _("Post Published"),
                    label);

                status.run ();
            }

            return published;
        }
    }
}