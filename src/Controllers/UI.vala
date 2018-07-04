using ThiefMD;
using ThiefMD.Widgets;

namespace ThiefMD.Controllers.UI {

    private int _hop = 0;
    private bool _moving = false;

    public void toggle_view () {
        var settings = AppSettings.get_default ();

        settings.view_state = (settings.view_state + 1) % 3;
        
        if (settings.view_state == 0) {
            show_sheets_and_library ();
        } else if (settings.view_state == 1) {
            // hide library
        } else if (settings.view_state == 2) {
            hide_sheets();
        }
        stdout.printf ("View mode: %d\n", settings.view_state);
    }

    public void show_sheets_and_library () {
        show_sheets ();
    }

    public void show_sheets () {
        var settings = AppSettings.get_default ();
        ThiefApp instance = ThiefApp.get_instance ();

        if (instance.sheets_pane.get_position () < settings.view_sheets_width) {
            _moving = false;
            _hop = (int)((settings.view_sheets_width - instance.sheets_pane.get_position ()) / Constants.ANIMATION_FRAMES);
            _moving = true;
            Timeout.add ((int)(Constants.ANIMATION_TIME / Constants.ANIMATION_FRAMES), () => {
                if (!_moving || (instance.sheets_pane.get_position () >= settings.view_sheets_width)) {
                    _moving = false;
                    return false;
                }
                int next_place = instance.sheets_pane.get_position () + _hop;
                instance.sheets_pane.set_position ((next_place <= settings.view_sheets_width) ? next_place : settings.view_sheets_width);
                return true;
            });
        }
    }

    public void hide_sheets () {
        var settings = AppSettings.get_default ();
        ThiefApp instance = ThiefApp.get_instance ();

        stdout.printf ("Hiding sheets (%d)\n", instance.sheets_pane.get_position ());
        if (instance.sheets_pane.get_position () > 0) {
            _moving = false;
            settings.view_sheets_width = instance.sheets_pane.get_position ();
            _hop = (int)((instance.sheets_pane.get_position ()) / Constants.ANIMATION_FRAMES);
            _moving = true;
            Timeout.add ((int)(Constants.ANIMATION_TIME / Constants.ANIMATION_FRAMES), () => {
                if (!_moving || (instance.sheets_pane.get_position () <= 0)) {
                    _moving = false;
                    return false;
                }
                int next_place = instance.sheets_pane.get_position () - _hop;
                instance.sheets_pane.set_position ((next_place >= 0) ? next_place : 0);
                return true;
            });
        }
    }

}