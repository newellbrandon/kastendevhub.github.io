# Veeam Kasten DevHub

Welcome to the Veeam Kasten DevHub site. This site is intended to servce as a publicly-accessible web property where engineers, architects, partners, and others
can share their experiences, tips, tricks, guides, recipes, etc around implementing, managing, integrating, and enhancing Kasten K10. Note that nothing proprietary,
forward-facing, or otherise non-public knowledge should be published via this site. Any official announcements, support documentation, knowledge base articles
or release notes should be published via official channels

A few tips to get started:

## Getting Started

This site is managed via GitHub pages. As a result, there are no databases, backends, etc required to publish and manage site content.  All pages are written using the common
documentation markup language Markdown. Here's a great [cheat-sheet](https://www.markdownguide.org/cheat-sheet/) to help you get started.

### Blog Posts

Blog posts are individual markdown files with the name format of YYYY-MM-DD-blog-title.markdown and are stored in the `_posts` directory. Any images or media
referenced by those posts should be saved to `images/blogs/`

### Pages

Pages can be either markdown or HTML, saved to the `_pages` directory

### Contributing

Upon every commit/merged PR, github pages automatically triggers a GitHub action to render the site

## Resources

In addition to Markdown, the site is built on a number of underlying technologies or templates:

- [GitHub Pages](https://pages.github.com/)
- [Dann Jekyll Theme](https://dann-jekyll.netlify.app/)
- [Jekyll](https://jekyllrb.com/)
- [Jekyll Liquid templating](https://jekyllrb.com/docs/liquid/)