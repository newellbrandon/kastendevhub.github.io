# Veeam Kasten DevHub

Welcome to the Veeam Kasten DevHub site. This site is intended to servce as a publicly-accessible web property where engineers, architects, partners, and others
can share their experiences, tips, tricks, guides, recipes, etc around implementing, managing, integrating, and enhancing Kasten K10. Note that nothing proprietary,
forward-facing, or otherise non-public knowledge should be published via this site. Any official announcements, support documentation, knowledge base articles
or release notes should be published via official channels

## Getting Started

Kasten DevHub is produced with a [Static Site Generator](https://en.wikipedia.org/wiki/Static_site_generator) called Jekyll and published on GitHub pages, see [resources](#Resources). As a result, there are no databases, backends, etc required to publish and manage site content.  All pages are written using the common
documentation markup language Markdown. Here's a great [cheat-sheet](https://www.markdownguide.org/cheat-sheet/) to help you get started.

### Blog Posts

Blog posts are individual markdown files with the name format of `YYYY-MM-DD-blog-title.markdown` and are stored in the `_posts` directory. Any images or media
referenced by those posts should be saved to `images/blogs/` It is ideal to minimize image file size for quick web page loading and mantaining this repository's capacity quota.

### Pages

Pages can be either markdown or HTML, saved to the `_pages` directory

### Contributing

Upon every commit/merged PR, github pages automatically triggers a GitHub action to render the site

### Testing Locally

#### Environment Set-up

Testing locally is relatively simple, although note that the way that the Dann Jekyll template has been implemented, images will not load when testing locally. To run/test the site locally, you'll need the following pre-requisites:

1. [Install the latest Ruby](https://mac.install.guide/ruby/13.html)
2. [Install Bundler](https://bundler.io/)

On Mac OSX, installing ruby can be accomplished via `brew`, the only _slight_ hangup is ensuring your host path is updated to use the homebrew ruby (`/opt/homebrew/opt/ruby/bin/ruby`) as opposed to the old version bundles with OSX, installed to `/usr/bin/ruby`:

`$ brew install ruby`

Update hostpath. If using zsh, edit `~/.zshrc` or `~/.zprofile`. If using bash, edit `~/.bash_profile` or `~/.bashrc` to add the following:

```
export HOMEBREW_PREFIX=/opt/homebrew
if [ -d "$HOMEBREW_PREFIX/opt/ruby/bin" ]; then
  export PATH="$HOMEBREW_PREFIX/opt/ruby/bin:$PATH"
  export PATH=`gem environment gemdir`/bin:$PATH
fi
```
Then just source the updated file (e.g.`source ~/.zprofile` or `~/.bash_profile`)

Next, [install bundler](https://bundler.io/)

#### Testing Locally

1. Within a terminal, navigate to the source for the site
2. Run `bundle install`
3. Run `bundle exec jekyll serve --baseurl=''`
4. Open a browser and navigate to `http://localhost:4000` to view the site.

More CLI options: https://jekyllrb.com/docs/configuration/options/#serve-command-options,
e.g.: `bundle exec jekyll serve --baseurl='' --livereload --open-url &`


## Resources

In addition to Markdown, the site is built on a number of underlying technologies or templates:

- [GitHub Pages](https://pages.github.com/)
- [Dann Jekyll Theme](https://dann-jekyll.netlify.app/)
- [Jekyll](https://jekyllrb.com/)
- [Jekyll Liquid templating](https://jekyllrb.com/docs/liquid/)
- [Testing your github pages site locally with jekyll](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/testing-your-github-pages-site-locally-with-jekyll)
- [Installing Ruby on Mac OSX](https://mac.install.guide/ruby/13.html)
