---
layout: page
title: Blogging with Jekyll
---

If you're looking to start a blog, consider [Jekyll](https://jekyllrb.com/). You'll be able to publish on [GitHub](https://pages.github.com/), [GitLab](https://docs.gitlab.com/ee/user/project/pages/), or any other host.

ThiefMD will make it easy to manage and update your site's content.

This article assumes you already have a Git repository setup with your Jekyll install.  Jekyll has an in-depth guide [online here](https://jekyllrb.com/docs/step-by-step/01-setup/).

## Creating a Post

<img src="images/create_post.png" style="float: left; width: 40%" />

Creating a post is easy. Select `_posts` in the Library, click on the `New Post` icon, and enter in a filename `YYYY-MM-DD-title`.

This will create a new markdown file for you to write in.

<div style="clear: both;"></div>

### YAML Frontmatter

```yaml
---
layout: post
title: Clever Post Title
date: 2020-08-31 19:58
categories: [category1, category2]
---
```

Each post begins with some YAML markup telling Jekyll the title, publish time, categories, and layout.  You can read more in [Jekyll's Documentation](https://jekyllrb.com/docs/front-matter/)

To insert the current time, right click, Insert Datetime.

![](/images/datetime_menu.png)

Using a time in the future will prevent Jekyll from writing that post to the output until after the time specified.  This makes it useful for drafting or schedule articles.

### Moving Posts

If you're worried about accidentally publishing something, you can create posts in a `_drafts` folder instead.  Once you're ready to publish, simply drag and drop the post from `_drafts` to `_posts`, then commit your changes.

![](/images/drag_n_drop_sheets.gif)

### Committing

[gitg](https://wiki.gnome.org/Apps/Gitg/) is a useful tool for managing git repositories and committing your posts.

![](/images/gitg_post.png)

First, stage your changes. Then click `commit` in the lower right corner. After committing, you can go back into the timeline view to push your changes back onto the remote.

![](/images/gitg_push.png)