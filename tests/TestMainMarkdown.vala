public class TestMainMarkdown {
    public static int main (string[] args) {
        Test.init (ref args);
        new MarkdownTests ();
        return Test.run ();
    }
}
