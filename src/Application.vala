using ThiefMD;

public class ThiefApp : Gtk.Application {

    public ThiefApp () {
        Object (
            application_id: "com.github.kmwallio.theifmd",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var main_window = new Gtk.ApplicationWindow (this);
        var toolbar = new Widgets.Headerbar();
        main_window.set_titlebar(toolbar);
        main_window.default_height = 300;
        main_window.default_width = 300;
        main_window.title = "ThiefMD";
        main_window.show_all ();
    }

    public static int main (string[] args) {
        var app = new ThiefApp ();
        return app.run (args);
    }
}
