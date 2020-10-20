/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified September 6, 2020
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

using ThiefMD.Controllers;

namespace ThiefMD {
    errordomain ThiefError {
        FILE_NOT_FOUND,
        FILE_NOT_VALID_ARCHIVE,
        FILE_NOT_VALID_THEME
    }

    public class SecretAttr : Object {
        public string connection_type { get; set; }
        public string user { get; set; }
        public string endpoint { get; set; }
        public string secret { get; set; }
    }

    public class SecretAttributes : Object {
        public Gee.LinkedList<SecretAttr> secrets;

        public SecretAttributes () {
            secrets = new Gee.LinkedList<SecretAttr> ();
        }
    }

    public class SecretSchemas {
        private static SecretSchemas instance = null;
        public Secret.Schema writeas_secret;
        private SecretAttributes stored_secrets;
        private Secret.Collection collection;

        public SecretSchemas () {
            writeas_secret = new Secret.Schema (
                "com.kmwallio.thiefmd.Writeas", Secret.SchemaFlags.NONE,
                "endpoint", Secret.SchemaAttributeType.STRING,
                "alias", Secret.SchemaAttributeType.STRING);

            stored_secrets = new SecretAttributes ();
        }

        public static SecretSchemas get_instance () {
            if (instance == null) {
                instance = new SecretSchemas ();
            }

            return instance;
        }

        public async bool load_secrets () {
            warning ("Loading secrets");
            File secrets = File.new_for_path (UserData.connection_file);
            bool success = false;
            SecretAttributes attributes;
            if (!secrets.query_exists ()) {
                return true;
            }

            warning ("Found secrets");

            try {
                Json.Parser parser = new Json.Parser ();
                parser.load_from_file (secrets.get_path ());
                Json.Node data = parser.get_root ();
                var json_obj = parser.get_root ().get_object ();
                attributes = new SecretAttributes ();

                var secrets_data = json_obj.get_array_member ("secrets");

                if (secrets_data.get_length () > 0 && collection == null) {
                    yield load_collection ();
                }

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

                    if (s_p.has_member ("secret")) {
                        sec.secret = s_p.get_string_member ("secret");
                    }

                    warning ("Found secret: %s : %s", sec.connection_type, sec.user);

                    if (sec.connection_type == "writeas") {
                        var secattr = new GLib.HashTable<string,string> (str_hash, str_equal);
                        secattr["endpoint"] = sec.endpoint;
                        secattr["alias"] = sec.user;
                        warning ("Reading secret: %s : %s", sec.connection_type, sec.user);
                        try {
                            var password = yield Secret.password_lookupv (
                                writeas_secret,
                                secattr,
                                null);
                            if (password != null) {
                                warning ("Got secret: %s : %s", sec.connection_type, sec.user);
                                Connections.WriteasConnection writeas_connection = new Connections.WriteasConnection (sec.user, password, sec.endpoint);
                                Secret.password_wipe (password);

                                if (writeas_connection.connection_valid ()) {
                                    ThiefApp.get_instance ().exporters.register ("Write.as " + sec.user, writeas_connection.exporter);
                                    ThiefApp.get_instance ().connections.add (writeas_connection);
                                    stored_secrets.secrets.add (sec);
                                } else {
                                    yield Secret.password_clearv (
                                        writeas_secret,
                                        secattr,
                                        null);
                                }
                            } else {
                                warning ("Could not read secret: %s : %s", sec.connection_type, sec.user);
                            }
                        } catch (Error e) {
                            warning ("Error loading password: %s", e.message);
                        }
                    }
                }
            } catch (Error e) {
                warning ("Could not load connection file: %s", e.message);
                return false;
            }

            return true;
        }

        public bool save_secret (string type, string alias, string url) {
            bool success = false;

            debug ("Saving secret %s : %s", type, alias);

            SecretAttr new_sec = new SecretAttr ();
            new_sec.connection_type = type;
            new_sec.user = alias;
            new_sec.endpoint = url;
            stored_secrets.secrets.add (new_sec);

            return serialize_secrets ();
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
                var secattr = new GLib.HashTable<string,string> (str_hash, str_equal);
                secattr["endpoint"] = rem_sec.endpoint;
                secattr["alias"] = rem_sec.user;
                try {
                    Secret.password_clearv_sync (
                        writeas_secret,
                        secattr);

                } catch (Error e) {
                    warning ("Failure removing from keyring: %s", e.message);
                }
            }

            return serialize_secrets ();
        }

        private async void load_collection () {
            if (collection == null) {
                try {
                    warning ("Loading service");
                    var service = yield Secret.Service.get (Secret.ServiceFlags.LOAD_COLLECTIONS, null);
                    warning ("Checking for existing collection");
                    collection = yield Secret.Collection.for_alias (
                        service,
                        Constants.COLLECTION_THIEFMD,
                        Secret.CollectionFlags.LOAD_ITEMS,
                        null
                    );

                    warning ("Creating collection");
                    if (collection == null) {
                        warning ("Creating collection for real");
                        collection = yield Secret.Collection.create (
                            service,
                            "ThiefMD",
                            Constants.COLLECTION_THIEFMD,
                            0,
                            null
                        );
                    }
                } catch (Error e) {
                    warning ("Could not create link to collection: %s", e.message);
                }
            }
        }

        private bool serialize_secrets () {
            File secrets = File.new_for_path (UserData.connection_file);
            bool success = false;
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
                warning ("Saving to: %s", secrets.get_path ());

                Json.Generator generator = new Json.Generator ();
                Json.Node root = builder.get_root ();
                generator.set_root (root);

                warning (generator.to_data (null));

                FileManager.save_file (secrets, generator.to_data (null).data);
                success = true;
            } catch (Error e) {
                warning ("Could not serialize connection data: %s", e.message);
            }

            return success;
        }

        public async bool add_writeas_secret (string url, string alias, string password) {
            var attributes = new GLib.HashTable<string,string> (str_hash, str_equal);
            attributes["endpoint"] = url;
            attributes["alias"] = alias;

            if (collection == null) {
                yield create_collection ();
            }
            warning ("Saving secret to KeyStore %s : %s", url, alias);

            try {
                yield Secret.Item.create (
                    collection,
                    writeas_secret,
                    attributes,
                    "Writeas " + alias,
                    new Secret.Value (password, password.length, "text/plain"),
                    Secret.ItemCreateFlags.REPLACE,
                    null);

                save_secret ("writeas", alias, url);
            } catch (Error e) {
                warning ("Error storing password in keystore: %s", e.message);
            }

            return true;
        }
    }

    public string make_title (string text) {
        string current_title = text.replace ("_", " ");
        current_title = current_title.replace ("-", " ");
        string [] parts = current_title.split (" ");
        if (parts != null && parts.length != 0) {
            current_title = "";
            foreach (var part in parts) {
                part = part.substring (0, 1).up () + part.substring (1).down ();
                current_title += part + " ";
            }
            current_title = current_title.chomp ();
        }

        return current_title;
    }

    public string get_base_library_path (string path) {
        var settings = AppSettings.get_default ();
        if (path == null) {
            return "No file opened";
        }
        string res = path;
        foreach (var base_lib in settings.library ()) {
            if (res.has_prefix (base_lib)) {
                File f = File.new_for_path (base_lib);
                string base_chop = f.get_parent ().get_path ();
                res = res.substring (base_chop.length);
                if (res.has_prefix (Path.DIR_SEPARATOR_S)) {
                    res = res.substring (1);
                }
            }
        }

        return res;
    }

    public string csv_to_md (string csv) {
        StringBuilder b = new StringBuilder ();
        string[] lines = csv.split ("\n");
        int[] items = new int[lines.length];
        for (int l = 0; l < lines.length; l++) {
            string line = lines[l];
            string[] values = line.split (",");
            int j = 0;
            for (int i = 0; i < values.length; i++) {
                if (i == 0) {
                    b.append ("|");
                }
                string value = values[i];
                if (l == 0) {
                    items[j] = -1;
                }
                value = value.chomp ().chug ();
                if (value.has_prefix ("\"") && value.has_suffix ("\"")) {
                    value = value.substring (1, value.length - 2);
                    if (l == 0) {
                        items[j] = value.length;
                    }
                } else if (value.has_prefix ("\"")) {
                    string t;
                    do  {
                        t = values[i++];
                        if (l == 0) {
                            items[i] = -1;
                        }
                        value += t;
                    } while (!value.has_suffix ("\"") && i < values.length);
                    value = value.substring (1, value.length - 2);
                }
                b.append (value);
                if (l > 0) {
                    if (value.length < items[j]) {
                        for (int r = value.length; r < items[j]; r++) {
                            b.append (" ");
                        }
                    }
                }
                b.append ("|");
                j++;
            }
            b.append ("\n");
            if (l == 0) {
                b.append ("|");
                for (int k = 0; k < items.length && items[k] > 0; k++) {
                    for (int t = 0; t < items[k]; t++) {
                        b.append ("-");
                    }
                    b.append ("|");
                }
                b.append ("\n");
            }
        }

        return b.str;
    }

    public class TimedMutex {
        private bool can_action;
        private Mutex droptex;
        private int delay;

        public TimedMutex (int milliseconds_delay = 300) {
            if (milliseconds_delay < 100) {
                milliseconds_delay = 100;
            }

            delay = milliseconds_delay;
            can_action = true;
            droptex = Mutex ();
        }

        public bool can_do_action () {
            bool res = can_action;
            debug ("%s do action", res ? "CAN" : "CANNOT");

            if (can_action) {
                debug ("Acquiring lock");
                droptex.lock ();
                debug ("Lock acquired");
                can_action = false;
                Timeout.add (delay, clear_action);
                droptex.unlock ();
            }
            return res;
        }

        private bool clear_action () {
            droptex.lock ();
            can_action = true;
            droptex.unlock ();
            return false;
        }
    }
}