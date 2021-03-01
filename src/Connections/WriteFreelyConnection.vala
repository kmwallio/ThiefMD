/*
 * Copyright (C) 2020 kmwallio
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
    public class WriteFreelyConnection : ConnectionBase {
        public const string CONNECTION_TYPE = "writefreely";
        public override string export_name { get; protected set; }
        public override ExportBase exporter { get; protected  set; }
        public Writeas.Client connection;
        private string access_token;
        private string alias;
        public string conf_endpoint;
        public string conf_alias;

        public WriteFreelyConnection (string username, string password, string endpoint = "https://write.as/") {
            conf_endpoint = endpoint;
            conf_alias = username;
            conf_endpoint = endpoint;

            if (!(conf_endpoint.has_suffix ("api") || conf_endpoint.has_suffix ("api/"))) {
                if (conf_endpoint.has_suffix ("/")) {
                    conf_endpoint += "api/";
                } else {
                    conf_endpoint += "/api/";
                }
            }

            connection = new Writeas.Client (conf_endpoint);
            alias = "";

            try {
                connection.authenticate (username, password, out access_token);
                string temp;
                if (connection.get_authenticated_user (out temp)) {
                    alias = temp;
                    string label = endpoint.down ();
                    if (label.has_prefix ("https://")) {
                        label = endpoint.substring (8);
                    } else if (endpoint.has_prefix ("http://")) {
                        label = endpoint.substring (7);
                    }
                    if (label.has_suffix ("api/") || label.has_suffix ("api")) {
                        label = label.substring (0, label.last_index_of ("api"));
                    }
                    label = label.substring (0, 1).up () + label.substring (1).down ();
                    export_name = label + username;
                    exporter = new WriteFreelyExporter (connection);
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
            connection.logout ();
        }

        public static ConnectionData? create_connection () {
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

            Gtk.Label password_label = new Gtk.Label (_("Password"));
            password_label.xalign = 0;
            Gtk.Entry password_entry = new Gtk.Entry ();
            password_entry.set_visibility (false);

            Gtk.Label endpoint_label = new Gtk.Label (_("Endpoint"));
            endpoint_label.xalign = 0;
            Gtk.Entry endpoint_entry = new Gtk.Entry ();
            endpoint_entry.placeholder_text = "https://write.as/";

            grid.attach (username_label, 1, 1, 1, 1);
            grid.attach (username_entry, 2, 1, 2, 1);
            grid.attach (password_label, 1, 2, 1, 1);
            grid.attach (password_entry, 2, 2, 2, 1);
            grid.attach (endpoint_label, 1, 3, 1, 1);
            grid.attach (endpoint_entry, 2, 3, 2, 1);

            grid.show_all ();

            var dialog = new Gtk.Dialog.with_buttons (
                            "New WriteFreely Connection",
                            ThiefApp.get_instance (),
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
                    data.endpoint = endpoint_entry.text;
                }
                dialog.destroy ();
            });
            if (dialog.run () == Gtk.ResponseType.ACCEPT) {
                debug ("Data from block");
                data = new ConnectionData ();
                data.connection_type = CONNECTION_TYPE;
                data.user = username_entry.text;
                data.auth = password_entry.text;
                data.endpoint = endpoint_entry.text;
            }

            return data;
        }
    }

    private class WriteFreelyExporter : ExportBase {
        public override string export_name { get; protected set; }
        public override string export_css { get; protected set; }
        private PublisherPreviewWindow publisher_instance;
        public Writeas.Client connection;
        private GLib.List<Writeas.Collection> collections;
        private Gtk.ComboBoxText collection_selector;

        public WriteFreelyExporter (Writeas.Client connected) {
            export_name = "writefreely";
            export_css = "preview";
            connection = connected;
        }

        public override string update_markdown (string markdown) {
            return markdown;
        }

        public override void attach (PublisherPreviewWindow ppw) {
            publisher_instance = ppw;
            collections = new GLib.List<Writeas.Collection> ();
            if (connection.get_user_collections (ref collections)) {
                if (collections.length () > 0) {
                    collection_selector = new Gtk.ComboBoxText ();
                    collection_selector.hexpand = true;

                    foreach (var c in collections) {
                        collection_selector.append_text (c.alias);
                    }

                    collection_selector.set_active (0);
                    publisher_instance.headerbar.pack_end (collection_selector);
                }
            }
            return;
        }

        public override void detach () {
            if (collections.length () > 0) {
                collection_selector.set_active (0);
                publisher_instance.headerbar.remove (collection_selector);
                collection_selector = null;
            }
            publisher_instance = null;
            return;
        }

        public override bool export () {
            bool non_collected_post = true;
            bool published = true;
            string temp;
            string title;
            string date;
            string token = "";
            string id = "";
            Writeas.Collection publish_collection = null;
            string body = FileManager.get_yamlless_markdown (
                    publisher_instance.get_export_markdown (),
                    0,
                    out title,
                    out date,
                    true,
                    false, // Override as theme will probably display?
                    false);

            // Authenticated post
            if (collections.length () > 0 && connection.get_authenticated_user (out temp)) {
                int option = collection_selector.get_active ();
                if (option >= 0 && option < collections.length ()) {
                    publish_collection = collections.nth_data (option);
                    if (connection.publish_collection_post (
                        out token,
                        out id,
                        publish_collection.alias,
                        body,
                        title))
                    {
                        non_collected_post = false;
                        published = true;
                    }
                }
            }

            if (non_collected_post)
            {
                // Unauthenticated post
                if (connection.publish_post (
                    out token,
                    out id,
                    body,
                    title))
                {
                    published = true;
                }
            }

            if (published) {
                Gtk.Label label = new Gtk.Label (
                    "<b>Post URL:</b> <a href='%s'>%s</a>\nID: %s\nToken: %s\n".printf (
                        (non_collected_post) ? ("https://write.as/" + id) : (publish_collection.url + id),
                        (non_collected_post) ? ("https://write.as/" + id) : (publish_collection.url + id),
                        id,
                        token));

                Writeas.Post published_data;
                if (connection.get_post (out published_data, id) && published_data.slug != null && published_data.slug != "") {
                    label.set_text ("<b>Post URL:</b> <a href='%s'>%s</a>\nID: %s\nToken: %s\n".printf (
                        (non_collected_post) ? ("https://write.as/" + id) : (publish_collection.url + published_data.slug),
                        (non_collected_post) ? ("https://write.as/" + id) : (publish_collection.url + published_data.slug),
                        id,
                        token));
                }

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