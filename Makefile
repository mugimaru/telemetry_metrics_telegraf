.PHONY: check
check: MIX_ENV=test
check:
	@mix compile --force --warnings-as-errors
	@mix format --check-formatted
	@mix test
	@mix credo