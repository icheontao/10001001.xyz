#!/bin/bash

git add .
# commit message
msg="Commit at `date`"
git commit -m "$msg"
git push
