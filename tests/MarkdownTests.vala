using ThiefMD;
using ThiefMD.Controllers;
using ThiefMD.Enrichments;

public class MarkdownTests {
    public MarkdownTests () {
        Test.add_func ("/thiefmd/file_extensions", () => {
            assert (is_fountain ("screenplay.fou"));
            assert (is_fountain ("screenplay.fountain"));
            assert (is_fountain ("screenplay.spmd"));
            assert (!is_fountain ("screenplay.markdown"));
            assert (!is_fountain ("screenplay.fountain.markdown"));
            assert (!is_fountain ("screenplay.docx"));
            assert (!is_fountain ("screenplay.bib"));
        });

        Test.add_func ("/thiefmd/titles", () => {
            assert (make_title ("this_cool_cat") == "This Cool Cat");
            assert (make_title ("this-cool_cat") == "This Cool Cat");
            assert (make_title ("this_cool-cat") == "This Cool Cat");
            assert (make_title ("this cool-cat") == "This Cool Cat");
            assert (make_title ("this_cool cat") == "This Cool Cat");
        });

        Test.add_func ("/thiefmd/find_file", () => {
            assert (Pandoc.find_file ("README.md", Environment.get_current_dir ()) != "");
            assert (Pandoc.find_file ("README.md", Environment.get_current_dir ()) != "README.md");
        });

        Test.add_func ("/thiefmd/strip_markdown", () => {
            assert (strip_markdown ("this is a [link](https://thiefmd.com)") == "this is a link");
            assert (strip_markdown ("some **bold** text") == "some bold text");
            assert (strip_markdown ("some _italic_ text") == "some italic text");
        });

        Test.add_func ("/thiefmd/grammar", () => {
            GrammarThinking grammar_check = new GrammarThinking ();
            assert (grammar_check.sentence_check ("he ate cake"));
            assert (!grammar_check.sentence_check ("he eat cake"));
            Gee.List<string> problem_words = new Gee.LinkedList<string> ();
            assert (!grammar_check.sentence_check ("they eats cake", problem_words));
            assert (!problem_words.is_empty);
            assert (problem_words.contains ("eats"));
            Gee.List<string> no_problem_words = new Gee.LinkedList<string> ();
            assert (grammar_check.sentence_check ("he ate cake", no_problem_words));
            assert (no_problem_words.is_empty);
        });
    }
}