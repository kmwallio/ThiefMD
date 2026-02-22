using ThiefMD;

public class MarkerNavigationTests {
    public MarkerNavigationTests () {
        Test.add_func ("/thiefmd/marker_navigation/utf8_byte_to_char_offset", () => {
            string text = "Café noir";
            int byte_offset = "Café".length;
            int char_offset = utf8_byte_to_char_offset (text, byte_offset);
            assert (char_offset == 5);
        });

        Test.add_func ("/thiefmd/marker_navigation/fountain_forced_heading", () => {
            assert (is_fountain_scene_heading (".MONTAGE"));
            assert (is_fountain_scene_heading (".   DREAM SEQUENCE"));
            assert (!is_fountain_scene_heading ("..not a scene heading"));
        });

        Test.add_func ("/thiefmd/marker_navigation/fountain_standard_heading", () => {
            assert (is_fountain_scene_heading ("INT. HOSPITAL HALLWAY - DAY"));
            assert (is_fountain_scene_heading ("EXT/INT CAR - NIGHT"));
            assert (is_fountain_scene_heading ("I/E APARTMENT - DAY"));
            assert (!is_fountain_scene_heading ("A NURSE finally scoops up the slippery baby."));
        });

        Test.add_func ("/thiefmd/marker_navigation/scene_pattern_multiline", () => {
            string sample = "A NURSE finally scoops up the slippery baby.\n.My father’s birth would set the pace.\n..transition style line\nINT. HALF-DARK PARIS APARTMENT - DAY\n";
            var scene_regex = new Regex (get_fountain_scene_heading_pattern (), RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS);
            MatchInfo match_info;
            assert (scene_regex.match (sample, 0, out match_info));

            int match_count = 0;
            do {
                match_count++;
            } while (match_info.next ());

            assert (match_count == 2);
        });
    }
}
