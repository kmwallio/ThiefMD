---
layout: page
title: Blogging with Jekyll
thieftags: #blogging
---

If you're looking to start a blog, consider [Jekyll](https://jekyllrb.com/). You'll be able to publish on [GitHub](https://pages.github.com/), [GitLab](https://docs.gitlab.com/ee/user/project/pages/), or any other host.

ThiefMD makes it easy to manage and update your site's content.

This article assumes you already have a Git repository setup with your Jekyll install.  Jekyll has an in-depth guide [online here](https://jekyllrb.com/docs/step-by-step/01-setup/).

## Creating a Post

<div class="responsive-right-short jonas"><img src="/images/create_post.png" alt="Application screenshot showing creation of a new blog post" /></div>

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

You can configure Jekyll so it won't publish the post until after the `date`.  This makes it useful for drafting or scheduling articles.

You can read more in [Jekyll's Documentation](https://jekyllrb.com/docs/front-matter). Many of these tips also work with [Hugo](https://gohugo.io) and other static site generators.

<div class="clear"></div>

## Updating the _config.yml for Drafts

### Using _drafts folder

By default, items in the `_drafts` folder are excluded from being built and previewed. If you want the drafts folder to be included, you can add:

```yaml
show_drafts: true
```

to your `_config.yml`. This can be combined with `future` or `unpublished`. Learn more at Jykell's [Configuration Options](https://jekyllrb.com/docs/configuration/options).

#### Previewing Drafts

If `show_drafts` is not set in your `_config.yml`, you can ask the serve command to render `_drafts`.

```bash
jekyll serve --drafts
```

### Using future dates

In your `_config.yml` add:

```yaml
future: false
```

This will prevent Jekyll from publishing any posts in the future. For previewing those posts, you can run:

```bash
jekyll serve --future
```

## Moving Posts

<div class="responsive-right"><img src="/images/drag_n_drop_sheets.gif" alt="Application animation showing drag and drop support of posts" /></div>

If you're worried about accidentally publishing something, you can create posts in a `_drafts` folder instead.  Once you're ready to publish, simply drag and drop the post from `_drafts` to `_posts`, then commit your changes.

## Too Many **_posts**?

Sort your files by Filename.

By default, files are created at the bottom of the Folder view.  Sorting by Filename ascending will have your **newer** posts at the bottom of the screen.

Sorting by descending will have newer posts at the top, but any new post will be located at the bottom.  Just re-run the sort, and your post will be right where you want it.

<div class="clear"></div>

### Committing

<div class="marcel"><img src="/images/gitg_post.png" alt="gitg application screenshot of committing a post" /></div>

[gitg](https://wiki.gnome.org/Apps/Gitg/) is a free and useful tool for managing git repositories and committing your posts[^fn-gitg-flathub]. [Sublime Merge](https://www.sublimemerge.com) offers more power and features but has too many features if you're just blogging[^fn-sublime-merge-flathub]. [Learn X in Y Minutes](https://learnxinyminutes.com/docs/git) has a great git write for the command line.

[^fn-gitg-flathub]: gitg is available on [flathub](https://flathub.org/apps/details/org.gnome.gitg).
[^fn-sublime-merge-flathub]: Sublime Merge is available on [flathub](https://flathub.org/apps/details/com.sublimemerge.App)

<div class="responsive-right-short hoffman"><img src="/images/gitg_push.png" alt="Application screenshot showing gitg's push feature" /></div>

First, stage your changes. To stage your changes, double click on the post or right-click and choose "Stage changes". This will store the current version of the file in Git's history for version control.

Click `commit` in the lower right corner once you've staged all the files you've modified.

After committing, you can go back into the timeline view to push your changes back onto the remote.


<div class="clear"></div>

