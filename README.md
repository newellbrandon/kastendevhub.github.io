# Veeam Kasten DevHub

Welcome to the Veeam Kasten DevHub site. This site is intended to servce as a publicly-accessible web property where engineers, architects, partners, and others can share their experiences, tips, tricks, guides, recipes, etc around implementing, managing, integrating, and enhancing Kasten K10. Note that nothing proprietary, forward-facing, or otherise non-public knowledge should be published via this site. Any official announcements, support documentation, knowledge base articles or release notes should be published via official channels

## Getting Started

Kasten DevHub is produced with a [Static Site Generator](https://en.wikipedia.org/wiki/Static_site_generator) called Jekyll and published on GitHub pages, see [resources](#Resources). As a result, there are no databases, backends, etc required to publish and manage site content.  All pages are written using the common documentation markup language Markdown. Here's a great [cheat-sheet](https://www.markdownguide.org/cheat-sheet/) to help you get started.

### Blog Posts

Blog posts are individual markdown files with the name format of `YYYY-MM-DD-blog-title.markdown` and are stored in the `_posts` directory. Any images or media referenced by those posts should be saved to `images/blogs/` It is ideal to minimize image file size for quick web page loading and mantaining this repository's capacity quota.

### Pages

Pages can be either markdown or HTML, saved to the `_pages` directory

### Contributing

Upon every commit/merged PR, Github pages automatically triggers a GitHub action to render the site

### Testing Locally

#### Environment Set-up

Testing locally is relatively simple, you'll need to install the latest stable [Ruby](https://mac.install.guide/ruby/13.html), which includes [Bundler](https://bundler.io/).

On Mac OSX, install with `brew`, the only _slight_ hangup is ensuring your host path is updated to use the homebrew ruby (`/opt/homebrew/opt/ruby/bin/ruby`) as opposed to the old version bundles with OSX, installed to `/usr/bin/ruby`:

`$ brew install ruby`

Update your system `$PATH` by adding the following

```shell
export HOMEBREW_PREFIX=/opt/homebrew
if [ -d "$HOMEBREW_PREFIX/opt/ruby/bin" ]; then
  export PATH="$HOMEBREW_PREFIX/opt/ruby/bin:$PATH"
  export PATH=`gem environment gemdir`/bin:$PATH
fi
```
- If using zsh, edit `~/.zshrc` or `~/.zprofile`
- If using bash, edit `~/.bash_profile` or `~/.bashrc`

Then just source the updated file (e.g.: `source ~/.zprofile` or `~/.bash_profile`)

Alternatively, use an evironment manager, such as [rbenv](https://github.com/rbenv/rbenv) (optionally installed via [anyenv](https://anyenv.github.io/)), e.g.:

```bash
brew install anyenv libyaml ruby \
&& cat >> ~/.zshrc <<- 'EoM'
if command -v anyenv; then
  eval "$(anyenv init -)"
fi
EoM

source ~/.zshrc && anyenv install rbenv && exec $SHELL -l
# to determine stable release: open https://www.ruby-lang.org/en/downloads/
rbenv install --list && rbenv install 3.3.0 && rbenv rehash

cd ${YOUR_FORK-~/Documents/github.com/mlavi/kastendevhub/}
# will use .ruby-version; `rbenv local` should display 3.3.0
bundle install # should install to local, not global or system Ruby 
```



#### Testing Locally

1. Within a terminal, navigate to the source for the site.
2. Run `bundle install` to install the Ruby gem depenencies.
3. Run `bundle exec jekyll serve --baseurl='' --livereload --open-url &`

## Resources

In addition to Markdown, the site is built on a number of underlying technologies or templates:

- [GitHub Pages](https://pages.github.com/)
- [Dann Jekyll Theme](https://dann-jekyll.netlify.app/)
- [Jekyll](https://jekyllrb.com/)
- [Jekyll Liquid templating](https://jekyllrb.com/docs/liquid/)
- [Testing your github pages site locally with jekyll](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/testing-your-github-pages-site-locally-with-jekyll)
  - [Jekyll server CLI options](https://jekyllrb.com/docs/configuration/options/#serve-command-options), such as `--drafts`
- [Installing Ruby on Mac OSX](https://mac.install.guide/ruby/13.html)
