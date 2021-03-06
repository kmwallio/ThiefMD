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
    public class WordpressConnection : ConnectionBase {
        public const string CONNECTION_TYPE = "wordpress";
        public override string export_name { get; protected set; }
        public override ExportBase exporter { get; protected  set; }
        public Wordpress.Client connection;
        private string alias;
        public string conf_endpoint;
        public string conf_alias;
        bool authenticated = false;

        public WordpressConnection (string username, string password, string endpoint) {
            connection = new Wordpress.Client (endpoint, username, password);
            alias = "";
            conf_endpoint = endpoint;
            conf_alias = username;

            if (connection.authenticate ()) {
                string label = endpoint.down ();
                if (label.has_prefix ("https://")) {
                    label = endpoint.substring (8);
                } else if (endpoint.has_prefix ("http://")) {
                    label = endpoint.substring (7);
                }
                if (label.has_suffix (".php")) {
                    label = endpoint.substring (0, endpoint.last_index_of_char('/'));
                }
                if (!label.has_suffix ("/")) {
                    label += "/";
                }
                label = label.substring (0, 1).up () + label.substring (1).down ();
                export_name = label + username;
                exporter = new WordpressExporter (connection);
                authenticated = true;
            } else {
                warning ("Could not establish connection");
            }
        }

        public override bool connection_valid () {
            return authenticated;
        }

        public override void connection_close () {
            // Void
        }

        public static ConnectionData? create_connection (Gtk.Window? parent = null) {
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
            endpoint_entry.placeholder_text = "https://my.wordpress.org/";

            grid.attach (username_label, 1, 1, 1, 1);
            grid.attach (username_entry, 2, 1, 2, 1);
            grid.attach (password_label, 1, 2, 1, 1);
            grid.attach (password_entry, 2, 2, 2, 1);
            grid.attach (endpoint_label, 1, 3, 1, 1);
            grid.attach (endpoint_entry, 2, 3, 2, 1);

            grid.show_all ();

            var dialog = new Gtk.Dialog.with_buttons (
                            "New Wordpress Connection",
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

    private class WordpressExporter : ExportBase {
        public override string export_name { get; protected set; }
        public override string export_css { get; protected set; }
        private PublisherPreviewWindow publisher_instance;
        public Wordpress.Client connection;
        private Gtk.ComboBoxText publish_state;

        public WordpressExporter (Wordpress.Client connected) {
            export_name = "Wordpress";
            export_css = "preview";
            connection = connected;

            publish_state = new Gtk.ComboBoxText ();
            publish_state.append_text ("Draft");
            publish_state.append_text ("Published");
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

        private bool generate_html (string raw_mk, out string processed_mk) {
            processed_mk = raw_mk;
            var mkd = new Markdown.Document.from_gfm_string (processed_mk.data,
                Markdown.DocumentFlags.TOC + 
                Markdown.DocumentFlags.AUTOLINK + Markdown.DocumentFlags.EXTRA_FOOTNOTE + 
                Markdown.DocumentFlags.AUTOLINK + Markdown.DocumentFlags.DLEXTRA + 
                Markdown.DocumentFlags.FENCEDCODE + Markdown.DocumentFlags.GITHUBTAGS + 
                Markdown.DocumentFlags.LATEX + Markdown.DocumentFlags.URLENCODEDANCHOR + 
                Markdown.DocumentFlags.NOSTYLE + Markdown.DocumentFlags.EXPLICITLIST);

            mkd.compile (
                Markdown.DocumentFlags.TOC + Markdown.DocumentFlags.AUTOLINK + 
                Markdown.DocumentFlags.EXTRA_FOOTNOTE + 
                Markdown.DocumentFlags.AUTOLINK + Markdown.DocumentFlags.DLEXTRA +
                Markdown.DocumentFlags.FENCEDCODE + Markdown.DocumentFlags.GITHUBTAGS +
                Markdown.DocumentFlags.LATEX + Markdown.DocumentFlags.URLENCODEDANCHOR +
                Markdown.DocumentFlags.EXPLICITLIST + Markdown.DocumentFlags.NOSTYLE);
            mkd.get_document (out processed_mk);

            return (processed_mk.chomp () != "");
        }

        public override bool export () {
            bool published = false;
            string title;
            string date;
            string id = "";
            string html = "";
            string featured_image = "";

            debug ("Exporting");

            Gee.Map<string, string> images_to_upload = Pandoc.file_image_map (publisher_instance.get_export_markdown ());
            Gee.HashMap<string, string> replacements = new Gee.HashMap<string, string> ();

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
                                warning ("Could not upload image");
                            }
                        }
                    }
                });
                worker.run ();
            }

            Gee.Map<string, string> metadata = FileManager.get_yaml_kvp (publisher_instance.get_export_markdown ());

            string body = FileManager.get_yamlless_markdown (
                    publisher_instance.get_export_markdown (),
                    0,
                    out title,
                    out date,
                    true,
                    false, // Override instead of use settings as theme will display
                    false);

            if (metadata.has_key ("title")) {
                title = metadata.get ("title");
            }

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
            }

            debug ("Read title: %s", title);

            foreach (var replacement in replacements) {
                body = body.replace ("(" + replacement.key, "(" + replacement.value);
                body = body.replace ("\"" + replacement.key, "\"" + replacement.value);
                body = body.replace ("'" + replacement.key, "'" + replacement.value);

                if (featured_image == replacement.key) {
                    featured_image = replacement.value;
                }
                warning ("Replaced %s with %s", replacement.key, replacement.value);
            }

            int published_state = publish_state.get_active ();
            bool immediately_publish = (published_state == 1);

            if (generate_html (body, out html)) {
                // Simple post
                if (connection.create_post_simple (
                    out id,
                    title,
                    html,
                    immediately_publish,
                    featured_image.has_prefix ("http") ? featured_image : ""))
                {
                    published = true;
                    debug ("Posted");
                    Gtk.Label label = new Gtk.Label (
                        "<b>Post URL:</b> <a href='%s'>%s</a>".printf (
                            connection.endpoint.substring (0, connection.endpoint.last_index_of_char  ('/')) + "/?p=" + id,
                            connection.endpoint.substring (0, connection.endpoint.last_index_of_char  ('/')) + "/?p=" + id));

                    label.xalign = 0;
                    label.use_markup = true;
                    PublishedStatusWindow status = new PublishedStatusWindow (
                        publisher_instance,
                        (title != "") ? title + _(" Published") : _("Post Published"),
                        label);

                    status.run ();
                } else {
                    warning ("Hit error");
                }
            }

            return published;
        }
    }
}