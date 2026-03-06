.PHONY: tag

tag:
	@bash -c '\
		while true; do \
			read -p "Release type? [M]ajor / [m]inor / [p]atch: " release_type; \
			case $$release_type in M|major|m|minor|p|patch) break ;; \
			*) echo "Please enter M, m, or p." ;; esac; \
		done; \
		read -p "Pre-release suffix? [a]lpha / [b]eta / empty for none: " pre; \
		case $$pre in a) pre=alpha ;; b) pre=beta ;; esac; \
		latest=$$(git tag --sort=-v:refname | grep -v -- '-' | head -1); \
		if [ -z "$$latest" ]; then latest=$$(git tag --sort=-v:refname | head -1); fi; \
		latest=$${latest#v}; \
		base=$${latest%%-*}; \
		major=$$(echo $$base | cut -d. -f1); \
		minor=$$(echo $$base | cut -d. -f2); \
		patch=$$(echo $$base | cut -d. -f3); \
		case $$release_type in \
			M|major) major=$$((major+1)); minor=0; patch=0 ;; \
			m|minor) minor=$$((minor+1)); patch=0 ;; \
			p|patch) patch=$$((patch+1)) ;; \
			*) echo "Unknown release type: $$release_type"; exit 1 ;; \
		esac; \
		new_version="$$major.$$minor.$$patch"; \
		if [ -n "$$pre" ]; then new_version="$$new_version-$$pre"; fi; \
		echo "Tagging as v$$new_version"; \
		/usr/libexec/PlistBuddy -c "Set :version $$new_version" info.plist; \
		git add info.plist; \
		git commit -m "chore: bump version to $$new_version"; \
		git tag "v$$new_version"; \
		echo "Tagged v$$new_version — run: git push --follow-tags"; \
	'
