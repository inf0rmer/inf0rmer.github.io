#!/bin/bash
timestamp() {
  date +"%Y-%m-%d_%H-%M-%S"
}

jekyll build
git add --all
git commit -m "Deploying at $(timestamp)"
git push
git subtree push --prefix _site origin master
