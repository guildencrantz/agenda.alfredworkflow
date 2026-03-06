#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

latest=$(/usr/libexec/PlistBuddy -c "Print :version" info.plist)
pre_suffix="${latest#*-}"
if [ "$pre_suffix" = "$latest" ]; then pre_suffix=""; fi

force_push=0

if [ -n "$pre_suffix" ]; then
    read -p "Current version is v$latest. Re-tag this version? [y/N]: " retag
    case $retag in
    y|Y|yes)
        new_version="$latest"
        commit_msg="chore: retag v$new_version"
        force_push=1
        ;;
    *)
        if [ "$pre_suffix" = "alpha" ]; then proposed_pre="beta"
        else proposed_pre=""; fi
        if [ -n "$proposed_pre" ]; then
            read -p "Promote to -$proposed_pre? [Y/n]: " confirm
            case $confirm in n|N|no) proposed_pre="" ;; esac
        fi
        base="${latest%%-*}"
        new_version="$base"
        if [ -n "$proposed_pre" ]; then new_version="$new_version-$proposed_pre"; fi
        commit_msg="chore: bump version to $new_version"
        ;;
    esac
else
    while true; do
        read -p "Release type? [M]ajor / [m]inor / [p]atch: " release_type
        case $release_type in M|major|m|minor|p|patch) break ;;
        *) echo "Please enter M, m, or p." ;; esac
    done
    read -p "Pre-release suffix? [a]lpha / [b]eta / empty for none: " pre
    case $pre in a) pre=alpha ;; b) pre=beta ;; esac
    base="$latest"
    major=$(echo $base | cut -d. -f1)
    minor=$(echo $base | cut -d. -f2)
    patch=$(echo $base | cut -d. -f3)
    case $release_type in
        M|major) major=$((major+1)); minor=0; patch=0 ;;
        m|minor) minor=$((minor+1)); patch=0 ;;
        p|patch) patch=$((patch+1)) ;;
    esac
    new_version="$major.$minor.$patch"
    if [ -n "$pre" ]; then new_version="$new_version-$pre"; fi
    commit_msg="chore: bump version to $new_version"
fi

echo "Tagging as v$new_version"
/usr/libexec/PlistBuddy -c "Set :version $new_version" info.plist
git add info.plist
git commit -m "$commit_msg"
if [ "$force_push" = "1" ]; then
    git tag -f "v$new_version"
else
    git tag "v$new_version"
fi
if [ "$force_push" = "1" ]; then
    echo "Tagged v$new_version — run: git push --force origin v$new_version && git push"
else
    echo "Tagged v$new_version — run: git push --follow-tags"
fi
