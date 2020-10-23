---
layout: page
title: Blogging with WriteFreely
thieftags: #blogging
---

Already have a [WriteFreely](https://writefreely.org) or [Write.as](https://write.as) blog? ThiefMD can publish to them!

Please note, automated image upload is not supported. Check out [Snap.as](https://snap.as) as a convenient way to upload and share your photos.

## Adding a Connection ❤

<div class="responsive-right-short marcel"><img src="/images/blogging-write.as/new-connection.png" alt="ThiefMD adding Write.as connection" /></div>

In the Preferences `Ctrl+,` click on **Connections**.

In the **Add Connection** section, click on "Write Freely". This will prompt for your username, password, and Write Freely API URL.

If everything goes well, the blog will be added to the **Current Connections** list. You can click on the blog to remove it.

## Writing for WriteFreely

ThiefMD supports adding a title, uploading images, and publishing the post in a "Draft" or "Published" state.

### Adding a Title

At the start of your file, you need to add a little YAML front-matter to specify the title.

```yaml
---
title: My Awesome Post
---
```

<div class="clear"></div>

### Adding Content

For content, just use Markdown after the YAML frontmatter.

```yaml
---
title: My Awesome Post
---

Hello Write Freely!

![](https://i.snap.as/cwQFF5Iu.jpeg)

Today, I'm not sure what I want to write. I figured you all should know I had Vietnamese Food for lunch.
```

If you're a Write.as Pro user, you can upload your images to [Snap.as](https://snap.as), and copy the  `Share on Write.as` markdown to include images in your post.

With this, ThiefMD will be ready to upload your images and you post through the `Export` window. Right-click on the post you want to publish, and click **Export**.

![](/images/blogging-write.as/publisher-window.png)

In the window, you can select `Write.as/user` as the Export Option. A Drop Down with your available collections will appear. Use this to choose where your post will appear.

As long as everything looks good, click on **Export**.

Once everything is done, links will appear to access the post along with a Token and ID corresponding to your post.

Happy Writing!
