# Vision

This document hopes to define what is and isn't in the view for ThiefMD.

Always feel free to reach out or [submit an issue](https://github.com/kmwallio/ThiefMD/issues) asking about a feature or the direction of ThiefMD.

The goal of this document is to help align people on how things should go into ThiefMD, and help people figure out how a feature request will be prioritized.

## Goals

ThiefMD is made for managing large amounts of text split across multiple files. Organization and management of these files is a key goal of ThiefMD.

ThiefMD can be used for writing manuscripts, books, blog posts, site content, notes, and other scenarios where [Markdown](https://daringfireball.net/projects/markdown) can be used for the content generation. Other humane markup languages may be added, but Markdown is the first class citizen.

### Writing

#### The Main Editor Window

The main editing window will focus on writing--getting words on a page--and organizing those words. The main window will focus on content creation.

Anything too distracting, like live preview, burn down widgets, pie charts, and etc, should be placed in a separate window. Questions related to content produced should go in a separate window. "How does my document look?", "How is my writing progress?", and similar questions can be answered by ThiefMD, but not in the main window where it can distract from creating content.

#### Getting Out of the Way

ThiefMD will not dictate a certain pattern or enforce a style of writing on the user.

ThiefMD will not lock the user into using a specific application.

ThiefMD should provide new and increased functionality, but it should not prompt or alert the user about the new features. Features should be discoverable, even if hidden behind a few mouse clicks.

Never nag, but always offer.

#### Customization

The user should be able to tweak settings to make ThiefMD encourage them to write. Customizations should persist for the user between sessions. ThiefMD should remember what the user liked, and try to keep it that way.

#### Incomplete is okay, but never broken

New features or improvements can be implemented and submitting in an imcomplete state as long as it benefits the user.

Things in an incomplete state that break the user's experience should not be checked in for release.

### Reading

#### The Main Window

The main window should be readable. Changes to the default style should be made if reading cannot be done.

#### The Preview Window

The preview window should provide styling that encourages the writer to be proud of their work.  It should be a showcase separate from the main window.

## Non-Goals

### Static Site Generation

Although ThiefMD works great with [static site generators](https://www.staticgen.com/), ThiefMD will not become a SSG specific environment. [Tips and Tricks](https://thiefmd.com/tips/jekyll) on how to use ThiefMD for these types of scenarios is encouraged. That doesn't mean ThiefMD won't support startup tasks that could potentially start a preview server in that directory, but design should cover writers and general purpose writing in the UI first.

Although based on GtkSourceView, ThiefMD will only support humane markup languages.

### Version Control Management

Any changes related to get or other version control is an attempt to maintain data integrity and reliability of ThiefMD. ThiefMD's primary focus is writing and content creation, but it should encourage methods of backup and sync in a way the user can disable.

### WYSIWYG

While live preview is encouraging to see when writing, ThiefMD does not plan on handling requests for templating and page formatting. With all the different mediums it would be too much.

Export Templates are in line with the goals of ThiefMD. It is hoped that support and issues can be directed towards the template creators.
