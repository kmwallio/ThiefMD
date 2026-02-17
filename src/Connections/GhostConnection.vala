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
    public class GhostConnection : ConnectionBase {
        public const string CONNECTION_TYPE = "ghost";
        public override string export_name { get; protected set; }
        public override ExportBase exporter { get; protected  set; }
        public Ghost.Client connection;
        private string alias;
        public string conf_endpoint;
        public string conf_alias;
        bool authenticated = false;

        public GhostConnection (string username, string password, string endpoint) {
            connection = new Ghost.Client (endpoint, username, password);
            alias = "";
            conf_endpoint = endpoint;
            conf_alias = username;

            if (connection.authenticate ()) {
                // Check if 2FA is required
                if (connection.requires_2fa) {
                    if (prompt_for_2fa ()) {
                        setup_connection (endpoint, username);
                    } else {
                        warning ("2FA verification failed");
                    }
                } else {
                    setup_connection (endpoint, username);
                }
            } else {
                warning ("Could not establish connection");
            }
        }

        private void setup_connection (string endpoint, string username) {
            string label = endpoint.down ();
            if (label.has_prefix ("https://")) {
                label = endpoint.substring (8);
            } else if (endpoint.has_prefix ("http://")) {
                label = endpoint.substring (7);
            }
            if (!label.has_suffix ("/")) {
                label += "/";
            }
            label = label.substring (0, 1).up () + label.substring (1).down ();
            export_name = label + username.substring (0, username.index_of ("@"));
            exporter = new GhostExporter (connection);
            authenticated = true;
        }

        private bool prompt_for_2fa () {
            bool verified = false;
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

            Gtk.Label code_label = new Gtk.Label (_("Enter verification code from your authenticator app"));
            code_label.xalign = 0;
            code_label.wrap = true;

            Gtk.Entry code_entry = new Gtk.Entry ();
            code_entry.placeholder_text = "000000";
            code_entry.max_width_chars = 6;

            grid.attach (code_label, 1, 1, 2, 1);
            grid.attach (code_entry, 1, 2, 2, 1);

            var dialog = new Gtk.Dialog.with_buttons (
                            _("Two-Factor Authentication Required"),
                            ThiefApp.get_instance (),
                            Gtk.DialogFlags.MODAL,
                            _("_Verify"),
                            Gtk.ResponseType.ACCEPT,
                            _("_Cancel"),
                            Gtk.ResponseType.REJECT,
                            null);

            dialog.get_content_area ().append (grid);

            var loop = new GLib.MainLoop ();
            dialog.response.connect ((response_id) => {
                if (response_id == Gtk.ResponseType.ACCEPT) {
                    debug ("Attempting 2FA verification");
                    if (connection.verify_session (code_entry.text)) {
                        verified = true;
                        debug ("2FA verification successful");
                    } else {
                        warning ("2FA verification failed");
                    }
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

            return verified;
        }

        public override bool connection_valid () {
            return authenticated;
        }

        public override void connection_close () {
            // Void
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

            Gtk.Label username_label = new Gtk.Label (_("E-mail"));
            username_label.xalign = 0;
            Gtk.Entry username_entry = new Gtk.Entry ();

            Gtk.Label password_label = new Gtk.Label (_("Password"));
            password_label.xalign = 0;
            Gtk.Entry password_entry = new Gtk.Entry ();
            password_entry.set_visibility (false);

            Gtk.Label endpoint_label = new Gtk.Label (_("Endpoint"));
            endpoint_label.xalign = 0;
            Gtk.Entry endpoint_entry = new Gtk.Entry ();
            endpoint_entry.placeholder_text = "https://my.ghost.org/";

            grid.attach (username_label, 1, 1, 1, 1);
            grid.attach (username_entry, 2, 1, 2, 1);
            grid.attach (password_label, 1, 2, 1, 1);
            grid.attach (password_entry, 2, 2, 2, 1);
            grid.attach (endpoint_label, 1, 3, 1, 1);
            grid.attach (endpoint_entry, 2, 3, 2, 1);

            var dialog = new Gtk.Dialog.with_buttons (
                            _("New ghost Connection"),
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
                    // Try to authenticate and get the session cookie
                    Ghost.Client temp_client = new Ghost.Client (
                        endpoint_entry.text,
                        username_entry.text,
                        password_entry.text);

                    if (temp_client.authenticate ()) {
                        // Check if 2FA is required
                        if (temp_client.requires_2fa) {
                            // Create 2FA dialog
                            Gtk.Grid twofa_grid = new Gtk.Grid ();
                            twofa_grid.margin_top = 12;
                            twofa_grid.margin_bottom = 12;
                            twofa_grid.margin_start = 12;
                            twofa_grid.margin_end = 12;
                            twofa_grid.row_spacing = 12;
                            twofa_grid.column_spacing = 12;
                            twofa_grid.orientation = Gtk.Orientation.VERTICAL;
                            twofa_grid.hexpand = true;
                            twofa_grid.vexpand = true;

                            Gtk.Label code_label = new Gtk.Label (_("Enter verification code from your authenticator app"));
                            code_label.xalign = 0;
                            code_label.wrap = true;

                            Gtk.Entry code_entry = new Gtk.Entry ();
                            code_entry.placeholder_text = "000000";
                            code_entry.max_width_chars = 6;

                            twofa_grid.attach (code_label, 1, 1, 2, 1);
                            twofa_grid.attach (code_entry, 1, 2, 2, 1);

                            var twofa_dialog = new Gtk.Dialog.with_buttons (
                                            _("Two-Factor Authentication Required"),
                                            ThiefApp.get_instance (),
                                            Gtk.DialogFlags.MODAL,
                                            _("_Verify"),
                                            Gtk.ResponseType.ACCEPT,
                                            _("_Cancel"),
                                            Gtk.ResponseType.REJECT,
                                            null);

                            twofa_dialog.get_content_area ().append (twofa_grid);

                            bool twofa_verified = false;
                            var twofa_loop = new GLib.MainLoop ();
                            twofa_dialog.response.connect ((twofa_response_id) => {
                                if (twofa_response_id == Gtk.ResponseType.ACCEPT) {
                                    debug ("Attempting 2FA verification");
                                    if (temp_client.verify_session (code_entry.text)) {
                                        twofa_verified = true;
                                        debug ("2FA verification successful");
                                    } else {
                                        warning ("2FA verification failed");
                                    }
                                }
                                twofa_dialog.destroy ();
                                twofa_loop.quit ();
                            });

                            twofa_dialog.close_request.connect (() => {
                                twofa_loop.quit ();
                                return false;
                            });

                            twofa_dialog.present ();
                            twofa_loop.run ();

                            if (twofa_verified) {
                                // 2FA verification successful, extract session cookie
                                string? session_cookie = temp_client.get_session_cookie ();
                                data = new ConnectionData ();
                                data.connection_type = CONNECTION_TYPE;
                                data.user = username_entry.text;
                                // Store cookie with "cookie:" prefix to distinguish from password
                                data.auth = session_cookie != null ? "cookie:" + session_cookie : password_entry.text;
                                data.endpoint = endpoint_entry.text;
                            } else {
                                warning ("2FA verification failed");
                            }
                        } else {
                            // Authentication successful, extract session cookie
                            string? session_cookie = temp_client.get_session_cookie ();
                            data = new ConnectionData ();
                            data.connection_type = CONNECTION_TYPE;
                            data.user = username_entry.text;
                            // Store cookie with "cookie:" prefix to distinguish from password
                            data.auth = session_cookie != null ? "cookie:" + session_cookie : password_entry.text;
                            data.endpoint = endpoint_entry.text;
                        }
                    } else {
                        warning ("Failed to authenticate with Ghost");
                    }
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

    private class GhostExporter : ExportBase {
        public override string export_name { get; protected set; }
        public override string export_css { get; protected set; }
        private PublisherPreviewWindow publisher_instance;
        public Ghost.Client connection;
        private Gtk.ComboBoxText publish_state;

        public GhostExporter (Ghost.Client connected) {
            export_name = "Ghost";
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

        public override bool export () {
            bool published = false;
            string title;
            string date;
            string slug = "";
            string id = "";
            string html = "";
            string featured_image = "";

            debug ("Exporting");

            Gee.Map<string, string> images_to_upload = Pandoc.file_image_map (publisher_instance.get_export_markdown ());
            Gee.HashMap<string, string> replacements = new Gee.HashMap<string, string> ();

            Gee.List<string> ghostSayings = new Gee.LinkedList<string> ();
            ghostSayings.add(_("Your words are like Casper... Friendly!"));
            ghostSayings.add(_("I see your words, and I'm taking them to the internet!"));
            ghostSayings.add(_("Booooooooooo! (That's Ghost speak for Great Work!)"));

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
                ghostSayings,
                publisher_instance);
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

            if (metadata.has_key ("bibliography")) {
                body = publisher_instance.get_export_markdown ();
            }

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
                debug ("Replaced %s with %s", replacement.key, replacement.value);
            }

            int published_state = publish_state.get_active ();
            bool immediately_publish = (published_state == 1);

            if (generate_html (body, out html)) {
                // Simple post
                if (connection.create_post_simple (
                    out slug,
                    out id,
                    title,
                    html,
                    immediately_publish,
                    featured_image.has_prefix ("http") ? featured_image : ""))
                {
                    published = true;
                    debug ("Posted");
                    Gtk.Label label = new Gtk.Label (
                        "<b>Post URL:</b> <a href='%s'>%s</a>\nAdmin: <a href='%s'>%s</a>".printf (
                            connection.endpoint + slug, connection.endpoint + slug,
                            connection.endpoint + "ghost/#/editor/post/" + id, connection.endpoint + "ghost/#/editor/post/" + id));

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