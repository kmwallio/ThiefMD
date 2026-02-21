/*
 * Copyright (C) 2020 kmwallio
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall
 * be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

using ThiefMD;

// Fountain ↔ FDX (Final Draft XML) conversion helpers.
// FDX spec: https://www.finaldraft.com/learn/fdx-spec/
// Fountain spec: https://fountain.io/syntax
namespace ThiefMD.Controllers.FountainFdx {

    // Convert FDX (Final Draft XML) content to Fountain screenplay format.
    public string fdx_to_fountain (string fdx_content) {
        var builder = new StringBuilder ();
        bool is_first = true;
        string prev_type = "";

        Xml.Doc* doc = Xml.Parser.parse_memory (fdx_content, fdx_content.length);
        if (doc == null) {
            return "";
        }

        Xml.Node* root = doc->get_root_element ();
        if (root == null) {
            delete doc;
            return "";
        }

        // Walk to <Content> node inside the root <FinalDraft> element
        for (Xml.Node* child = root->children; child != null; child = child->next) {
            if (child->type != Xml.ElementType.ELEMENT_NODE || child->name != "Content") {
                continue;
            }

            for (Xml.Node* para = child->children; para != null; para = para->next) {
                if (para->type != Xml.ElementType.ELEMENT_NODE || para->name != "Paragraph") {
                    continue;
                }

                string? para_type = para->get_prop ("Type");
                if (para_type == null) {
                    para_type = "Action";
                }

                // Collect all text from child <Text> nodes (handles styled runs too)
                var text_builder = new StringBuilder ();
                for (Xml.Node* t = para->children; t != null; t = t->next) {
                    if (t->type == Xml.ElementType.ELEMENT_NODE && t->name == "Text") {
                        string? content = t->get_content ();
                        if (content != null) {
                            text_builder.append (content);
                        }
                    }
                }

                string text = text_builder.str.strip ();
                if (text == "") {
                    continue;
                }

                // Dialogue-continuation check: parenthetical/dialogue that follows a character
                // block should have no blank line before it in Fountain.
                bool in_dialogue = (para_type == "Parenthetical" || para_type == "Dialogue") &&
                                   (prev_type == "Character" || prev_type == "Parenthetical" || prev_type == "Dialogue");

                // Add a blank line before this element unless it continues a dialogue block
                if (!is_first && !in_dialogue) {
                    builder.append ("\n");
                }

                switch (para_type) {
                    case "Scene Heading":
                        // Scene headings must be ALL CAPS in Fountain.
                        // If the heading lacks a standard keyword (INT., EXT., etc.)
                        // prefix it with "." so Fountain treats it as a forced heading.
                        string heading = text.up ();
                        if (!is_scene_heading (heading)) {
                            heading = "." + heading;
                        }
                        builder.append (heading + "\n");
                        break;
                    case "Character":
                        // Character cues must be ALL CAPS in Fountain
                        builder.append (text.up () + "\n");
                        break;
                    case "Transition":
                        // Fountain right-aligns transitions with the > marker
                        builder.append ("> " + text + "\n");
                        break;
                    default:
                        builder.append (text + "\n");
                        break;
                }

                is_first = false;
                prev_type = para_type;
            }
            break; // Only one <Content> block expected
        }

        delete doc;
        return builder.str.strip ();
    }

    // Convert Fountain screenplay format to FDX (Final Draft XML).
    public string fountain_to_fdx (string fountain_content) {
        var xml = new StringBuilder ();
        xml.append ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        xml.append ("<FinalDraft DocumentType=\"Script\" Template=\"No\" Version=\"1\">\n");
        xml.append ("  <Content>\n");

        string[] lines = fountain_content.split ("\n");
        int len = lines.length;
        int i = 0;
        // Track whether we're inside a character/dialogue block
        bool in_dialogue = false;

        while (i < len) {
            string line = lines[i].strip ();

            // Blank line ends a dialogue block
            if (line == "") {
                in_dialogue = false;
                i++;
                continue;
            }

            // Skip Fountain notes [[...]]
            if (line.has_prefix ("[[") && line.has_suffix ("]]")) {
                i++;
                continue;
            }

            // Skip synopses (= ...)
            if (line.has_prefix ("=")) {
                i++;
                continue;
            }

            // Centered text: >text<  (not a transition)
            if (line.has_prefix (">") && line.has_suffix ("<")) {
                append_paragraph (xml, "General", line.substring (1, line.length - 2).strip ());
                i++;
                continue;
            }

            // Forced transition: starts with > but not >text< format
            if (line.has_prefix (">")) {
                append_paragraph (xml, "Transition", line.substring (1).strip ());
                in_dialogue = false;
                i++;
                continue;
            }

            // Forced scene heading: starts with . (but not ..)
            if (line.has_prefix (".") && !line.has_prefix ("..")) {
                append_paragraph (xml, "Scene Heading", line.substring (1).strip ());
                in_dialogue = false;
                i++;
                continue;
            }

            // Scene headings: INT., EXT., EST., INT./EXT., I/E
            if (is_scene_heading (line)) {
                append_paragraph (xml, "Scene Heading", line);
                in_dialogue = false;
                i++;
                continue;
            }

            // Section headers: # Heading – treat as general text
            if (line.has_prefix ("#")) {
                append_paragraph (xml, "General", line.replace ("#", "").strip ());
                i++;
                continue;
            }

            // Within a dialogue block: parenthetical or dialogue line
            if (in_dialogue) {
                if (line.has_prefix ("(") && line.has_suffix (")")) {
                    append_paragraph (xml, "Parenthetical", line);
                } else {
                    append_paragraph (xml, "Dialogue", line);
                }
                i++;
                continue;
            }

            // Forced action: starts with !
            if (line.has_prefix ("!")) {
                append_paragraph (xml, "Action", line.substring (1).strip ());
                i++;
                continue;
            }

            // Transition: ends with TO: or well-known fade-out phrases
            if (is_transition (line)) {
                append_paragraph (xml, "Transition", line);
                i++;
                continue;
            }

            // Character name: ALL CAPS (forced with @), followed by non-blank line
            if (is_character (line) && i + 1 < len && lines[i + 1].strip () != "") {
                string char_name = line.has_prefix ("@") ? line.substring (1).strip () : line;
                append_paragraph (xml, "Character", char_name);
                in_dialogue = true;
                i++;
                continue;
            }

            // Default: Action
            append_paragraph (xml, "Action", line);
            i++;
        }

        xml.append ("  </Content>\n");
        xml.append ("</FinalDraft>\n");
        return xml.str;
    }

    // Check if a Fountain line is a scene heading (INT., EXT., etc.)
    public bool is_scene_heading (string line) {
        string lower = line.down ();
        return lower.has_prefix ("int.") || lower.has_prefix ("int ") ||
               lower.has_prefix ("ext.") || lower.has_prefix ("ext ") ||
               lower.has_prefix ("est.") || lower.has_prefix ("est ") ||
               lower.has_prefix ("int/ext.") || lower.has_prefix ("int/ext ") ||
               lower.has_prefix ("i/e.") || lower.has_prefix ("i/e ");
    }

    // Check if a Fountain line looks like a character cue (ALL CAPS, or @-prefixed)
    private bool is_character (string line) {
        if (line.has_prefix ("@")) {
            return true;
        }
        // Must be ALL CAPS and not a parenthetical
        if (line.has_prefix ("(")) {
            return false;
        }
        return line.length > 0 && line == line.up ();
    }

    // Check if a Fountain line is a transition (ends with TO: or common fade phrases)
    private bool is_transition (string line) {
        return line.has_suffix (" TO:") || line.has_suffix ("\tTO:") ||
               line == "FADE OUT." || line == "FADE OUT" ||
               line == "SMASH CUT TO:" || line == "MATCH CUT TO:" ||
               line == "FADE TO BLACK.";
    }

    // Write a single <Paragraph> with <Text> content to the FDX XML builder.
    // XML special characters in text are escaped.
    private void append_paragraph (StringBuilder xml, string type, string text) {
        string escaped = text
            .replace ("&", "&amp;")
            .replace ("<", "&lt;")
            .replace (">", "&gt;")
            .replace ("\"", "&quot;");
        xml.append ("    <Paragraph Type=\"" + type + "\">\n");
        xml.append ("      <Text>" + escaped + "</Text>\n");
        xml.append ("    </Paragraph>\n");
    }
}
