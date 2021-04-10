---
layout: page
title: Open Source
---

# Open Source Components

We're making ThiefMD components reusable. You can find the components in at [GitHub.com/ThiefMD](https://github.com/thiefmd). We're also built on top of [other great open source software](/about/#credit)

- [libwritegood](#libwritegood)
- [writeas-vala](#writeas-vala)
- [ghost-vala](#ghost-vala)
- [wordpress-vala](#wordpress-vala)
- [BibTeX-vala](#BibTeX-vala)
- [Theme Generator](#theme-generator)
- [ultheme-vala](#ultheme-vala)
- [Stolen Victory Duo](#stolen-victory-duo)
- [ThiefMD](https://github.com/kmwallio/ThiefMD)

## libwritegood

[libwritegood](https://writegood.thiefmd.com) is like [GtkSpell](http://gtkspell.sourceforge.net) for style. libwritegood is based on [btford/write-good](https://github.com/btford/write-good). It's easy to use, for example:

```vala
var manager = Gtk.SourceLanguageManager.get_default ();
var language = manager.guess_language (null, "text/markdown");
var view = new Gtk.SourceView ();
buffer = new Gtk.SourceBuffer.with_language (language);
buffer.highlight_syntax = true;
view.set_buffer (buffer);
view.set_wrap_mode (Gtk.WrapMode.WORD);

//
// Enable write-good
//

checker = new WriteGood.Checker ();
checker.set_language ("en_US");
checker.attach (view);

//
// Disable hard sentences
//
checker.check_hard_sentences = false;

//
// Quick check only scans around the last check cursor position, and
// and the current cursor position
//
buffer.changed.connect (() => {
    checker.quick_check ();
});

//
// Recheck all will scan the entire document
//
buffer.paste_done.connect ((clipboard) => {
    checker.recheck_all ();
});
```

## Writeas-vala

[writeas-vala](https://github.com/ThiefMD/writeas-vala) is a [Write Freely](https://writefreely.org) client library. It can be used for submitting and managing posts on [Write.as](https://write.as) or any other Write Freely instance.

## Ghost-vala

[Ghost-vala](https://github.com/ThiefMD/ghost-vala) is a simple library for publishing posts to [ghost](https://ghost.org) blogs.

## WordPress-vala

[WordPress-vala](https://github.com/ThiefMD/wordpress-vala) is a simple library for publishing posts to [WordPress](https://wordpress.org) blogs. It contains some workarounds and retries for some common issues.

## BibTeX-vala

[BibTeX-vala](https://github.com/ThiefMD/BiBtex-vala) is a quick processor for [BibTeX](http://www.bibtex.org) files. It generates a HashMap of items in the BibTeX file and allows for querying a list of the labels and getting a title for the label.

```vala
public static void main () {
    // Set file
    BibTex.Parser parser = new BibTex.Parser ("test.bib");
    // Parse
    parser.parse_file ();

    // Print labels and titles
    foreach (var label in parser.get_labels ()) {
        print ("%s - %s\n", label, parser.get_title (label));
    }
}
```

## Theme Generator

![](https://raw.githubusercontent.com/ThiefMD/theme-generator/master/theme-generator.png)

[Theme Generator](https://github.com/ThiefMD/theme-generator) helps generate Markdown editor themes for [Ulysses](https://ulysses.app) and [GtkSourceView](https://wiki.gnome.org/Projects/GtkSourceView) based editors.

Have a consistent writing environment no matter where you're at.

## ultheme-vala

[ultheme-vala](https://github.com/TwiRp/ultheme-vala), a converter for [Ulysses Themes](https://styles.ulysses.app/themes) to markdown [GtkSouceView Style Schemes](https://wiki.gnome.org/Projects/GtkSourceView/StyleSchemes).

ultheme-vala converts a ultheme package into both a light and dark GtkSourceView Style Scheme. In ThiefMD, [we load the file](https://github.com/kmwallio/ThiefMD/blob/master/src/Widgets/ThemeSelector.vala#L176) and then [persist the theme to disk](https://github.com/kmwallio/ThiefMD/blob/master/src/Widgets/ThemePreview.vala#L50).

```vala
public static int main (string[] args) {
    var ultheme = new Ultheme.Parser (File.new_for_path (args[1]));
    // Display resulting Dark Theme XML for GtkSourceView
    print (ultheme.get_dark_theme ());

    return 0;
}
```

## Stolen Victory Duo

[Stolen Victory Duo](https://github.com/ThiefMD/StolenVictoryDuo) is a mashup of [iA Writer Duospace](https://github.com/iaolo/iA-Fonts/tree/master/iA%20Writer%20Duospace) with [Victor Mono](https://rubjo.github.io/victor-mono/). It aims to be digitally authentic with human approachability.

You can try it here:

<textarea id="stolen-text" class="duo">
# Stolen Victory Duo
Is a mash up of **iA Writer Duospace** and *Victor Mono* with adjustments to have more curvature and wider spacing for certain characters.

The quick brown fox jumped over the lazy dog.
*The quick brown fox jumped over the lazy dog.*
THE QUICK BROWN FOX JUMPED OVER THE LAZY DOG.
*THE QUICK BROWN FOX JUMPED OVER THE LAZY DOG.*
</textarea>

<script>
    var simplemde = new SimpleMDE({ element: $("#stolen-text")[0] });
</script>