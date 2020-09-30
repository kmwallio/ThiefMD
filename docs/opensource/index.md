---
layout: page
title: Open Source
---

# Open Source Components

We're making ThiefMD components reusable. You can find the components in at [GitHub.com/ThiefMD](https://github.com/thiefmd)

- [libwritegood](#libwritegood)
- [ultheme-vala](#ultheme-vala)
- [ThiefMD](https://github.com/kmwallio/ThiefMD)

## libwritegood

[libwritegood](https://github.com/ThiefMD/libwritegood-vala) is like [GtkSpell](http://gtkspell.sourceforge.net) for style. libwritegood is based on [btford/write-good](https://github.com/btford/write-good). It's easy to use, for example:

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
// WriteGood doesn't auto-check for changes, may be too compute heavy for large docs
//
buffer.changed.connect (() => {
    checker.recheck_all ();
});
```

## ultheme-vala

A converter for [Ulysses Themes](https://styles.ulysses.app/themes) to markdown [GtkSouceView Style Schemes](https://wiki.gnome.org/Projects/GtkSourceView/StyleSchemes).

ultheme-vala converts a ultheme package into both a light and dark GtkSourceView Style Scheme. In ThiefMD, [we load the file](https://github.com/kmwallio/ThiefMD/blob/master/src/Widgets/ThemeSelector.vala#L176) and then [persist the theme to disk](https://github.com/kmwallio/ThiefMD/blob/master/src/Widgets/ThemePreview.vala#L50).
