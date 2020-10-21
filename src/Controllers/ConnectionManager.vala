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
using ThiefMD.Connections;

namespace ThiefMD.Controllers {

    public class SecretAttr : Object {
        public string connection_type { get; set; }
        public string user { get; set; }
        public string endpoint { get; set; }
    }

    public class SecretAttributes : Object {
        public Gee.ConcurrentList<SecretAttr> secrets;

        public SecretAttributes () {
            secrets = new Gee.ConcurrentList<SecretAttr> ();
        }
    }

    public class SecretSchemas {
        private static SecretSchemas instance = null;
        public Secret.Schema thief_secret;
        private SecretAttributes stored_secrets;
        private Secret.Collection collection;
        private Mutex save_secrets;

        public SecretSchemas () {
            thief_secret = new Secret.Schema (
                "com.kmwallio.thiefmd.secret", Secret.SchemaFlags.NONE,
                "type", Secret.SchemaAttributeType.STRING,
                "endpoint", Secret.SchemaAttributeType.STRING,
                "alias", Secret.SchemaAttributeType.STRING);

            stored_secrets = new SecretAttributes ();
            save_secrets = Mutex ();
        }

        public static SecretSchemas get_instance () {
            if (instance == null) {
                instance = new SecretSchemas ();
            }

            return instance;
        }

        public bool load_secrets () {
            debug ("Loading collections");
            File secrets = File.new_for_path (UserData.connection_file);
            bool success = false;
            if (!secrets.query_exists ()) {
                return true;
            }

            try {
                Json.Parser parser = new Json.Parser ();
                parser.load_from_file (secrets.get_path ());
                Json.Node data = parser.get_root ();
                var json_obj = parser.get_root ().get_object ();

                var secrets_data = json_obj.get_array_member ("secrets");

                foreach (var sec_elem in secrets_data.get_elements ()) {
                    var s_p = sec_elem.get_object ();
                    SecretAttr sec = new SecretAttr ();
                    sec.connection_type = "";
                    sec.user = "";
                    sec.endpoint = "";

                    if (s_p.has_member ("connection_type")) {
                        sec.connection_type = s_p.get_string_member ("connection_type");
                    }

                    if (s_p.has_member ("endpoint")) {
                        sec.endpoint = s_p.get_string_member ("endpoint");
                    }

                    if (s_p.has_member ("user")) {
                        sec.user = s_p.get_string_member ("user");
                    }

                    warning ("Found secret: %s : %s", sec.connection_type, sec.user);
                    var attributes = new GLib.HashTable<string,string> (str_hash, str_equal);
                    attributes["type"] = sec.connection_type;
                    attributes["endpoint"] = sec.endpoint;
                    attributes["alias"] = sec.user;

                    Secret.password_lookupv.begin (thief_secret, attributes, null, (obj, async_res) => {
                        try {
                            string? the_secret = Secret.password_lookup.end (async_res);
                            if (the_secret != null) {
                                warning ("Loaded secret: %s : %s", sec.connection_type, sec.user);
                                if (sec.connection_type == WriteasConnection.CONNECTION_TYPE) {
                                    WriteasConnection writeas_connection = new WriteasConnection (sec.user, the_secret, sec.endpoint);
                                    stored_secrets.secrets.add (sec);

                                    if (writeas_connection.connection_valid ()) {
                                        ThiefApp.get_instance ().exporters.register (writeas_connection.export_name, writeas_connection.exporter);
                                        ThiefApp.get_instance ().connections.add (writeas_connection);
                                    }
                                } else if (sec.connection_type == GhostConnection.CONNECTION_TYPE) {
                                    GhostConnection ghost_connection = new GhostConnection (sec.user, the_secret, sec.endpoint);
                                    stored_secrets.secrets.add (sec);

                                    if (ghost_connection.connection_valid ()) {
                                        ThiefApp.get_instance ().exporters.register (ghost_connection.export_name, ghost_connection.exporter);
                                        ThiefApp.get_instance ().connections.add (ghost_connection);
                                    }
                                }
                            }
                            Secret.password_wipe (the_secret);
                        } catch (Error e) {
                            warning ("Error loading from keyring: %s", e.message);
                        }
                    });
                }
            } catch (Error e) {
                warning ("Could not load connection file: %s", e.message);
                return false;
            }

            return true;
        }

        public void save_secret (string type, string alias, string url, string secret) {
            var attributes = new GLib.HashTable<string,string> (str_hash, str_equal);
            attributes["type"] = type;
            attributes["endpoint"] = url;
            attributes["alias"] = alias;

            warning ("Saving secret %s : %s", type, alias);
            Secret.password_storev.begin (
                thief_secret,
                attributes,
                Secret.COLLECTION_DEFAULT,
                "%s:%s".printf(url, alias),
                secret,
                null, (obj, async_res) =>
            {
                bool res = false;
                try {
                    res = Secret.password_store.end (async_res);
                } catch (Error e) {
                    warning ("Error with libsecret: %s", e.message);
                }
                if (res) {
                    warning ("Saved secret %s : %s", type, alias);
                    SecretAttr new_sec = new SecretAttr ();
                    new_sec.connection_type = type;
                    new_sec.user = alias;
                    new_sec.endpoint = url;
                    stored_secrets.secrets.add (new_sec);
                    serialize_secrets ();
                } else {
                    warning ("Could not save secret %s : %s", type, alias);
                }
            });
        }

        public bool remove_secret (string type, string alias, string url) {
            bool success = false;

            SecretAttr? rem_sec = null;
            foreach (var cur_sec in stored_secrets.secrets) {
                if (cur_sec.endpoint == url && cur_sec.user == alias && cur_sec.connection_type == type) {
                    rem_sec = cur_sec;
                }
            }

            if (rem_sec != null) {
                stored_secrets.secrets.remove (rem_sec);
                success = true;
            }

            return serialize_secrets ();
        }

        private bool serialize_secrets () {
            bool success = false;
            save_secrets.lock ();
            File secrets = File.new_for_path (UserData.connection_file);

            try {
                Json.Builder builder = new Json.Builder ();
                builder.begin_object ();
                builder.set_member_name ("secrets");
                builder.begin_array ();
                foreach (var sec in stored_secrets.secrets) {
                    warning ("Adding secrent: %s", sec.user);
                    builder.begin_object ();
                    builder.set_member_name ("connection_type");
                    builder.add_string_value (sec.connection_type);
                    builder.set_member_name ("user");
                    builder.add_string_value (sec.user);
                    builder.set_member_name ("endpoint");
                    builder.add_string_value (sec.endpoint);
                    builder.end_object ();
                }

                builder.end_array ();
                builder.end_object ();

                if (secrets.query_exists ()) {
                    secrets.delete ();
                }
                debug ("Saving to: %s", secrets.get_path ());

                Json.Generator generator = new Json.Generator ();
                Json.Node root = builder.get_root ();
                generator.set_root (root);

                FileManager.save_file (secrets, generator.to_data (null).data);
                success = true;
            } catch (Error e) {
                warning ("Could not serialize connection data: %s", e.message);
            }
            save_secrets.unlock ();
            return success;
        }

        public bool add_writeas_secret (string url, string alias, string password) {
            save_secret (WriteasConnection.CONNECTION_TYPE, alias, url, password);
            return true;
        }

        public bool add_ghost_secret (string url, string alias, string password) {
            save_secret (GhostConnection.CONNECTION_TYPE, alias, url, password);
            return true;
        }
    }
}