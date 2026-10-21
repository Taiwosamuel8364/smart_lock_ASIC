IVERILOG = iverilog
VVP      = vvp
GTKWAVE  = gtkwave
MKDIR    = mkdir -p
RM       = rm -rf

# Directories
RTL_DIR  = rtl
TB_DIR   = tb
SIM_DIR  = sim

# Source Files
MEMORY_RTL = $(RTL_DIR)/memory/sram.v \
             $(RTL_DIR)/memory/spi2ram.v \
             $(RTL_DIR)/memory/spi_sram_subsystem.v

MEMORY_TB  = $(TB_DIR)/tb_spi_sram.v

# Output Targets
SIM_EXEC   = $(SIM_DIR)/spi_sram_tb.out
VCD_FILE   = $(SIM_DIR)/spi_sram.vcd

# Default Rule
.PHONY: all
all: sim

# 1. Ensure build directory exists
$(SIM_DIR):
	$(MKDIR) $(SIM_DIR)

# 2. Compile Verilog files into executable simulation binary
$(SIM_EXEC): $(MEMORY_RTL) $(MEMORY_TB) | $(SIM_DIR)
	@echo "==> Compiling Verilog RTL & Testbench..."
	$(IVERILOG) -g2012 -o $(SIM_EXEC) $(MEMORY_RTL) $(MEMORY_TB)

# 3. Run VVP simulation to execute testbench and generate VCD
.PHONY: sim
sim: $(SIM_EXEC)
	@echo "==> Executing Simulation..."
	$(VVP) $(SIM_EXEC)

# 4. Open GTKWave to view generated VCD waveforms
.PHONY: wave
wave: $(VCD_FILE)
	@echo "==> Opening Waveforms in GTKWave..."
	$(GTKWAVE) $(VCD_FILE) &

# 5. Clean simulation outputs
.PHONY: clean
clean:
	@echo "==> Cleaning simulation artifacts..."
	$(RM) $(SIM_DIR)/*.out $(SIM_DIR)/*.vcd

# Help menu
.PHONY: help
help:
	@echo "Usage:"
	@echo "  make         - Compile and run SPI-SRAM subsystem simulation"
	@echo "  make sim     - Same as 'make'"
	@echo "  make wave    - Launch GTKWave to inspect spi_sram.vcd"
	@echo "  make clean   - Remove compiled binaries and wave logs"