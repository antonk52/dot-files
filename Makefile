lint:
	@selene ./nvim

format:
	@stylua ./nvim

format-check:
	@stylua --check ./nvim

git-hooks:
	@ln -s ../../.githooks/pre-commit .git/hooks/pre-commit
	@echo "Git hooks installed."
