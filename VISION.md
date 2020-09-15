# Vision

This document hopes to define what is and isn't in the view for ThiefMD.

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

The user should be able to tweak some settings to make ThiefMD encourage them to write.

### Reading

#### The Main Window

The main window should be readable. Changes to the default style should be made if reading cannot be done.

#### The Preview Window

The preview window should provide styling that encourages the writer to be proud of their work.  It should be a showcase separate from the main window.

## Non-Goals

Although ThiefMD works great with [static site generators](https://www.staticgen.com/), ThiefMD will not become a SSG specific environment. That doesn't mean ThiefMD won't support startup tasks that could potentially start a preview server in that directory, but design should cover writers and general purpose writing in the UI first.

Although based on GtkSourceView, ThiefMD will only support humane markup languages.