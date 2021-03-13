---
layout: post
title: Stability And Improvements
date: 2021-03-13 13:03:35
---
[WordPress](https://wordpress.org) got a huge update with [Featured Image](https://wordpress.com/support/featured-images/).
In the YAML, just add `cover-image` or `featured-image` to the frontmatter.

```yaml
---
title: My Fancy Blogpost
featured-image: /images/my-featured-image.jpeg
---
```

Publishing to [Write.as](https://write.as) and have a Pro Account? [Snap.as](https://snap.as) image uploading is now supported.

## New Translations

Did you know [Poeditor](https://poeditor.com/join/project?hash=iQkE5oTIOV) can be used to help translate ThiefMD? People have been submitting translations:

 * French Translation by [David Bosman](https://github.com/davidbosman)
 * Slovak Translation by [Marek L'ach](https://github.com/marek-lach)
 * Swedish Translation by [Åke Engelbrektson](https://github.com/eson57)

Thanks to everyone contributing!

## UI Accessibility

We've added borders to sheets in the sidebar when using the OS Theme.

## Stability Improvements

We've improved how heading margins are calculated, which means... we've relaxed font selection. You're still only limited to the family, but more should appear in the selector.

We've lowered the chances of crashing in experimental mode. When selecting text with experimental mode, bold links will become normal font as [invisible text can cause a crash if formatted differently from surrounding text](https://stackoverflow.com/a/59314509).

## Bug Fixes

Fixed and issue where PDF export tried using non-PDF themes.

## More to come...

We're still working on Tagging and Categories for WordPress and Ghost. Checkout the [ThiefMD Project Board](https://github.com/kmwallio/ThiefMD/projects) to see what we have planned, and let us know how we can empower you to do more!