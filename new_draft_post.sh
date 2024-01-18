#!/usr/bin/env bash

function init.post {
  local _author
  local _filespec
  local _template

  _filespec="_drafts/${TITLE-placeholder}.md"
  _template='_drafts/_template.md'

  if [[ -n ${AUTHOR} ]]; then
    _author="${AUTHOR}"
  elif command gh --version >&/dev/null; then
    # brew install gh # https://cli.github.com/manual
    # gh auth login --git-protocol ssh --web # gh config set -h github.com git_protocol ssh
    # vs: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
    _author=$(gh auth status | grep 'Logged' | awk -F'account ' '{print $2}' | awk '{print $1}')
  else
    _author=$(whoami)
  fi

  sed \
    -e s/DATE/"$(date '+%Y-%m-%d')"/ \
    -e s/TIME/"$(date '+%H:%M:%S')"/ \
    -e s/TZ/"$(date '+%z')"/ \
    -e s/AUTHOR/${_author}/ \
    -e s/CAPTION/${CAPTION-${TITLE}}/ \
    -e s/DESCRIPTION/${DESCRIPTION-${TITLE}}/ \
    -e s/IMAGE/${IMAGE-IMAGE}/ \
    -e s/TAGS/${TAGS-${TITLE}}/ \
    -e s/TITLE/${TITLE-placeholder}/ \
    "${_template}" >> "${_filespec}" \
    && echo "|    DONE| ${_filespec}" \
    && echo "|INFO|TRY| bundle exec jekyll serve --baseurl='' --drafts --livereload --open-url --unpublished &"
}

cat <<- 'EoM'
|OPTIONAL| set AUTHOR, CAPTION, DESCRIPTION, IMAGE, TAGS, TITLE environment variables.
|BUG:TODO| TAGS='comma, separated, list' # doesn't work yet.
|DEFAULTS| unless set, the variable name or these values will be used:
 - AUTHOR: `gh auth status` or `whoami`
 -  TITLE: placeholder
EoM
cat <<- EoM
| EXAMPLE| TITLE='my_posting' ${0}
EoM

init.post;
