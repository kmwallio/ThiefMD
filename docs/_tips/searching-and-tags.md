---
layout: page
title: Searching and Tags
thieftags: #novel-writing, #searching
---

# Something like Tags in ThiefMD

Depending on how you organize your project, you may want to tag items as #needs-improvement, #todo, or #mc (main-character). Tagging and finding relevant files is a powerful feature of other Markdown Editors, like [Ulysses](https://ulysses.app/tutorials/keywords), [Bear](https://blog.bear.app/2020/05/getting-started-with-using-and-organizing-tags-in-bear/), [Notes-up](https://flathub.org/apps/details/com.github.philip_scott.notes-up), [iA Writer](https://ia.net/writer/blog/write-to-organize), and more.

ThiefMD doesn't have this yet, but it does have Library Search (`Ctrl+Shift+F`) with a live-update mode.

## Ways of Adding Tags

### YAML Front Matter

If you're writing a novel, blog post, or planning on publishing your work in other ways, YAML front-matter is one way to keep your tags. This will prevent them from being added to your word count and appearing in your work.

<div class="responsive-right-short jonas">
<img src="/images/searching-and-tags/tag-search.png" />
</div>

At the start of your file, you can add:

```yaml
---
title: My Fancy Title
thieftags: #tips, #more-tags
---
```

You don't have to call it thieftags, but tags or categories is a YAML keyword in many static site generators. You could also choose a different character from `#`.

### Just Use #Hashtags

If you're using ThiefMD for notes, it's easy just to **#hashtag** in the middle of your writing. No need to scroll to the top of the page, and no need to put in formatting or control characters.

### Comment it Out

Have a paragraph you want to come back to? A tag hidden in your YAML frontmatter might not be as useful. Here, you can use HTML comments[^fn-or-dont].

[^fn-or-dont]: For things needing improvement, #needs-improvement on a line by itself might be good enough. Accidentally send it to your editor, and you'll get a call reminding you a section of your work needs improvement.

```html
    <!-- #needs-improvement -->
```

Put this above or in the paragraph, and you'll be able to quickly find and jump to it from the search.

## Finding Tags

Open the Library Search (`Ctrl+Shift+F`), enter in your #tag and click enter. This will display all your files that contain the tag.

See the little slider switcher? This tells the search to monitor for file changes. Anytime you modify a file in the library, the search will rerun surfacing any new files that contain the tag.

Just remember to be consistent with your tag names, and you'll be tagging and writing in no time.

Happy Writing!

<div class="clear"></div>