---
layout: page
title: Novel Writing
thieftags: #novel-writing, #markdown
---

ThiefMD is great for organizing your markdown documents. With the ability to drag and drop to organize the order of your library, then export your work with a few clicks, ThiefMD can make compiling an epic story into a tiny task.

- [Git for Writers](#git-for-writers)
- [Markdown for Writing?](#markdown-for-writing)
- [Structuring Your Novel](#structuring-your-novel)
- [Novel Metadata](#novel-metadata)
- [Sharing your Work](#sharing-your-work)
- [Importing Existing Work](#importing-existing-work)
- [Getting in the Zone](#getting-in-the-zone)
- [Writing on Multiple Devices](#writing-on-multiple-devices)

## Git for Writers

<div class="responsive-right-short hoffman"><img src="/images/preview.png" alt="ThiefMD's Live Preview Mode" /></div>

We recommend using [GitHub](https://github.com) or [GitLab](https://gitlab.com) as a way to store and backup your work. This [Guide to Git and GitHub for Writers](https://www.scrygroup.com/tutorial/2020-01-07/guide-to-git-github-for-writers) would be a good place to brush up on [git](https://git-scm.com/) if you're not familiar with git already. D. Moonfire has a great post on [how he uses GitLab to manage his writing](https://d.moonfire.us/blog/2015/05/09/gitlab-projects).

While ThiefMD has been mildly tested, data loss, file sync conflicts, and good old fashion acts of God can happen. Using Git will provide peace of mind knowing you can always recover your work, or find that sentence you deleted that wasn't "good enough" at the time.

## Markdown for Writing?

[Markdown](https://daringfireball.net/projects/markdown) isn't just for programmers anymore. Markdown makes it easy for writers [to focus and write](https://www.fastcompany.com/40586767/for-focused-writing-markdown-is-your-best-friend).

With minimal effort to learn and remember, using Markdown will remove all of the hassle of learning a specific editing program, struggling with document formatting and design, and getting stuck in vendor lock-in.

ThiefMD is a Markdown Editor that lets you focus on your words.

<div class="clear"></div>

## Structuring Your Novel

We have a [sample novel project](https://github.com/ThiefMD/sample-novel) on GitHub featuring the first 5 chapters of Lewis Carrol's [Alice's Adventures in Wonderland](https://www.gutenberg.org/ebooks/28885).

We like breaking down our projects into:

```
/Novel
/Novel/title-page.md
/Novel/Chapter-01/Part-1.md
/Novel/Chapter-01/Part-2.md
/Novel/Chapter-01/Part-3.md
/Novel/Chapter-02/Part-X.md
/Novel/Chapter-0Y/...
```

where each part is a scene in our chapter.

If you wanted to, you could structure your novel like:

```
/Novel/title-page.md
/Novel/Chapter-01.md
/Novel/Chapter-02.md
/Novel/...
```

and ThiefMD would still export your work to the desired format. You could even write your entire novel in a single markdown file, and ThiefMD would still be able to produce your ePub.

Work in whatever way keeps you comfortable and helps you write. We'll do our best to stay out of the way.

## Novel Metadata

The title page contains our novel's metadata. When using metadata, make sure to tell ThiefMD the first file in the project includes the [author metadata](https://pandoc.org/MANUAL.html#epub-metadata).

<div class="responsive-center marcel" style="overflow: hidden; height: 200px"><img src="/images/export_preferences.png" /></div>

The metadata in `title-page.md` should look something like:

```yaml
---
title: My Great Novel
author: My Name
cover-image: /images/cover.png
---
```

During export, this will be embedded into the resulting ePub.

<div class="responsive-center marcel"><img src="/images/epub-export.png" alt="Export Preview Window and resulting ePub" /></div>

<div class="clear"></div>

## Sharing your Work

![](/images/export_preview.png)

<div class="responsive-left-short hoffman"><img src="/images/export_menu.png" alt="Menu screenshot showcasing Export Preview option" /></div>

Ready to share your work?

Right-click on the folder you want to publish and click `Export Preview`. Items will be organized the same way they're kept in ThiefMD.

This will bring up the `Publishing Preview` window. Double check that everything you want is there just the way you want it.

<div style="clear: both"></div>

<div class="responsive-right-short"><img src="/images/export_preferences.png" alt="Export Preferences Dialog" /></div>

Once you're ready, click on the `Export` button.

Pick a place for your great work and pick a name.  Currently, ThiefMD supports PDF, DocX, [ePub](https://en.wikipedia.org/wiki/EPUB), HTML, [MHTML](https://en.wikipedia.org/wiki/MHTML), [LaTeX](https://www.latex-project.org/), and Markdown export.

ThiefMD will generate the output based on the filename. `my-great-work.pdf` will create a PDF. `my-great-work.mhtml` will generate an HTML page with any images embedded into the same file. `my-great-work.md` will convert every single markdown file selected into a single markdown file you can share.

Things not looking quite as planned? In the Export Preferences `Ctrl + ,` you can tweak the results based on how you organized your library.

Want more advanced control of how your book looks? [Export Styles](/tips/export-styles) requires a little CSS know-how to get your book looking great.

<div style="clear: both"></div>

## Importing Existing Work

<div class="responsive-left-short marcel"><img src="/images/import-epub.png" /></div>

Already working on something great? If it's a folder of Markdown files, just drag it into the Library.

Coming from DocX, OPT, HTML, or something else? Made an ePUB and lost the source Markdown? Drag the file onto an existing folder in the Library, and if ThiefMD supports it, it will convert the file to Markdown.

Files containing image assets (like DocX, OPT, or ePub) will have their images added to the library.

You'll have to re-add your [novel's metadata](#novel-metadata), but it beats having to type the whole thing over again.

<div class="clear"></div>

## Getting in the Zone

![](/images/typewriter_scrolling.gif)

Typewriter scrolling helps keep you centered.  The current line is always in the middle of the screen.

You can keep writing without having to touch the scroll-bar to keep the cursor in your favorite position.

`Ctrl + 1` will change in Editor Only mode. Eliminate distractions and focus on the current sheet on hand.  Want even less distraction? `F11` will enter full-screen. No title-bar, no desktop background, no distraction. `F11` or `Esc` can help return you back to the world of noise.

`Ctrl + 2` will switch to Editor + Current Folder view. Want to keep focused on a single chapter and break the chapter into multiple files? This view is for you. Drag and drop files to reorder, and quickly switch between them with just a click.

`Ctrl + 3` will take you back to the Library view.

<div class="hoffman"><img src="/images/theme_preferences.png" alt="Screenshot of multiple themes for ThiefMD" /></div>

Make the editor your own. [We have a selection of themes available](https://themes.thiefmd.com), and ThiefMD can load your favorite [Ulysses themes](https://styles.ulysses.app/themes). Find a theme that encourages you to write and get in the zone or [make your own](https://themes.thiefmd.com/howto).

## Writing on Multiple Devices

Have multiple devices? Git is a secure way to keep things in sync and have history, but it might not work on your mobile device[^working-copy].

[^working-copy]: [Working Copy](https://workingcopyapp.com/) on iOS will let you checkout a git repo on your iPhone or iPad. [Ulysses](https://ulysses.app/integrations/workingcopy) or [iA Writer](https://thesweetsetup.com/how-ive-set-up-ia-writer-after-moving-from-ulysses) support integration with Working Copy.

[DropBox](https://www.dropbox.com) is useful for syncing files between mobile, laptop, and desktop devices. ThiefMD still has some issues with detecting file changes, so be careful if your plan doesn't support file history.

ThiefMD doesn't lock you into a specific format or editor, so you could use [Ulysses](https://ulysses.app) on your Mac, [iA Writer](https://ia.net/writer) on your iPhone, [Visual Studio Code](https://code.visualstudio.com) or [Typora](https://typora.io) on Windows, and [markor](https://github.com/gsantner/markor) on Android.

These are just suggestions. Markdown is plain-text, so you're not locked in.

There's a world of editors out there. We're glad you choose ThiefMD to be one of yours.

## Now Get Writing!

ThiefMD won't lock you in, and now you know how to get your work out and keep things in sync.