---
layout: page
title: Help with WordPress
---

## Unable to Connect

Double check your username, password, and provided endpoint. If you didn't provide `http://` or `https://`, ThiefMD will default to `https://`.

### Check for /xmlrpc.php

ThiefMD communicates with WordPress through [XML-RPC](https://codex.wordpress.org/XML-RPC_Support).

Certain plug-ins may disable XML-RPC, and some automated installations remove the file.

### If /xmlrpc.php exists

If `/xmlrpc.php` exists on your site, but you still can't connect, try to check your site's error logs.

Sometimes, renaming the file or creating a symlink to `xmlrpc.php` with a different name will fix the issue. Don't worry, ThiefMD will be able to connect to the new file. We recommend renaming the file to `restrpc.php`. In the Connection window, you can specify `https://my-wordpress.blog/restrpc.php`

### Disable mod_security

On [DreamHost](https://dreamhost.com), you can disable mod_security by going into Manage Domains, clicking Edit, and choosing to disable **Extra Web Security?**.

Disabling mod\_security can open up your site to DDoS attacks, SQL Injections, Brute Force attacks, and other preventable common issues. We recommend trying the other workarounds listed.

Disabling mod\_security may improve XML-RPC reliability. mod\_security limits the amount of data being sent though XML-RPC. Disabling it can allow for larger photo uploads.

### Disable block-xmlrpc on Digital Ocean

The [WordPress Marketplace Installer](https://marketplace.digitalocean.com/apps/wordpress) disabled XML-RPC by default. To enable XML-RPC in your Droplet:

```bash
a2disconf block-xmlrpc
systemctl reload apache2
```

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

### Disable mod_security

On [DreamHost](https://dreamhost.com), you can disable mod_security by going into Manage Domains, clicking Edit, and choosing to disable **Extra Web Security?**.

Disabling mod\_security can open up your site to DDoS attacks, SQL Injections, Brute Force attacks, and other preventable common issues. We recommend trying the other workarounds listed.

Disabling mod\_security may improve XML-RPC reliability. 

### Other issue?

Please check your error and access logs.

Also, please try running `com.github.kmwallio.thiefmd` from the terminal. Attempt to publish, and capture the output from the terminal. Feel free to reach out through [GitHub Issues](https://github.com/ThiefMD/wordpress-vala/issues).