---
layout: page
title: Blogging with Ghost
thieftags: #blogging
---

Already have a [Ghost](https://ghost.org) blog? ThiefMD assists with publishing to Ghost!

## Adding a Connection ❤

<div class="responsive-right-short hoffman"><img src="/images/blogging-ghost/connections-prompt.png" alt="ThiefMD adding Ghost connection" /></div>

In the Preferences `Ctrl+,` click on **Connections**.

In the **Add Connection** section, click on "ghost". This will prompt for your username, password, and Ghost URL.

If everything goes well, the blog will be added to the **Current Connections** list. You can click on the blog to remove it.

## Writing for Ghost

ThiefMD supports adding a title, uploading images, and publishing the post in a "Draft" or "Published" state.

### Adding a Title

At the start of your file, you need to add a little YAML front-matter to specify the title.

```yaml
---
title: My Awesome Post
---
```

### Adding Content and Images

For content and images, just use Markdown after the YAML frontmatter.

```yaml
---
title: My Awesome Post
---

Hello Ghost! This is what happy people look like:

![](/images/brooke-cagle-happy-people.jpg)
```

With this, ThiefMD will be ready to upload your images and you post through the `Export` window. Right-click on the post you want to publish, and click **Export**.

![](/images/blogging-ghost/publisher-window.png)

In the window, you can select `my-ghost.blog/user` as the Export Option. A Drop Down for "Draft" or "Published" will appear. If you're ready to publish immediately, change this to Publish.

As long as everything looks good, click on **Export**. ThiefMD will upload any images, and then send the contents to your Ghost blog.

Once everything is done, links will appear to access the post, or Ghost's online editor.

Happy Writing!
