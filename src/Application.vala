using ThiefMD;
using ThiefMD.Widgets;
using ThiefMD.Controllers;

namespace ThiefMD {
    public class ThiefApp : Gtk.Application {
        private static ThiefApp _instance;
        public Gtk.ApplicationWindow main_window;
        public Headerbar toolbar;
        public Gtk.ScrolledWindow edit_view;
        public Editor edit_view_content;
        public Library library;
        public Gtk.Paned sheets_pane;
        public Gtk.Paned library_pane;

        public ThiefApp () {
            Object (
                application_id: "com.github.kmwallio.theifmd",
                flags: ApplicationFlags.FLAGS_NONE
            );
        }

        public int pane_position {
            get {
                return sheets_pane.get_position ();
            }
        }

        public bool is_fullscreen {
            get {
                var settings = AppSettings.get_default ();
                return settings.fullscreen;
            }
            set {
                var settings = AppSettings.get_default ();
                settings.fullscreen = value;

                var toolbar_context = toolbar.get_style_context ();
                toolbar_context.add_class("thiefmd-toolbar");

                if (settings.fullscreen) {
                    main_window.fullscreen ();
                    settings.statusbar = false;
                    var buffer_context = edit_view_content.get_style_context ();
                    buffer_context.add_class ("full-text");
                    buffer_context.remove_class ("small-text");
                } else {
                    main_window.unfullscreen ();
                    settings.statusbar = true;
                    var buffer_context = edit_view_content.get_style_context ();
                    buffer_context.add_class ("small-text");
                    buffer_context.remove_class ("full-text");
                }
            }
        }

        protected override void activate () {
            var settings = AppSettings.get_default ();

            string start_dir = "";
            if (settings.last_file != "") {
                start_dir = settings.last_file.substring(0, settings.last_file.last_index_of("/"));
                debug ("Starting with %s\n", start_dir);
            }

            if (settings.library_list == "") {
                settings.add_to_library (start_dir);
            }

            main_window = new Gtk.ApplicationWindow (this);
            toolbar = new Headerbar ();
            edit_view_content = new Editor ();
            library = new Library ();
            sheets_pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            library_pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);

            edit_view = new Gtk.ScrolledWindow (null, null);
            edit_view.add (edit_view_content);

            library_pane.add1(library);
            Sheets start_sheet = library.get_sheets (start_dir);
            library_pane.add2(start_sheet);
            library_pane.set_position(settings.view_library_width);
            
            sheets_pane.add1(library_pane);
            sheets_pane.add2(edit_view);
            sheets_pane.set_position(settings.view_library_width + settings.view_sheets_width);


            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/com/github/kmwallio/thiefmd/app-main-stylesheet.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            main_window.set_titlebar (toolbar);
            if (settings.window_height < 600) {
                settings.window_height = 600;
            }
            if (settings.window_width < 800) {
                settings.window_width = 800;
            }
            main_window.default_height = settings.window_height;
            main_window.default_width = settings.window_width;
            main_window.title = "ThiefMD";
            main_window.add (sheets_pane);
            is_fullscreen = false;

            // Restore preview view
            UI.show_view ();

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