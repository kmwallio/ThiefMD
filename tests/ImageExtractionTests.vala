using ThiefMD;
using ThiefMD.Controllers;

public class ImageExtractionTests : Object {
    public ImageExtractionTests () {
        upload_images ();
        upload_images_missing ();
        import_images ();
    }

    public static void set_up () {
        string search_path = Path.build_path (Path.DIR_SEPARATOR_S, Environment.get_tmp_dir (), "image-tests");

        File temp_location = File.new_for_path (search_path);

        if (!temp_location.query_exists ()) {
            if (!temp_location.make_directory_with_parents ()) {
                warning ("Could not create environment directories");
            }
        }

        try {
            string buffer = "placeholder";
            File image_one = File.new_for_path (Path.build_filename (search_path, "image1.png"));
            FileManager.save_file (image_one, buffer.data);
            File image_two = File.new_for_path (Path.build_filename (search_path, "image2.png"));
            FileManager.save_file (image_two, buffer.data);
            File image_three = File.new_for_path (Path.build_filename (search_path, "image3.png"));
            FileManager.save_file (image_three, buffer.data);
        } catch (Error e) {
            warning ("Could not setup testenv: %s", e.message);
        }
    }

    public static void tear_down () {
        string search_path = Path.build_path (Path.DIR_SEPARATOR_S, Environment.get_tmp_dir (), "image-tests");
        File temp_location = File.new_for_path (search_path);
    
        try {
            if (temp_location.query_exists ()) {
                Dir dir = Dir.open (search_path, 0);
                string? file_name = null;
                while ((file_name = dir.read_name()) != null) {
                    if (!file_name.has_prefix(".")) {
                        string path = Path.build_filename (search_path, file_name);
                        if (FileUtils.test (path, FileTest.IS_REGULAR) && !FileUtils.test (path, FileTest.IS_SYMLINK)) {
                            File rm_file = File.new_for_path (path);
                            rm_file.delete ();
                        }
                    }
                }
                temp_location.delete ();
            }
        } catch (Error e) {
            warning ("Could not clean up: %s\n", e.message);
            return;
        }
    }

    public void upload_images () {
        Test.add_func ("/thiefmd/upload-images", () => {
            set_up ();
            string search_path = Path.build_path (Path.DIR_SEPARATOR_S, Environment.get_tmp_dir (), "image-tests");
            string sample_text = """# Blog Post
                Photos:

                [](image3.png)

                [](/image-tests/image2.png)

                [](image-tests/image1.png)
                """;

            Gee.Map<string, string> images_to_upload = Pandoc.file_image_map (sample_text, search_path);
            assert (images_to_upload.keys.size == 3);
            tear_down ();
        });
    }

    public void upload_images_missing () {
        Test.add_func ("/thiefmd/upload-images-missing", () => {
            set_up ();
            string search_path = Path.build_path (Path.DIR_SEPARATOR_S, Environment.get_tmp_dir (), "image-tests");
            File image_two = File.new_for_path (Path.build_filename (search_path, "image2.png"));
            if (image_two.query_exists ()) {
                image_two.delete ();
            }

            string sample_text = """# Blog Post
    Photos:

    [](image3.png)

    [](/image-tests/image2.png)

    [](image-tests/image1.png)
    """;

            Gee.Map<string, string> images_to_upload = Pandoc.file_image_map (sample_text, search_path);
            assert (images_to_upload.keys.size == 2);
            tear_down ();
        });
    }

    public void import_images () {
        Test.add_func ("/thiefmd/import-images", () => {
            string search_path = Path.build_path (Path.DIR_SEPARATOR_S, Environment.get_tmp_dir (), "image-tests");
            string sample_text = """# Blog Post
                Photos:

                [](image3.png)

                [](/image-tests/image2.png)

                [](image-tests/image1.png)
                """;

            Gee.List<string> images_to_extract = Pandoc.file_import_paths (sample_text);
            assert (images_to_extract.size == 3);
            tear_down ();
        });
    }
}