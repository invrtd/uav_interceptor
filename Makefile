SHELL := /bin/bash
.DEFAULT_GOAL := help

.PHONY: help setup sitl plugin sim sim-intercept fake-gs doctor clean help

help:  ## Show this help
	@echo "ArduPilot + Gazebo SITL"
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-13s %s\n", $$1, $$2}'
	@echo
	@echo "Flags: CAMERA=1 enable gimbal camera stream, HEADLESS=1 server-only Gazebo,"
	@echo "       WORLD=... VEHICLE=... FRAME=... PARM=... override sim defaults."

setup:  ## Fetch submodules + create the uv environment
	scripts/setup.sh

sitl:  ## Build the ArduPilot SITL binary
	uv run scripts/build-sitl.sh

plugin:  ## Build the Gazebo plugin (needs Gazebo installed)
	uv run scripts/build-plugin.sh

sim:  ## Run Gazebo + SITL + MAVProxy
	uv run scripts/run-sim.sh

sim-intercept:  ## Run the two-vehicle interceptor sim (Gazebo + 2x SITL)
	uv run scripts/run-intercept.sh

fake-gs:  ## Run the oracle ground station (pairs with sim-intercept)
	uv run python fake_gs/oracle.py

doctor:  ## Check the local environment
	uv run scripts/doctor.sh

clean:  ## Remove build artifacts
	uv run scripts/clean.sh
