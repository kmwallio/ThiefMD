public class TestMainFileManager {
    public static int main (string[] args) {
        Test.init (ref args);
        new FileManagerTests ();
        return Test.run ();
    }
}
