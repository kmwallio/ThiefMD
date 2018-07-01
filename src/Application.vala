using ThiefMD;
using ThiefMD.Widgets;
namespace ThiefMD {
    public class ThiefApp : Gtk.Application {
        private static ThiefApp _instance;
        public Gtk.ApplicationWindow main_window;
        public Headerbar toolbar;

        public ThiefApp () {
            Object (
                application_id: "com.github.kmwallio.theifmd",
                flags: ApplicationFlags.FLAGS_NONE
            );
        }

        protected override void activate () {
            var settings = AppSettings.get_default ();

            main_window = new Gtk.ApplicationWindow (this);
            toolbar = new Headerbar ();
            var pane = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
            
            pane.add1(new Sheets("/home/kmwallio/Dropbox/DnD/World"));
            pane.add2(new Editor());
            pane.set_position((int)(settings.window_width * 0.2));

            main_window.set_titlebar (toolbar);
            main_window.default_height = settings.window_height;
            main_window.default_width = settings.window_width;
            main_window.title = "ThiefMD";
            main_window.add (pane);
            main_window.show_all ();
        }

        public static ThiefApp get_instance () {
            return _instance;
        }

        public static int main (string[] args) {
            var app = new ThiefApp ();
            _instance = app;
            return app.run (args);
        }
    }
}