---
layout: page
title: Help with Wordpress
---

## Unable to Connect

Double check your username, password, and provided endpoint. If you didn't provide `http://` or `https://`, ThiefMD will default to `https://`.

### Check for /xmlrpc.php

ThiefMD communicates with Wordpress through [XML-RPC](https://codex.wordpress.org/XML-RPC_Support).

Certain plug-ins may disable XML-RPC, and some automated installations remove the file.

### /xmlrpc.php exists

If `/xmlrpc.php` exists on your site, but you still can't connect, try to check your site's error logs.

Sometimes, renaming the file or creating a symlink to `xmlrpc.php` with a different name will fix the issue. Don't worry, ThiefMD will be able to connect to the new file. We recommend renaming the file to `restrpc.php`. In the Connection window, you can specify `https://my-wordpress.blog/restrpc.php`

### Other issue?

Please check your error and access logs.

Also, please try running `com.github.kmwallio.thiefmd` from the terminal. Attempt to publish, and capture the output from the terminal. Feel free to reach out through [GitHub Issues](https://github.com/ThiefMD/wordpress-vala/issues).

## Unable to Publish Posts

Please check your error and access logs.

Also, please try running `com.github.kmwallio.thiefmd` from the terminal. Attempt to publish, and capture the output from the terminal. Feel free to reach out through [GitHub Issues](https://github.com/ThiefMD/wordpress-vala/issues).

## Unable to Upload Images

### Configure File Upload Size?

Check your PHP's file upload size limit and make sure it's larger than the image your uploading.

The Web Server running may also impose file upload limits.

### Other issue?

Please check your error and access logs.

Also, please try running `com.github.kmwallio.thiefmd` from the terminal. Attempt to publish, and capture the output from the terminal. Feel free to reach out through [GitHub Issues](https://github.com/ThiefMD/wordpress-vala/issues).