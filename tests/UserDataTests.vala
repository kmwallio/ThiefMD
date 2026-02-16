using ThiefMD;
using ThiefMD.Controllers;

public class UserDataTests {
    public UserDataTests () {
        test_data_directories ();
        test_trash_folder ();
    }

    private void test_data_directories () {
        Test.add_func ("/thiefmd/user_data_directories", () => {
            // Create data directories
            UserData.create_data_directories ();
            
            // Check that paths are set
            assert (UserData.data_path != "");
            assert (UserData.style_path != "");
            assert (UserData.scheme_path != "");
            assert (UserData.css_path != "");
            
            // Check that directories contain expected components
            assert (UserData.data_path.contains (Constants.DATA_BASE));
            assert (UserData.style_path.contains (Constants.DATA_STYLES));
            assert (UserData.scheme_path.contains (Constants.DATA_SCHEMES));
            assert (UserData.css_path.contains (Constants.DATA_CSS));
            
            // Check directories were created
            assert (FileUtils.test (UserData.data_path, FileTest.IS_DIR));
            assert (FileUtils.test (UserData.style_path, FileTest.IS_DIR));
            assert (FileUtils.test (UserData.scheme_path, FileTest.IS_DIR));
            assert (FileUtils.test (UserData.css_path, FileTest.IS_DIR));
        });
    }

    private void test_trash_folder () {
        Test.add_func ("/thiefmd/user_data_trash_folder", () => {
            // Get trash folder
            string? trash = UserData.get_trash_folder ();
            
            // Trash folder should not be null
            assert (trash != null);
            
            // Trash folder should contain expected path components
            assert (trash.contains ("Trash") || trash.contains ("trash"));
        });
    }
}
