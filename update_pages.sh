#!/bin/bash

git add .
# commit message
msg="Commit automatically at `date`"
git commit -m "$msg"
git push