public class TestMainHelpers {
    public static int main (string[] args) {
        Test.init (ref args);
        new HelpersTests ();
        return Test.run ();
    }
}
