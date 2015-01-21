#!/bin/bash
timestamp() {
  date +"%T"
}

jekyll build
git add --all
git commit -m "Deploying at $(timestamp)"
git push
git subtree push --prefix _site origin master
