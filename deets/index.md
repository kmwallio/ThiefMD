---
layout: page
title: Details
---
<div class="jumbotron">
  <h1>ThiefMD isn't your average text editor</h1>
  <p><a href="https://blog.thiefmd.com/introducing-fountain-support/">Fountain Support</a>, <a href="/tips/blogging-with-ghost/">Blog Publishing</a>, and so much more. It's too much for one page.</p>
  <p><a class="btn btn-primary btn-lg" href="/deets/list" role="button">Check out a List of Features</a> <a class="btn btn-primary btn-lg" href="/shortcuts" role="button">Learn our Keyboard Shortcuts</a></p>
</div>

## Live Preview

<div class="responsive-right marcel"><img src="/images/preview.png" alt="ThiefMD's Live Preview Mode" /></div>

`Ctrl + Shift + P` and see your markdown rendered instantly. Live preview updates as you type.

Relative paths? Absolute paths? Don't worry, ThiefMD finds the images you're looking for.

A separate window lets allows for better positioning, or multi-monitor support. Focus on your writing, or focus on your reading.

Customize the results with [Export Styles](/tips/export-styles). Just a little CSS, and you can see how the results will look on your blog, PDF, or ePUB. [See what people have shared](https://themes.thiefmd.com/export-css).

<div class="clear"></div>

## Compilation & Multi-Format Export

<div class="responsive-left-short hoffman"><img src="/images/export_menu.png" alt="ThiefMD showing the export menu" /></div>

Writing a novel is no easy feat. Epic undertakings are easier to accomplish broken down into feasible tasks. The same thing goes for [great writing](/tips/novel-writing).

ThiefMD supports [exporting your work](/tips/novel-writing#sharing-your-work) from multiple folders and files.

Publish to PDF to send to friends over e-mail. [ePub](https://en.wikipedia.org/wiki/EPUB) if you want to preview your novel in your favorite e-Reader. docx or LaTeX if you're getting ready to turn in that report or dissertation.

Make a [Connection](/tips/blogging-with-ghost/), and you can publish to [Ghost](https://ghost.org), [WordPress](https://wordpress.org), [Medium](https://medium.com), [Forem](https://forem.com), or [WriteFreely](https://writefreely.org).

However large the task and wherever you need to take it, ThiefMD has you covered[^okay-its-pandoc].

[^okay-its-pandoc]: Export powered by [Pandoc](https://pandoc.org). [Let us know](https://github.com/kmwallio/ThiefMD/issues) if we don't have you covered.

<div class="clear"></div>

## Write-Good

<div class="responsive-right jonas"><img src="/images/write-good.png" alt="ThiefMD highlighting and suggesting writing improvements" /></div>

[Write-good](https://github.com/ThiefMD/libwritegood-vala) <span style="background: #0b8370; color: #FFF" title="Passive voice found, be active">was added</span> to ThiefMD to help check for passive voice.

Powered by logic stolen from [btford/write-good](https://github.com/btford/write-good), ThiefMD can help improve your writing.

No more:
* Weasel words
* Passive voice
* Long and Complex Sentences
* Meaningless Wordy Words
* *and more*

Toggle it on, or toggle it off. They're <span style="background: #20528c; color: #FFF" title="Weak word found, be forceful">only</span> suggestions. <span style="background: #564a5e; color: #FFF" title="This sentence is very hard to read">Whether you've found your voice, looking for your voice, or writing in multiple voices, ThiefMD will help you get to where you want to be.</span>

<div class="clear"></div>

## Grammar Check and Notes

<div class="responsive-left marcel"><img src="/images/grammar-notes.png" alt="ThiefMD highlighting potential grammar issues with notes pane open" /></div>

Not all of us are whoever the Picaso of the writing world would be, but with Write-Good + Grammar Check, your writing can look like a Picaso! None of us here have an English Degree, but ThiefMD will attempt to highlight what's potentially wrong.

Our grammar checker uses the revolutionary [Link Grammar Parser](https://www.abisource.com/projects/link-grammar/), the same grammar checking in [AbiWord](http://www.abisource.com/), so you know it's good.

With Link Grammar, you'll be saying "*[Hyah!](https://www.youtube.com/watch?v=q7IfOwcaxwc)*" to bad Grammar in no time[^fn-link-joke].

[^fn-link-joke]: *Link* Grammar... Grammar check is always green... get it...? I don't know why they let me update the site. These are the jokes kid 😼.

**Noted.** ThiefMD also lets you take notes for the file you are working on or for the project you are in. Notes aren't part of your work but are great for keeping track on it.

<div class="clear"></div>

## Typewriter Scrolling

![ThiefMD's typewriter scrolling feature](/images/typewriter_scrolling.gif)

Stay centered and stay focused. Type writer scrolling keeps your active line fixed, both in the editor and the preview.

No longer look for where you're typing, keep your eye muscles on what matters most.

## Focus Mode

<div class="responsive-left jonas"><img src="/images/focus_mode.png" alt="ThiefMD dimming all text except for the sentence being modified" /></div>

Eliminate distractions with focus mode. Paired with [typewriter scrolling](#typewriter-scrolling), ThiefMD can help keep you focused.

Don't get distracted by mark-up, other sentences, or multiple colors on the screen. Focus mode provides two colors: the background and your text.

You can focus by paragraph, sentence, or word. Paragraph Focus keeps things in context. Sentence focus prevents editing and revision while you write. Word focus keeps content flowing without looking back.

And yes, it works with [any theme you could throw at it](https://themes.thiefmd.com)[^if-not-file-a-bug].

[^if-not-file-a-bug]: If it doesn't please [let us know](https://github.com/kmwallio/ThiefMD/issues).

<div class="clear"></div>

## YAML Frontmatter

<div class="responsive-right marcel"><img src="/images/jekyll-minimark.png" alt="ThiefMD rendering YAML frontmatter" /></div>

Use [Jekyll](https://jekyllrb.com), [Hugo](https://gohugo.io), or another [Static Site Generator](https://www.staticgen.com/)?

ThiefMD surfaces the [front matter](https://jekyllrb.com/docs/front-matter) in the Folder View using minimark.

Live preview also renders any `title:` making your post look like art.

Our [export logic](/tips/novel-writing#novel-metadata) also understands [whatever metadata you may throw at it](https://pandoc.org/MANUAL.html#epub-metadata).

<div class="clear"></div>

## KaTeX Support

<div class="responsive-left jonas"><img src="/images/katex_preview.png" alt="ThiefMD rendering a complex math formula" /></div>

We do not like math, but we'll support it.

Use [KaTeX](https://katex.org) to render Math Equations in Previews.

This requires libmarkdown 2.2.0 or greater. Using [flatpak](https://flathub.org/apps/details/com.github.kmwallio.thiefmd) will let ThiefMD use the latest and greatest versions of its dependencies. Ubuntu 20.04 won't have Math Previews, but Fedora 32+ and Ubuntu 20.10 will.

For more power, [LaTeX](https://www.latex-project.org) export will have you looking professional.

Export and finalize your work in [TeXstudio](https://flathub.org/apps/details/org.texstudio.TeXstudio), [Setzer](https://flathub.org/apps/details/org.cvfosammmm.Setzer), or your favorite LaTeX editor.

The sky's the limit, and ThiefMD will help get you there.

<div class="clear"></div>

## Syntax Highlighting

<div class="responsive-right hoffman"><img src="/images/syntax_preview.png" alt="ThiefMD syntax highlighting Vala code in various colors" /></div>

Writing a dev blog? Updating your [DocFX](https://dotnet.github.io/docfx)?

[highlight.js](https://highlightjs.org) makes code shine. And since it's in ThiefMD, ThiefMD will make your code shine too!

I guess it's true what they say: the magic was inside ThiefMD all along.

<div class="clear"></div>

## Import from almost Anywhere

<div class="responsive-left-short marcel"><img src="/images/import-epub.png" /></div>

Already started your work in [LibreOffice Writer](https://www.libreoffice.org/discover/writer)? Published your ePUB but need to make some changes? ThiefMD has your back.

Whether you're stealing something from the Public Domain or improving your own work, ThiefMD won't judge you. ThiefMD will assist you.

DocX, Odt, HTML, and other file acronyms can be dragged into the Library. Watch in wonder as they convert to Markdown under the covers.

Once you've made your changes, feel free to export them back. Or even [export them to something else](/tips/novel-writing#sharing-your-work).

<div class="clear"></div>

## Theme Support

<div class="responsive-right jonas"><img src="/images/theme_preferences.png" alt="ThiefMD skinned in various vibrant colors" /></div>

Light Theme, Dark Theme, Pink or Blue, make ThiefMD unique to you.

Browse [themes created for ThiefMD](https://themes.thiefmd.com/), or import your favorite [Ulysses Themes](https://styles.ulysses.app/themes)[^ulysses-the-best]. If you're feeling daring, [make your own with our theme generator](https://themes.thiefmd.com/howto).

[^ulysses-the-best]: [Ulysses](https://ulysses.app) is our writing tool of choice on [macOS](https://www.apple.com/macos) and our [theme generator](https://themes.thiefmd.com/howto) is a great way to make us match. ThiefMD is not affiliated with Ulysses.

In the Preferences Window (`Ctrl + ,`), you can now drag themes into the app.

Get immersed and match the whole UI or keep the colors for your words.

Discover more themes at [https://themes.thiefmd.com](https://themes.thiefmd.com) or [make your own](https://themes.thiefmd.com/howto) from scratch.

<div class="clear"></div>

## Super Fast Search

<div class="responsive-left jonas"><img src="/images/thief_search.png" alt="ThiefMD showing library search and highlighting in current file" /></div>

Whether you know where you're looking or what you're looking for, ThiefMD will help you get there.

`Ctrl+F` to search the current file.

`Ctrl+Shift+F` searches your entire library. Want to search a specific area? Right-click on the Library Item and choose "Search Item".

Get lost in your writing and find your way back to wherever you need to go, all within ThiefMD.

<div class="clear"></div>

## Writing Statistics

<div class="responsive-right marcel"><img src="/images/writing_statistics.png" alt="ThiefMD tracking statistics for a whole project and an individual chapter" /></div>

Working on [NaNoWriMo](https://nanowrimo.org)? Making sure you hit your book report's word count? Trying to make progress on a chapter?

Keep track of it all with Writing Statistics. Turn it on or off in the preferences.

Right-click on a Library Item to pop out a window tracking a project or chapter. Or enable the status bar for tracking the file you're working on.

Currently key bound to `Ctrl+Shift+S` until we can think of something better.

<div class="clear"></div>

## Fountain Support

<div class="responsive-left hoffman"><img src="/images/thiefmd-screenplay.png" alt="ThiefMD tracking statistics for a whole project and an individual chapter" /></div>

We all know your best selling novel will become an award winning movie.

Start both drafts in ThiefMD thanks to [Fountain](https://fountain.io) support.

All caps for a CHARACTER followed by some text is dialogue. `EXT. PLACE` to change the setting. It's just that easy to start your journey to the big screen[^maybe-not-that-easy].

[^maybe-not-that-easy]: The journey will be pretty tough, but you'll never make it without taking the first step.

<div class="clear"></div>

## BibTeX Support

![Right-Click Insert Citation Support](https://user-images.githubusercontent.com/132455/112594422-23499d00-8dc6-11eb-8bd6-b6b6bcc28f7f.gif)

Use [BibTeX](http://www.bibtex.org) to manage your citations? ThiefMD can dig that.

Use [JabRef](https://www.jabref.org) or your favorite citation manager to modify your BibTeX. Watch in Wonder as ThiefMD offers to insert citations from its right-click menu.

<div class="clear"></div>

***

<small>The photo of Wheat is by [Matt Hoffman](https://unsplash.com/@__matthoffman__), more Wheat by [Jonas Zürcher](https://unsplash.com/@tsueri), and even more wheat by [Gaelle Marcel](https://unsplash.com/@gaellemarcel).</small>

***