using ThiefMD;

public class HelpersTests {
    public HelpersTests () {
        test_exportable_file ();
        test_can_open_file ();
        test_get_some_words ();
        test_csv_to_md ();
        test_string_or_empty_string ();
    }

    private void test_exportable_file () {
        Test.add_func ("/thiefmd/exportable_file", () => {
            assert (exportable_file ("document.md"));
            assert (exportable_file ("novel.markdown"));
            assert (exportable_file ("screenplay.fountain"));
            assert (exportable_file ("script.fou"));
            assert (exportable_file ("scene.spmd"));
            assert (!exportable_file ("archive.zip"));
            assert (!exportable_file ("image.png"));
            assert (!exportable_file ("bibliography.bib"));
            // Test case insensitivity
            assert (exportable_file ("Document.MD"));
            assert (exportable_file ("NOVEL.MARKDOWN"));
        });
    }

    private void test_can_open_file () {
        Test.add_func ("/thiefmd/can_open_file", () => {
            // Can open markdown files
            assert (can_open_file ("document.md"));
            assert (can_open_file ("novel.markdown"));
            // Can open fountain files
            assert (can_open_file ("screenplay.fountain"));
            assert (can_open_file ("script.fou"));
            assert (can_open_file ("scene.spmd"));
            // Can open bibliography files
            assert (can_open_file ("sources.bib"));
            assert (can_open_file ("references.bibtex"));
            // Cannot open other files
            assert (!can_open_file ("archive.zip"));
            assert (!can_open_file ("image.png"));
            // Test uppercase
            assert (can_open_file ("DOCUMENT.MD"));
            assert (can_open_file ("SOURCES.BIB"));
        });
    }

    private void test_get_some_words () {
        Test.add_func ("/thiefmd/get_some_words", () => {
            // Extract words from simple text
            string words = get_some_words ("Hello world from test");
            assert (words.contains ("hello"));
            assert (words.contains ("world"));
            
            // Extract words from text with punctuation
            string words_punct = get_some_words ("Hello, world! How are you?");
            assert (words_punct.contains ("hello"));
            assert (words_punct.contains ("world"));
            
            // Test with long words (should be filtered)
            string long_words = get_some_words ("Supercalifragilisticexpialidocious short");
            assert (!long_words.contains ("supercalifragilistic"));
            
            // Test empty string
            string empty = get_some_words ("");
            assert (empty == "");
        });
    }

    private void test_csv_to_md () {
        Test.add_func ("/thiefmd/csv_to_md", () => {
            // Simple CSV to Markdown
            string csv = "Name,Age,City\nAlice,30,NYC\nBob,25,LA";
            string result = csv_to_md (csv);
            assert (result.contains ("|Name"));
            assert (result.contains ("Age"));
            assert (result.contains ("City|"));
            assert (result.contains ("|Alice"));
            assert (result.contains ("30"));
            assert (result.contains ("NYC|"));
            assert (result.contains ("|Bob"));
            assert (result.contains ("25"));
            assert (result.contains ("LA|"));
            // Should have pipe separator rows
            assert (result.contains ("|\n"));
            
            // CSV with simple values
            string csv_simple = "Name,Value\nTest,123";
            string result_simple = csv_to_md (csv_simple);
            assert (result_simple.contains ("|Test"));
            assert (result_simple.contains ("123|"));
        });
    }

    private void test_string_or_empty_string () {
        Test.add_func ("/thiefmd/string_or_empty_string", () => {
            // Test with valid string
            assert (string_or_empty_string ("hello") == "hello");
            
            // Test with null
            assert (string_or_empty_string (null) == "");
            
            // Test with empty string
            assert (string_or_empty_string ("") == "");
            
            // Test with whitespace
            assert (string_or_empty_string ("   ") == "   ");
        });
    }
}
