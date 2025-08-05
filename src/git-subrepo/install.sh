#!/usr/bin/env bash
set -e

if [ ! -d "$HOME/.git-subrepo" ]; then
  git clone https://github.com/ingydotnet/git-subrepo.git "$HOME/.git-subrepo"
fi

grep -qxF 'source ~/.git-subrepo/.rc' "$HOME/.bashrc" \
  || printf '\nsource ~/.git-subrepo/.rc\n' >> "$HOME/.bashrc"