# File Structure

* src/DE2\_115
	* All files related to the FPGA
* src/test
	* testbenchs
* include/
	* Verilog files which only contain include lines
* sim/ and lint/
	* Working directories

# Linting

Lint the core file(s)
    cd lint/
    make ../include/wrapper

Lint the wrapper file(s)
    cd lint/
    make ../include/core

# Simulation

Simulate the core file(s)
    cd sim/
    make ../include/wrapper

Simulate the wrapper file(s)
    cd sim/
    make ../include/core

Note that I only dump partial signals during the simulation of wrapper.
