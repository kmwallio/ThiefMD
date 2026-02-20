using ThiefMD;
using ThiefMD.Controllers;

public class PandocTests {
    public PandocTests () {
        test_find_file ();
        test_needs_bibtex ();
        test_generate_discount_html ();
    }

    private void test_find_file () {
        Test.add_func ("/thiefmd/pandoc_find_file", () => {
            // Find README.md in current directory
            string readme = Pandoc.find_file ("README.md", Environment.get_current_dir ());
            assert (readme != "");
            assert (readme != "README.md");
            assert (FileUtils.test (readme, FileTest.EXISTS));
            
            // Non-existent file should return original filename
            string not_found = Pandoc.find_file ("nonexistent_file_12345.xyz", Environment.get_current_dir ());
            assert (not_found == "nonexistent_file_12345.xyz");
        });
    }

    private void test_needs_bibtex () {
        Test.add_func ("/thiefmd/pandoc_needs_bibtex", () => {
            // Text without bibtex reference
            string no_bibtex = "This is a simple document";
            assert (!Pandoc.needs_bibtex (no_bibtex));
            
            // Text with YAML front matter containing bibliography directive
            string with_bibtex = "---\nbibliography: refs.bib\n---\n\nThis cites a source";
            assert (Pandoc.needs_bibtex (with_bibtex));
            
            // Text with YAML front matter with quoted bibliography path
            string with_bibliography = "---\nbibliography: \"sources.bib\"\n---\n\nDocument content";
            assert (Pandoc.needs_bibtex (with_bibliography));
            
            // Text without YAML front matter
            string plain_text = "No YAML here\nJust plain text";
            assert (!Pandoc.needs_bibtex (plain_text));
        });
    }

    private void test_generate_discount_html () {
        Test.add_func ("/thiefmd/pandoc_generate_discount_html", () => {
            string markdown = "# Hello Writer\n\nA paragraph with **bold** and a [link](https://example.com).\n\n- one\n- two\n";

            string html_once = "";
            bool first_result = Pandoc.generate_discount_html (markdown, out html_once);
            assert (first_result);
            assert (html_once != "");
            assert (html_once.contains ("<h1"));
            assert (html_once.contains ("<strong>bold</strong>"));
            assert (html_once.contains ("<ul>"));

            string html_twice = "";
            bool second_result = Pandoc.generate_discount_html (markdown, out html_twice);
            assert (second_result);
            assert (html_twice != "");
            assert (html_once == html_twice);

            string empty_html = "not-empty-before-call";
            bool empty_result = Pandoc.generate_discount_html ("", out empty_html);
            assert (!empty_result);
            assert (empty_html == "");
        });
    }
}
