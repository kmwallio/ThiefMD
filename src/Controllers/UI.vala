using ThiefMD;
using ThiefMD.Widgets;

namespace ThiefMD.Controllers.UI {
    private bool _init = false;
    private bool _show_filename = false;

    // Returns the old sheets, but puts in the new one
    public Sheets set_sheets (Sheets sheet) {
        if (sheet == null) {
            return sheet;
        }
        ThiefApp instance = ThiefApp.get_instance ();
        var old = instance.library_pane.get_child2 ();
        int cur_pos = instance.library_pane.get_position ();
        instance.library_pane.remove (old);
        instance.library_pane.add2 (sheet);
        instance.library_pane.set_position (cur_pos);
        instance.library_pane.show_all ();
        return (Sheets) old;
    }

    public void toggle_view () {
        var settings = AppSettings.get_default ();
        ThiefApp instance = ThiefApp.get_instance ();

        if (!_init) {
            _init = true;
            _show_filename = settings.show_filename;
        }

        if (_moving) {
            return;
        }

        settings.view_state = (settings.view_state + 1) % 3;

        if (settings.view_state == 2) {
            settings.view_sheets_width = instance.sheets_pane.get_position ();
        } else if (settings.view_state == 1) {
            int target_sheets = instance.sheets_pane.get_position () - instance.library_pane.get_position ();
            settings.view_sheets_width = target_sheets;
            settings.view_library_width = instance.library_pane.get_position ();
        }

        show_view ();
    }

    public void show_view () {
        var settings = AppSettings.get_default ();

        if (!_init) {
            _init = true;
            _show_filename = settings.show_filename;
        }

        if (_moving) {
            return;
        }

        if (settings.view_state == 0) {
            settings.show_filename = _show_filename;

            if (settings.view_library_width <= 10) {
                settings.view_library_width = 200;
            }

            if (settings.view_sheets_width <= 10) {
                settings.view_sheets_width = 200;
            }

            show_sheets_and_library ();
            debug ("Show both\n");
        } else if (settings.view_state == 1) {
            hide_library ();
            debug ("Show sheets\n");
        } else if (settings.view_state == 2) {
            hide_sheets ();
            debug ("Show editor\n");
            _show_filename = settings.show_filename;
            settings.show_filename = true;
        }
        debug ("View mode: %d\n", settings.view_state);
    }

    public void show_sheets () {
        var settings = AppSettings.get_default ();
        ThiefApp instance = ThiefApp.get_instance ();

        debug ("Showing sheets (%d)\n", instance.sheets_pane.get_position ());
        move_panes(0, settings.view_sheets_width);
    }

    public void show_sheets_and_library () {
        var settings = AppSettings.get_default ();
        
        move_panes (settings.view_library_width, settings.view_sheets_width + settings.view_library_width);
    }

    public void hide_library () {
        var settings = AppSettings.get_default ();
        ThiefApp instance = ThiefApp.get_instance ();

        debug ("Hiding library (%d)\n", instance.library_pane.get_position ());
        if (instance.library_pane.get_position () > 0 || instance.sheets_pane.get_position () <= 0) {
            _moving = false;
            int target_sheets = 0;
            if (instance.library_pane.get_position () > 0) {
                target_sheets = instance.sheets_pane.get_position () - instance.library_pane.get_position ();
            } else {
                if (instance.sheets_pane.get_position () > 0) {
                    target_sheets = instance.sheets_pane.get_position ();
                } else {
                    target_sheets = settings.view_sheets_width;
                }
            }
            move_panes (0, target_sheets);
        }
    }

    public void hide_sheets () {
        var settings = AppSettings.get_default ();
        ThiefApp instance = ThiefApp.get_instance ();

        debug ("Hiding sheets (%d)\n", instance.sheets_pane.get_position ());
        move_panes(0, 0);
    }

    // There's totally a GTK thing that supports animation, but I haven't found where to
    // steal the code from yet
    private int _hop_sheets = 0;
    private int _hop_library = 0;
    private bool _moving = false;
    private void move_panes (int library_pane, int sheet_pane) {
        ThiefApp instance = ThiefApp.get_instance ();

        if (_moving) {
            return;
        }

        _moving = true;

        _hop_sheets = (int)((sheet_pane - instance.sheets_pane.get_position ()) / Constants.ANIMATION_FRAMES);
        _hop_library = (int)((library_pane - instance.library_pane.get_position ()) / Constants.ANIMATION_FRAMES);

        debug ("Sheets (%d, %d), Library (%d, %d)\n", sheet_pane, instance.sheets_pane.get_position (), library_pane, instance.library_pane.get_position ());

        debug ("Sheets hop: %d, Library Hop: %d\n", _hop_sheets, _hop_library);

        Timeout.add ((int)(Constants.ANIMATION_TIME / Constants.ANIMATION_FRAMES), () => {
            int next_sheets = instance.sheets_pane.get_position () + _hop_sheets;
            int next_library = instance.library_pane.get_position () + _hop_library;
            bool sheet_done = false;
            bool lib_done = false;

            if (!_moving) {
                // debug ("No longer moving\n");
                _moving = false;
                return false;
            }

            // debug ("Sheets move: (%d, %d), Library move: (%d, %d)\n", next_sheets, _hop_sheets, next_library, _hop_library);

            if ((_hop_sheets > 0) && (next_sheets >= sheet_pane)) {
                instance.sheets_pane.set_position (sheet_pane);
                sheet_done = true;
            } else if ((_hop_sheets < 0) && (next_sheets <= sheet_pane)) {
                instance.sheets_pane.set_position (sheet_pane);
                sheet_done = true;
            } else {
                instance.sheets_pane.set_position (next_sheets);
            }
            sheet_done = sheet_done || (_hop_sheets == 0);

            if ((_hop_library > 0) && (next_library >= library_pane)) {
                instance.library_pane.set_position (library_pane);
                lib_done = true;
            } else if ((_hop_library < 0) && (next_library <= library_pane)) {
                instance.library_pane.set_position (library_pane);
                lib_done = true;
            } else {
                instance.library_pane.set_position (next_library);
            }
            lib_done = lib_done || (_hop_library == 0);

            // debug ("Sheets done: %s, Library done: %s\n", sheet_done ? "yes" : "no", lib_done ? "yes" : "no");

            _moving = !lib_done || !sheet_done;
            return _moving;
        });
    }

    public bool moving () {
        return _moving;
    }
}