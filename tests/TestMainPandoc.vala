public class TestMainPandoc {
    public static int main (string[] args) {
        Test.init (ref args);
        new PandocTests ();
        return Test.run ();
    }
}
