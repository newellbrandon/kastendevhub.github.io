# Veeam Kasten DevHub

Welcome to the Veeam Kasten DevHub site. This site is intended to servce as a publicly-accessible web property where engineers, architects, partners, and others can share their experiences, tips, tricks, guides, recipes, etc around implementing, managing, integrating, and enhancing Kasten K10. Note that nothing proprietary, forward-facing, or otherise non-public knowledge should be published via this site. Any official announcements, support documentation, knowledge base articles or release notes should be published via official channels

## Getting Started

Kasten DevHub is produced with a [Static Site Generator](https://en.wikipedia.org/wiki/Static_site_generator) called Jekyll and published on GitHub pages, see [resources](#Resources). As a result, there are no databases, backends, etc required to publish and manage site content.  All pages are written using the common documentation markup language Markdown. Here's a great [cheat-sheet](https://www.markdownguide.org/cheat-sheet/) to help you get started and [_pages/elements.md](https://veeamkasten.dev/elements/) is a working example.

### Blog Posts

Blog posts are individual markdown files with the name format of `YYYY-MM-DD-blog-title.markdown` and are stored in the `_posts` directory. Any images or media referenced by those posts should be saved to `images/posts/` It is ideal to minimize image file size for quick web page loading and mantaining this repository's capacity quota.

### Pages

Pages can be either markdown or HTML, saved to the `_pages` directory

### Contributing

1. Fork the [kastendevhub/kastendevhub.github.io repo](https://github.com/kastendevhub/kastendevhub.github.io/fork)
2. [Sync your fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork) and resolve any merge problems

    ```bash
    git remote add upstream git@github.com:kastendevhub/kastendevhub.github.io.git \
      && git remote --verbose # one time setup; see remote added: upstream

    git fetch upstream && git diff upstream/master && git merge upstream/master
    ```

3. Make changes and [test locally](#testing-locally-1); when ready, git commit and push your fork
4. Submit a Pull Request and add at least one peer reviewer

Upon every commit/merged PR, Github pages automatically triggers a GitHub action to render the site.

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

Alternatively, use the [rbenv](https://github.com/rbenv/rbenv) environment manager (optionally installed via [anyenv](https://anyenv.github.io/) which has the benefits of not installing Brew's `ruby` or `rbenv` and having to manage Gem upgrade dependencies, because it compiles and installs Ruby+Gems per enviroment to avoid system or Brew upgrade conflicts). To determine the latest stable Ruby release, check https://www.ruby-lang.org/en/downloads/.

```bash
brew install anyenv libyaml \
&& cat >> ~/.zshrc <<- 'EoM'
if command -v anyenv >&/dev/null; then
  eval "$(anyenv init -)"
fi
EoM

source ~/.zshrc && anyenv install rbenv && exec $SHELL -l
# the above can be skipped if not using anyenv; use `brew install rbenv` instead
rbenv install --list && rbenv install 3.3.0 && rbenv rehash

cd ${YOUR_FORK-~/Documents/github.com/mlavi/kastendevhub/}
# uses .ruby-version; `rbenv local` should display 3.3.0
bundle install # should install to local, not global or system Ruby
```

#### Testing Locally

1. Within a terminal, navigate to the source for the site.
2. Run `bundle install` to install the Ruby gem depenencies.
3. Run `bundle exec jekyll serve --baseurl='' --livereload --open-url &`

## Resources

In addition to Markdown, the site is built on a number of underlying technologies or templates:

- [GitHub Pages](https://pages.github.com/)
  - [Testing your github pages site locally with jekyll](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/testing-your-github-pages-site-locally-with-jekyll)
- [Jekyll](https://jekyllrb.com/)
  - [Dann Jekyll Theme](https://dann-jekyll.netlify.app/)
  - [Jekyll Liquid templating](https://jekyllrb.com/docs/liquid/)
  - [Jekyll server CLI options](https://jekyllrb.com/docs/configuration/options/#serve-command-options), such as `--drafts`
- [Installing Ruby on Mac OSX](https://mac.install.guide/ruby/13.html)
