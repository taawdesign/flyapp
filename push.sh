#!/bin/bash
# Quick push script for Fly webapp

echo "📤 Pushing changes to GitHub..."

# Add all changes
git add .

# Commit with message
if [ -z "$1" ]; then
    git commit -m "Update files"
else
    git commit -m "$1"
fi

# Push to GitHub
git push origin main

echo "✅ Changes pushed to GitHub!"
echo "🌐 Your site will update at: https://taawdesign.github.io/fly/"
echo "⏱️  Wait 1-2 minutes for GitHub Pages to rebuild"
