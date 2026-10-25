# Local self-checking smoke test. The official CMOS5L template supplies
# its own cocotb Makefile/CI; retain those when merging this project.
PROJECT_SOURCES = project.v swapio_core.v
.PHONY: sim
sim:
	$(MAKE) -C .. sim-tt
