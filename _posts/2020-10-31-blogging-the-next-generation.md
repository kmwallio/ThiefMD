---
layout: post
title: Blogging the Next Generation
date: 2020-10-23 18:21:38
---

We revamped our Publishing Window and Export Options yet again. This time, to allow for publishing to online blog services. In the preferences, you'll find a [Connections tab](/tips/blogging-with-writefreely) that'll show our currently supported services.

<!-- more -->

![](/images/blogging-writefreely/publisher-window.png)

* [Write.as](https://write.as) as an [Export Connection option](/tips/blogging-with-writefreely/)
* [Ghost](https://ghost.org) as an [Export Connection option](/tips/blogging-with-ghost/)
* Fixed UI margin issue on opening large files (most of the time)
* There's [an issue storing passwords in flatpak](https://gitlab.gnome.org/GNOME/libsecret/-/issues/55), so you'll have to re-add connections to publish. We choose not to store passwords/auth tokens in plain text
* Improve file modification detection. Dropbox syncing in the background? ThiefMD will load changes if they seem safe, or prompt to load the file from disk.
* Improved wording in the Preferences dialog. I know what I mean, but y'all might not. We were lucky [to get a pull request](https://github.com/kmwallio/ThiefMD/pull/78) that helps describe features better.