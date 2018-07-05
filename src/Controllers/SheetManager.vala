using ThiefMD;
using ThiefMD.Widgets;

namespace ThiefMD.Controllers.SheetManager {
    private Sheet _currentSheet;
    public static Subscription sub;

    public class Subscription {
        public signal void changed ();

        public Subscription () {
            // No clue what I'm doing...
        }

        public void state_change () {
            changed ();
        }
    }

    public static bool load_sheet (Sheet sheet) {
        var settings = AppSettings.get_default ();
        bool loaded_file = false;

        if (sheet == null) {
            return false;
        }

        if (settings.last_file != "") {
            FileManager.save_work_file ();
        }

        if (_currentSheet != null) {
            _currentSheet.redraw ();
            _currentSheet.active = false;
        }

        loaded_file = FileManager.open_file (sheet.file_path());
        _currentSheet = sheet;
        _currentSheet.active = true;
        sub.state_change ();

        debug ("Tried to load %s (%s)\n", sheet.file_path (), (loaded_file) ? "success" : "failed");

        return loaded_file;
    }

    public static void new_sheet (string file_name) {
        var settings = AppSettings.get_default ();

        if (_currentSheet != null) {
            // Save the current file
            if (settings.last_file != "") {
                FileManager.save_work_file ();
            }

            // Attempt to create the sheet and switch to it
            Sheets sheet = _currentSheet.get_parent_sheets ();
            if (FileManager.create_sheet(sheet.get_sheets_path (), file_name)) {
                sheet.load_sheets ();
            }
        } else {
            warning ("Could not create file, no current sheet");
        }
    }

    // Just finds headers and makes the bold...
    public string mini_mark (string contents) {
        string result = contents;
        try {
            Regex headers = new Regex ("^(#+)\\s(.+)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            result = headers.replace (contents, -1, 0, "<b>\\1 \\2</b>");
        } catch (Error e) {
            warning ("Error: %s", e.message);
        }
        return result;
    }
}