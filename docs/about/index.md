---
layout: page
title: About
---

# About

<img src="/images/thiefmd_64.png" style="float: left; height: 64px; width: 64px;" />ThiefMD is a Markdown editor and file manager inspired by [Ulysses](https://ulysses.app). It is [Open Source](https://github.com/kmwallio/ThiefMD) and based off of [other great open source software](#credit).

It is my primary way of attempting to learn [Vala](https://wiki.gnome.org/Projects/Vala) and filling in the gap of applications I miss from [macOS](https://apple.com). 

<div style="clear: both;"></div>

# Features

ThiefMD currently supports

* Folder Import
* Markdown Syntax Highlighting
* Organization of Folders and Files
* Live Preview
* Export Preview
* Folder Export to PDF, DocX, ePub and more
* Import and Conversion of Ulysses Themes to GtkSourceView Styles
  - Matching the UI to the selected theme
* Type-Writer Scrolling

# Credit

Great software is built on the shoulders of giants.

* Code <s>stolen</s> *forked* from [Quilter](https://github.com/lainsce/quilter)
* Font is [iA Writer Duospace](https://github.com/iaolo/iA-Fonts)
* Inspired by [Ulysses](https://ulyssesapp.com)
* Preview CSS is [Splendor](http://markdowncss.github.io/splendor) + [Modest](http://markdowncss.github.io/modest)
* Markdown Rendering by [Discount](http://www.pell.portland.or.us/~orc/Code/discount)
* Preview Syntax Highlighting by [highlight.js](https://highlightjs.org)
* Math Rendering by [Katex](https://katex.org)
* Multi Format Export by [Pandoc](https://pandoc.org)
* Screenshots use [Vimix GTK Themes](https://github.com/vinceliuice/vimix-gtk-themes) and [Vimix Icon Theme](https://github.com/vinceliuice/vimix-icon-theme)

## Goals

### Initial

* Basic markdown syntax support
* Creation and Deletion of Files
* Library Management
    * Adding Existing Folders
    * Creating sub folders
    * Removing folders
    * Moving markdown files between folders
    * Ordering of markdown files and folders
* Light/Dark/User Themes
* Export a file or folders
* Compilation and preview of multiple files while maintaining order
* Keep undo history tied to files

### Later on Markdown Support

* Load multiple files into Editor View
* Additional export and preview themes

### I don't really want it but...

* Timed sessions with typing statistics
* Some sort of focus mode
* Git-Backed Projects
