#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

latest=$(/usr/libexec/PlistBuddy -c "Print :version" info.plist)

# Parse: pre_type (alpha/beta) and pre_num (1,2,...) from e.g. 1.1.0-beta2
base="${latest%%-*}"
pre_part=""
if [ "$latest" != "$base" ]; then
    pre_part="${latest#*-}"          # e.g. "beta.2"
    pre_type="${pre_part%%.*}"        # e.g. "beta"
    pre_num="${pre_part#*.}"         # e.g. "2"
    if [ -z "$pre_num" ]; then pre_num=1; fi
fi

if [ -n "$pre_part" ]; then
    # Current version is a pre-release — ask to increment first
    next_num=$((pre_num + 1))
    read -p "Current version is v$latest. Increment to ${pre_type}.${next_num}? [Y/n]: " inc
    case $inc in
    n|N|no)
        # Ask about category change
        if [ "$pre_type" = "alpha" ]; then
            read -p "Promote to beta.1? [Y/n]: " promote
            case $promote in
            n|N|no)
                echo "Aborted."; exit 0 ;;
            *)
                new_pre="beta.1" ;;
            esac
        else
            # beta -> release
            read -p "Promote to full release (drop pre-release suffix)? [Y/n]: " promote
            case $promote in
            n|N|no)
                echo "Aborted."; exit 0 ;;
            *)
                new_pre="" ;;
            esac
        fi
        ;;
    *)
        new_pre="${pre_type}.${next_num}"
        ;;
    esac

    new_version="$base"
    if [ -n "$new_pre" ]; then new_version="$new_version-$new_pre"; fi
    prev_tag_msg=$(git tag -n1 "v$latest" 2>/dev/null | sed 's/^[^ ]* *//')
    read -e -p "Tag message: " -i "$prev_tag_msg" tag_msg
    commit_msg="chore: bump version to $new_version"

else
    # Stable release — ask for bump type and optional pre-release
    while true; do
        read -p "Release type? [M]ajor / [m]inor / [p]atch: " release_type
        case $release_type in M|major|m|minor|p|patch) break ;;
        *) echo "Please enter M, m, or p." ;; esac
    done
    read -p "Pre-release suffix? [a]lpha / [b]eta / empty for none: " pre
    case $pre in a) pre=alpha ;; b) pre=beta ;; esac

    major=$(echo $base | cut -d. -f1)
    minor=$(echo $base | cut -d. -f2)
    patch=$(echo $base | cut -d. -f3)
    case $release_type in
        M|major) major=$((major+1)); minor=0; patch=0 ;;
        m|minor) minor=$((minor+1)); patch=0 ;;
        p|patch) patch=$((patch+1)) ;;
    esac
    new_version="$major.$minor.$patch"
    if [ -n "$pre" ]; then new_version="$new_version-${pre}.1"; fi
    read -e -p "Tag message: " tag_msg
    commit_msg="chore: bump version to $new_version"
fi

echo "Tagging as v$new_version"
/usr/libexec/PlistBuddy -c "Set :version $new_version" info.plist
git add info.plist
git commit -m "$commit_msg"
git tag -a "v$new_version" -m "$tag_msg"
echo "Tagged v$new_version — run: git push --follow-tags"
