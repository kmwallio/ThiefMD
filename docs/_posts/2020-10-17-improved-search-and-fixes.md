---
layout: post
title: Improved Search, Focus Mode, Hide the Toolbar, and Fixes
date: 2020-10-17 14:38
---

We were a bit eager with the last release. We fixed crashes in the Library Search and now sort by the number of occurrences of the search in each document. There's an essay of changes if you're willing to read them.

<!-- more -->

Search is now a modal window and you can have 'live search' which will update the search results as you type. This is an alternative for [tagging and labels](/tips/searching-and-tags) until we have a story around that. Don't want to search the *whole* library? Right-click on a Library Item and choose search.

For exporting, you can now disable the `title:` in the YAML from appearing in the exported document. Since there's so many export options, it now has a scrollbar to [prevent it from growing off screen](https://github.com/kmwallio/ThiefMD/issues/68).

In addition to more export options, need to export an Individual file? Just right-click on the file and choose Export. Same Novel-Level Export Powers for your individual files. United or Apart, your files look great.

The header bar can now be hidden with `Ctrl+Shift+H` to eliminate more distractions. We're working on making it look and function better, so let us know any issues you run into. Speaking of looking better, [custom fonts](https://github.com/kmwallio/ThiefMD/issues/69) are here. We included our favorite Serif and Sans-Serif fonts, but everyone has their own tastes and environments that help the creative juices flow.

Files can now be dragged into the editor window. If ThiefMD thinks it knows what it is, it will Markdown-ify the content as best it can.

Talking about dragging things into the editor, certain languages are now syntax highlighted in code blocks. Sharing some code, drag the file in and bam. It's like magic, but not (it's programming).

And for dragging things around, ThiefMD now monitors for folder changes. Delete, move, or create files using your File Manager or another app. [Outline](https://appcenter.elementary.io/com.github.phase1geo.outliner) your novel, then export the Markdown into your ThiefMD Library. ThiefMD will notice those changes and show them in the Library.

You can now Sort files by their Title or Date. This information is extracted from the YAML front matter (or any close guess we can come up with).

We also added a focus mode. Choose to focus on words, sentences, or paragraphs. ThiefMD dims everything but the content you're working on. With [plenty of themes](https://themes.thiefmd.com) and Fonts to choose from, Type Writer Scrolling, Focus Mode, a minimal UI, we're hoping you can create your ideal writing environment.

We know when writing your novel you have many options. Thanks for choosing ThiefMD, and be sure to let us know if there's anything we can do to make your stay more comfortable.

Other Updates:

 * Write-Good now highlights the whole phrase for passive voice or weasel words
 * Write-Good highlighting accounts for emoji and unicode characters
 * ThiefMD uses OS Path separator character in all instances
 * New Markdown Cheat Sheet (`Ctrl+H`)
 * Preview and Publisher Windows can now be full screened (`F11`)
 * In addition to custom fonts, you can now change the font size too
 * More hidden keyboard shortcuts. `Ctrl+Shift+T`: Typewriter Scrolling, `Ctrl+Shift+W`: Write Good. Full-Screen `F11`, Type-Writer Scrolling `Ctrl+Shift+T`, Editor View `Ctrl+1`, and then Focus `Ctrl+Shift+R` all without leaving the comfort of your keyboard
 * YAML Frontmatter now syntax highlighted as a comment
 * CSV to Markdown Table on Drag and Drop
