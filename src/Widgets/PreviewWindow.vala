using WebKit;
using ThiefMD;
using ThiefMD.Controllers;

namespace ThiefMD.Widgets {
    public class PreviewWindow : Gtk.Application {
        private static PreviewWindow? instance = null;
        Preview preview;
        public Gtk.ApplicationWindow window;

        public static void update_preview_title ()
        {
            var settings = AppSettings.get_default ();
            if (instance != null)
            {
                if (settings.show_filename && settings.last_file != "") {
                    string file_name = settings.last_file.substring(settings.last_file.last_index_of("/") + 1);
                    instance.window.title = "Preview: " + file_name;
                } else {
                    instance.window.title = "Preview";
                }
            }
        }

        public static PreviewWindow get_instance () {
            return instance;
        }

        protected override void activate () {
            window = new Gtk.ApplicationWindow (this);
            var settings = AppSettings.get_default ();
            int w, h, m, p;

            if (settings.show_filename && settings.last_file != "") {
                string file_name = settings.last_file.substring(settings.last_file.last_index_of("/") + 1);
                window.title = "Preview: " + file_name;
            } else {
                window.title = "Preview";
            }


            ThiefApp.get_instance ().main_window.get_size (out w, out h);

            w = w - ThiefApp.get_instance ().pane_position;

            window.set_default_size(w, h - 150);

            window.add (Preview.get_instance ());
            window.show_all ();

            window.delete_event.connect (this.on_delete_event);
            instance = this;
        }

        public bool on_delete_event () {
            window.remove (Preview.get_instance ());
            window.show_all ();
            instance = null;

            return false;
        }
    }
}
