---
layout: page
title: Help with Wordpress
---

## Unable to Connect

### Check for /xmlrpc.php

ThiefMD communicates with Wordpress through [XML-RPC](https://codex.wordpress.org/XML-RPC_Support).

Certain plug-ins may disable XML-RPC, and some automated installations remove the file.

### /xmlrpc.php exists

If `/xmlrpc.php` exists on your site, but you still can't connect, try to check your site's error logs.

Sometimes, renaming the file or creating a symlink to `xmlrpc.php` with a different name will fix the issue. Don't worry, ThiefMD will be able to connect to the new file. We recommend renaming the file to `restrpc.php`. In the Connection window, you can specify `https://my-wordpress.blog/restrpc.php`

## Unable to Publish Posts

## Unable to Upload Images
