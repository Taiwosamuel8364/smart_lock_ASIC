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

PE_RTL = $(RTL_DIR)/npu/pe.v
PE_TB  = $(TB_DIR)/tb_pe.v


# Output Targets
SIM_EXEC   = $(SIM_DIR)/spi_sram_tb.out
VCD_FILE   = $(SIM_DIR)/spi_sram.vcd
PE_EXEC= $(SIM_DIR)/pe_tb.out
PE_VCD= $(SIM_DIR)/pe.vcd

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

# 6. Rule to compile and run PE simulation
pe_sim: $(PE_RTL) $(PE_TB) | $(SIM_DIR)
	$(IVERILOG) -g2012 -o $(PE_EXEC) $(PE_RTL) $(PE_TB)
	$(VVP) $(PE_EXEC)

pe_wave: $(PE_VCD)
	@echo "==> Opening Waveforms in GTKWave..."
	$(GTKWAVE) $(PE_VCD) &

# Help menu
.PHONY: help
help:
	@echo "Usage:"
	@echo "  make         - Compile and run SPI-SRAM subsystem simulation"
	@echo "  make sim     - Same as 'make'"
	@echo "  make wave    - Launch GTKWave to inspect spi_sram.vcd"
	@echo "  make clean   - Remove compiled binaries and wave logs"

# Systolic Array Simulation
ARRAY_RTL = $(RTL_DIR)/npu/pe.v $(RTL_DIR)/npu/systolic_array.v
ARRAY_TB  = $(TB_DIR)/tb_systolic_array.v
ARRAY_EXEC= $(SIM_DIR)/systolic_tb.out

.PHONY: array_sim
array_sim: $(ARRAY_RTL) $(ARRAY_TB) | $(SIM_DIR)
	$(IVERILOG) -g2012 -o $(ARRAY_EXEC) $(ARRAY_RTL) $(ARRAY_TB)
	$(VVP) $(ARRAY_EXEC)

# NPU Simulation
NPU_RTL = $(RTL_DIR)/memory/sram.v \
          $(RTL_DIR)/memory/spi2ram.v \
          $(RTL_DIR)/memory/spi_sram_subsystem.v \
          $(RTL_DIR)/npu/pe.v \
          $(RTL_DIR)/npu/systolic_array.v \
          $(RTL_DIR)/npu/npu_controller.v \
          $(RTL_DIR)/npu/npu.v

NPU_TB  = $(TB_DIR)/tb_npu.v
NPU_EXEC= $(SIM_DIR)/npu_tb.out
NPU_VCD= $(SIM_DIR)/npu_integration.vcd

.PHONY: npu_sim
npu_sim: $(NPU_RTL) $(NPU_TB) | $(SIM_DIR)
	$(IVERILOG) -g2012 -o $(NPU_EXEC) $(NPU_RTL) $(NPU_TB)
	$(VVP) $(NPU_EXEC)

npu_wave: $(NPU_VCD)
	@echo "==> Opening Waveforms in GTKWave..."
	$(GTKWAVE) $(NPU_VCD) &