---
layout: page
title: Blogging with Jekyll
---

If you're looking to start a blog, consider [Jekyll](https://jekyllrb.com/). You'll be able to publish on [GitHub](https://pages.github.com/), [GitLab](https://docs.gitlab.com/ee/user/project/pages/), or any other host.

ThiefMD will make it easy to manage and update your site's content.

This article assumes you already have a Git repository setup with your Jekyll install.  Jekyll has an in-depth guide [online here](https://jekyllrb.com/docs/step-by-step/01-setup/).

## Creating a Post

<div class="responsive-right jonas"><img src="/images/create_post.png" alt="Application screenshot showing creation of a new blog post" /></div>

Creating a post is easy. Select `_posts` in the Library, click on the `New Post` icon, and enter in a filename `YYYY-MM-DD-title`.

This will create a new markdown file for you to write in.

<div class="clear"></div>

### YAML Frontmatter

<div class="responsive-left hoffman"><img src="/images/thief_frontmatter.png" alt="Application screenshot showing rendering of YAML frontmatter" /></div>

Each post begins with some YAML markup telling Jekyll the title, publish time, categories, and layout. Simply right-click and `Insert YAML Frontmatter`, and ThiefMD will generate the front matter for you based on the current file. ThiefMD will only provide the minimum needed frontmatter. Need to update the post time of the article? There's a menu item for that as well.

Front matter usually looks like:

```yaml
---
layout: post
title: My Super Awesome Blog Post
date: 2020-10-05 11:38
---
```

If you're using [themes](https://jekyllrb.com/docs/themes), the layout says what template to use. Most themes have `page` and `post`. The `date` is the publishing time. Adding `categories` can help readers find related posts or build good archive pages. `tags` are also supported by Jekyll.

On some versions of Jekyll, Jekyll won't publish the post until after the `date`.  This makes it useful for drafting or scheduling articles.

You can read more in [Jekyll's Documentation](https://jekyllrb.com/docs/front-matter). Many of these tips also work with [Hugo](https://gohugo.io) and other static site generators.

<div class="clear"></div>

### Moving Posts

<div class="responsive-right"><img src="/images/drag_n_drop_sheets.gif" alt="Application animation showing drag and drop support of posts" /></div>

If you're worried about accidentally publishing something, you can create posts in a `_drafts` folder instead.  Once you're ready to publish, simply drag and drop the post from `_drafts` to `_posts`, then commit your changes.

## Too Many **_posts**?

Sort your files by Filename.

By default, files are created at the bottom of the Folder view.  Sorting by Filename ascending will have your **newer** posts at the bottom of the screen.

Sorting by descending will have newer posts at the top, but any new post will be located at the bottom.  Just re-run the sort, and your post will be right where you want it.

<div class="clear"></div>

### Committing

[gitg](https://wiki.gnome.org/Apps/Gitg/) is a useful tool for managing git repositories and committing your posts.

![](/images/gitg_post.png)

First, stage your changes. Then click `commit` in the lower right corner. After committing, you can go back into the timeline view to push your changes back onto the remote.

![](/images/gitg_push.png)
