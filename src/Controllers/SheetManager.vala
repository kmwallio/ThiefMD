using ThiefMD;
using ThiefMD.Widgets;

namespace ThiefMD.Controllers.SheetManager {
    private Sheet _currentSheet;
    private Sheets _current_sheets;

    public void set_sheets (Sheets sheets) {
        _current_sheets = sheets;
        UI.set_sheets (sheets);
    }

    public static void refresh_sheet () {
        if (_currentSheet != null) {
            _currentSheet.redraw ();
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

        debug ("Tried to load %s (%s)\n", sheet.file_path (), (loaded_file) ? "success" : "failed");

        return loaded_file;
    }

    public static void new_sheet (string file_name) {
        var settings = AppSettings.get_default ();
        string parent_dir = "";
        Sheets sheet;

        if (_current_sheets == null) {
            // Save the current file
            if (settings.last_file != "") {
                FileManager.save_work_file ();
            }

            // Attempt to create the sheet and switch to it
            sheet = _currentSheet.get_parent_sheets ();
            parent_dir = sheet.get_sheets_path ();
        } else {
            sheet = _current_sheets;
            parent_dir = sheet.get_sheets_path ();
        }

        // Create the file and refresh
        if (parent_dir != "") {
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
            result = result.replace ("&", "&amp;");
            result = result.replace ("<", "&lt;").replace (">", "&gt;");
            result = headers.replace (result, -1, 0, "<b>\\1 \\2</b>");
        } catch (Error e) {
            warning ("Error: %s", e.message);
        }
        return result;
    }
}