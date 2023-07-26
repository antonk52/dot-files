lint:
	@selene ./nvim ./wezterm

format:
	@stylua ./nvim ./wezterm

format-check:
	@stylua --check ./nvim ./wezterm

git-hooks:
	@ln -sf ./.githooks/pre-commit .git/hooks/pre-commit
	@echo "Git hooks installed."
