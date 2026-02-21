using ThiefMD;
using ThiefMD.Controllers;

public class FdxTests {
    public FdxTests () {
        test_fdx_to_fountain ();
        test_fountain_to_fdx ();
        test_fdx_round_trip ();
    }

    // Sample FDX document for testing
    private const string SAMPLE_FDX = """<?xml version="1.0" encoding="UTF-8"?>
<FinalDraft DocumentType="Script" Template="No" Version="1">
  <Content>
    <Paragraph Type="Scene Heading">
      <Text>INT. COFFEE SHOP - DAY</Text>
    </Paragraph>
    <Paragraph Type="Action">
      <Text>A barista makes coffee.</Text>
    </Paragraph>
    <Paragraph Type="Character">
      <Text>BARISTA</Text>
    </Paragraph>
    <Paragraph Type="Dialogue">
      <Text>What can I get you?</Text>
    </Paragraph>
    <Paragraph Type="Character">
      <Text>CUSTOMER</Text>
    </Paragraph>
    <Paragraph Type="Parenthetical">
      <Text>(nervously)</Text>
    </Paragraph>
    <Paragraph Type="Dialogue">
      <Text>Just a coffee, please.</Text>
    </Paragraph>
    <Paragraph Type="Transition">
      <Text>CUT TO:</Text>
    </Paragraph>
  </Content>
</FinalDraft>""";

    private void test_fdx_to_fountain () {
        Test.add_func ("/thiefmd/fdx_to_fountain", () => {
            string result = FileManager.fdx_to_fountain (SAMPLE_FDX);

            // Scene heading should appear in output
            assert (result.contains ("INT. COFFEE SHOP - DAY"));

            // Action should appear
            assert (result.contains ("A barista makes coffee."));

            // Character names should appear
            assert (result.contains ("BARISTA"));
            assert (result.contains ("CUSTOMER"));

            // Dialogue should appear
            assert (result.contains ("What can I get you?"));
            assert (result.contains ("Just a coffee, please."));

            // Parenthetical should appear
            assert (result.contains ("(nervously)"));

            // Transition should appear with > marker
            assert (result.contains ("> CUT TO:"));
        });

        Test.add_func ("/thiefmd/fdx_to_fountain_upcasing", () => {
            // FDX allows lower case character names and scene headings;
            // Fountain requires them to be ALL CAPS.
            string lowercase_fdx = """<?xml version="1.0" encoding="UTF-8"?>
<FinalDraft DocumentType="Script" Template="No" Version="1">
  <Content>
    <Paragraph Type="Scene Heading">
      <Text>int. cafe - night</Text>
    </Paragraph>
    <Paragraph Type="Character">
      <Text>barista</Text>
    </Paragraph>
    <Paragraph Type="Dialogue">
      <Text>We're closing soon.</Text>
    </Paragraph>
  </Content>
</FinalDraft>""";
            string result = FileManager.fdx_to_fountain (lowercase_fdx);

            // Scene heading and character name should be uppercased
            assert (result.contains ("INT. CAFE - NIGHT"));
            assert (result.contains ("BARISTA"));
            // Dialogue should not be upcased
            assert (result.contains ("We're closing soon."));
        });

        Test.add_func ("/thiefmd/fdx_to_fountain_parenthetical_spacing", () => {
            // Parentheticals must not have blank lines separating them from
            // surrounding character/dialogue lines.
            string paren_fdx = """<?xml version="1.0" encoding="UTF-8"?>
<FinalDraft DocumentType="Script" Template="No" Version="1">
  <Content>
    <Paragraph Type="Character">
      <Text>HERO</Text>
    </Paragraph>
    <Paragraph Type="Dialogue">
      <Text>I can do this.</Text>
    </Paragraph>
    <Paragraph Type="Parenthetical">
      <Text>(quietly)</Text>
    </Paragraph>
    <Paragraph Type="Dialogue">
      <Text>I think.</Text>
    </Paragraph>
  </Content>
</FinalDraft>""";
            string result = FileManager.fdx_to_fountain (paren_fdx);

            // The entire dialogue block should have no blank lines inside it.
            // We look for the character followed immediately by the first dialogue,
            // then paren, then second dialogue — all without intervening blank lines.
            assert (result.contains ("HERO\nI can do this.\n(quietly)\nI think."));
        });

        Test.add_func ("/thiefmd/fdx_to_fountain_single_blank_between_blocks", () => {
            // Scene headings and action blocks should be separated by exactly one
            // blank line — not two.
            string two_scenes_fdx = """<?xml version="1.0" encoding="UTF-8"?>
<FinalDraft DocumentType="Script" Template="No" Version="1">
  <Content>
    <Paragraph Type="Scene Heading">
      <Text>INT. KITCHEN - DAY</Text>
    </Paragraph>
    <Paragraph Type="Action">
      <Text>Water boils on the stove.</Text>
    </Paragraph>
    <Paragraph Type="Scene Heading">
      <Text>EXT. GARDEN - CONTINUOUS</Text>
    </Paragraph>
    <Paragraph Type="Action">
      <Text>Birds chirp.</Text>
    </Paragraph>
  </Content>
</FinalDraft>""";
            string result = FileManager.fdx_to_fountain (two_scenes_fdx);

            // Each block should be separated by exactly one blank line (\n\n total).
            // Two blank lines (\n\n\n) between blocks is the bug we're fixing.
            assert (!result.contains ("\n\n\n"));
            assert (result.contains ("INT. KITCHEN - DAY\n\nWater boils on the stove.\n\nEXT. GARDEN - CONTINUOUS\n\nBirds chirp."));
        });
    }

    private void test_fountain_to_fdx () {
        Test.add_func ("/thiefmd/fountain_to_fdx", () => {
            // Build a simple fountain screenplay
            string fountain = """INT. OFFICE - DAY

Someone types at a keyboard.

CODER
It compiles!

> FADE OUT.
""";

            string result = FileManager.fountain_to_fdx (fountain);

            // Should produce valid FDX XML
            assert (result.contains ("<?xml version=\"1.0\""));
            assert (result.contains ("<FinalDraft"));
            assert (result.contains ("<Content>"));
            assert (result.contains ("</Content>"));
            assert (result.contains ("</FinalDraft>"));

            // Scene heading should be tagged correctly
            assert (result.contains ("Type=\"Scene Heading\""));
            assert (result.contains ("INT. OFFICE - DAY"));

            // Action paragraph
            assert (result.contains ("Type=\"Action\""));
            assert (result.contains ("Someone types at a keyboard."));

            // Character cue
            assert (result.contains ("Type=\"Character\""));
            assert (result.contains ("CODER"));

            // Dialogue
            assert (result.contains ("Type=\"Dialogue\""));
            assert (result.contains ("It compiles!"));

            // Transition
            assert (result.contains ("Type=\"Transition\""));
            assert (result.contains ("FADE OUT."));
        });
    }

    private void test_fdx_round_trip () {
        Test.add_func ("/thiefmd/fdx_round_trip", () => {
            // Convert FDX → Fountain → FDX and check the key content survives
            string fountain = FileManager.fdx_to_fountain (SAMPLE_FDX);
            assert (fountain != "");

            string fdx = FileManager.fountain_to_fdx (fountain);
            assert (fdx != "");

            // Key content should survive the round-trip
            assert (fdx.contains ("INT. COFFEE SHOP - DAY"));
            assert (fdx.contains ("A barista makes coffee."));
            assert (fdx.contains ("BARISTA"));
            assert (fdx.contains ("CUSTOMER"));
            assert (fdx.contains ("Just a coffee, please."));
        });
    }
}
