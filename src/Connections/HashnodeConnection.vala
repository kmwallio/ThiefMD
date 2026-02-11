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
    public class HashnodeConnection : ConnectionBase {
        public const string CONNECTION_TYPE = "hashnode";
        public override string export_name { get; protected set; }
        public override ExportBase exporter { get; protected  set; }
        public Hashnode.Client connection;
        private string access_token;
        private string alias;
        public string conf_endpoint;
        public string conf_alias;

        public HashnodeConnection (string username, string password, string domain) {
            conf_alias = domain;
            conf_endpoint = domain;

            connection = new Hashnode.Client ();

            if (conf_alias.chug ().chomp () == "") {
                string q_domain = "";
                string pub_id = "";
                if (connection.get_user_information (username, out pub_id, out q_domain)) {
                    conf_alias = "%s/%s".printf(q_domain, username);
                } else {
                    conf_alias = "%s@hashnode".printf(username);
                }
            }

            try {
                connection.authenticate (username, password);
                export_name = conf_alias;
                exporter = new HashnodeExporter (connection);
            } catch (Error e) {
                warning ("Could not establish connection: %s", e.message);
            }
        }

        public override bool connection_valid () {
            return true;
        }

        public override void connection_close () {
        }

        public static ConnectionData? create_connection (Gtk.Window? parent) {
            Gtk.Grid grid = new Gtk.Grid ();
            grid.margin_top = 12;
            grid.margin_bottom = 12;
            grid.margin_start = 12;
            grid.margin_end = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.hexpand = true;
            grid.vexpand = true;

            Gtk.Label username_label = new Gtk.Label (_("Username or Publication ID"));
            username_label.xalign = 0;
            Gtk.Entry username_entry = new Gtk.Entry ();

            Gtk.Label password_label = new Gtk.Label ("<a href='https://hashnode.com/settings/developer'>" + _("Access Token") + "</a>");
            password_label.xalign = 0;
            password_label.use_markup = true;
            Gtk.Entry password_entry = new Gtk.Entry ();
            password_entry.set_visibility (false);

            Gtk.Label endpoint_label = new Gtk.Label (_("Display Name"));
            endpoint_label.xalign = 0;
            Gtk.Entry endpoint_entry = new Gtk.Entry ();
            endpoint_entry.placeholder_text = "username.hashnode.com";

            username_entry.editing_done.connect (() => {
                if (endpoint_entry.text.chug ().chomp () == "") {
                    Hashnode.Client client = new Hashnode.Client();
                    if (username_entry.text.chug ().chomp () == "") {
                        string domain = "";
                        string pub_id = "";
                        if (client.get_user_information (username_entry.text, out pub_id, out domain)) {
                            endpoint_entry.placeholder_text = "%s/%s".printf(domain, username_entry.text);
                        } else {
                            endpoint_entry.placeholder_text = "%s@hashnode".printf(username_entry.text);
                        }
                    }
                }
            });

            grid.attach (username_label, 1, 1, 1, 1);
            grid.attach (username_entry, 2, 1, 2, 1);
            grid.attach (password_label, 1, 2, 1, 1);
            grid.attach (password_entry, 2, 2, 2, 1);
            grid.attach (endpoint_label, 1, 3, 1, 1);
            grid.attach (endpoint_entry, 2, 3, 2, 1);

            var dialog = new Gtk.Dialog.with_buttons (
                            _("New Hashnode Connection"),
                            (parent != null) ? parent : ThiefApp.get_instance (),
                            Gtk.DialogFlags.MODAL,
                            _("_Add Account"),
                            Gtk.ResponseType.ACCEPT,
                            _("_Cancel"),
                            Gtk.ResponseType.REJECT,
                            null);

            dialog.get_content_area ().append (grid);

            ConnectionData data = null;

            var loop = new GLib.MainLoop ();
            dialog.response.connect ((response_id) => {
                if (response_id == Gtk.ResponseType.ACCEPT) {
                    debug ("Data from callback");
                    data = new ConnectionData ();
                    data.connection_type = CONNECTION_TYPE;
                    data.user = username_entry.text;
                    data.auth = password_entry.text;
                    data.endpoint = endpoint_entry.text;
                }
                dialog.destroy ();
                loop.quit ();
            });
            dialog.close_request.connect (() => {
                loop.quit ();
                return false;
            });

            dialog.present ();
            loop.run ();

            return data;
        }
    }

    private class HashnodeExporter : ExportBase {
        public override string export_name { get; protected set; }
        public override string export_css { get; protected set; }
        private PublisherPreviewWindow publisher_instance;
        public Hashnode.Client connection;

        public HashnodeExporter (Hashnode.Client connected) {
            export_name = "hashnode";
            export_css = "preview";
            connection = connected;
        }

        public override string update_markdown (string markdown) {
            return markdown;
        }

        public override void attach (PublisherPreviewWindow ppw) {
            publisher_instance = ppw;
            return;
        }

        public override void detach () {
            publisher_instance = null;
            return;
        }

        public override bool export () {
            bool non_collected_post = true;
            bool published = false;
            string temp;
            string title = "";
            string date;
            string url = "";
            string id = "";
            string body = FileManager.get_yamlless_markdown (
                publisher_instance.get_export_markdown (),
                0,
                out title,
                out date,
                true,
                false, // Override instead of use settings as theme will display
                false);

            warning ("Hashnode exporting");

            Gee.Map<string, string> images_to_upload = Pandoc.file_image_map (publisher_instance.get_export_markdown ());
            Gee.HashMap<string, string> replacements = new Gee.HashMap<string, string> ();

            bool good_to_go = true;
            if (images_to_upload.keys.size > 0) {
                foreach (var images in images_to_upload) {
                    File img_file = File.new_for_path (images.value);
                    if (img_file.query_exists () && !FileUtils.test (images.value, FileTest.IS_DIR)) {
                        good_to_go = false;
                    }
                }
            }

            if (good_to_go) {
                Gee.Map<string, string> metadata = FileManager.get_yaml_kvp (publisher_instance.get_export_markdown ());
                string featured_image = "";
                if (metadata.has_key ("cover-image")) { // Consistency for ePub cover-image
                    featured_image = metadata.get ("cover-image");
                } else if (metadata.has_key ("feature_image")) { // What ghost API documents
                    featured_image = metadata.get ("feature_image");
                } else if (metadata.has_key ("coverimage")) { // Misc. things I'll try and wonder why they didn't work
                    featured_image = metadata.get ("coverimage");
                } else if (metadata.has_key ("featureimage")) {
                    featured_image = metadata.get ("featureimage");
                } else if (metadata.has_key ("featuredimage")) {
                    featured_image = metadata.get ("featureimage");
                } else if (metadata.has_key ("featured-image")) {
                    featured_image = metadata.get ("featureimage");
                } else if (metadata.has_key ("cover_image")) { // What ghost API documents
                    featured_image = metadata.get ("cover_image");
                }
                featured_image = featured_image.chomp ().chug ();
                if (!featured_image.has_prefix ("http")) {
                    featured_image = "";
                }

                Gee.List<string> hashnodeSayings = new Gee.LinkedList<string> ();
                hashnodeSayings.add(_("Hashing words and nodes together."));
                hashnodeSayings.add(_("Don't forget to share on reddit."));
                hashnodeSayings.add(_("This looks like something worth sharing"));

                Thinking worker = new Thinking (_("Beaming to the Internet"), () => {
                    if (connection.publish_post (
                        out url,
                        out id,
                        body,
                        title,
                        featured_image))
                    {
                        published = true;
                    }
                }, hashnodeSayings, publisher_instance);
                worker.run ();
            } else {
                Gtk.Label label = new Gtk.Label (
                    _("Image uploads are not supported by Hashnode."));

                PublishedStatusWindow status = new PublishedStatusWindow (
                    publisher_instance,
                    _("Unsupported Format"),
                    label);

                status.run ();
            }

            if (published) {
                Gtk.Label label = new Gtk.Label (
                    "<b>Post URL:</b> <a href='%s'>%s</a>".printf (
                        url,
                        url));

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