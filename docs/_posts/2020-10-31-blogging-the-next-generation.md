---
layout: post
title: Blogging the Next Generation
date: 2020-10-20 19:10:57
---

We revamped our Publishing Window and Export Options yet again. This time, to allow for publishing to online blog services. In the preferences, you'll find a Connections tab that'll show our currently supported services.

<!-- more -->

* [Write.as](https://write.as) as an Export Connection option
* [Ghost](https://ghost.org) as an Export Connection option
* Fixed UI margin issue on opening large files (most of the time)
* There's [an issue storing passwords in flatpak](https://gitlab.gnome.org/GNOME/libsecret/-/issues/55), so you'll have to re-add connections to publish. We choose not to store passwords/auth tokens in plaintext
* Improve file modification detection. Dropbox syncing in the background? ThiefMD will load changes if they seem safe, or prompt to load the file from disk.