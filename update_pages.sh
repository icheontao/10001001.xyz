#!/bin/bash

echo -e "Deploying gitHub pages..."
git add .
git commit -m "Built automatically at `data`"

git push