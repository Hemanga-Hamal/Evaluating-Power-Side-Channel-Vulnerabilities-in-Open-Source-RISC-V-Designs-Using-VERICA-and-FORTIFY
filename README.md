# Power Side-Channel Analysis Tools and Evaluation

This repository contains tools and test cases for evaluating power side-channel vulnerabilities in cryptographic hardware designs at the RTL/HDL level. The focus is on pre-silicon analysis using VERICA and supporting synthesis tools.

## Project Overview

This project evaluates power side-channel leakage of cryptographic hardware designs before fabrication. Power side-channel attacks exploit variations in power consumption to extract secret information such as cryptographic keys. By analyzing designs at the RTL/HDL level, we can identify vulnerabilities early in the development cycle.

### Key Tools

- **VERICA**: Automated verification framework for analyzing digital circuits against side-channel and fault injection attacks at the logic level
- **Yosys**: Open-source synthesis suite for converting RTL designs to gate-level netlists
- **FORTIFY** and **PLAN**: Additional frameworks for power side-channel characterization (documentation included)

## Repository Structure

```
.
├── Verica/              # VERICA tool and test cases
│   └── case-studies/
│       └── personal-tests/
├── Yosys/               # Synthesis configurations and test cases
│   ├── working_yosys_config.ys
│   └── lib/            # Custom gate libraries
└── Documents/          # Installation guides and run instructions
```

## Prerequisites

### System Requirements

- Ubuntu/WSL2 environment (tested on Ubuntu)
- Minimum 8GB RAM (16GB recommended for complex designs)
- Multi-core processor (VERICA supports parallel execution)

### Dependencies

#### For VERICA -> Use VERICA install guide. Found in VERICA folder Readme.

```bash
sudo apt update
sudo apt install build-essential autoconf libtool wget
sudo apt install libboost-graph-dev libboost-program-options-dev
```

#### For Yosys

Download and install OSS CAD Suite or build Yosys from source. Refer to the Yosys documentation for detailed installation instructions.

## Installation

### VERICA Setup

1. Install Boost Graph Library:
```bash
sudo apt install libboost-graph-dev libboost-program-options-dev
```

2. Install CUDD library:
```bash
wget https://github.com/davidkebo/cudd/raw/main/cudd_versions/cudd-3.0.0.tar.gz
tar -xvzf cudd-3.0.0.tar.gz
cd cudd-3.0.0
./configure --enable-shared --enable-obj
make -j$(nproc)
sudo make install
```

3. Clone and build VERICA:
```bash
git clone https://github.com/Chair-for-Security-Engineering/VERICA.git
cd VERICA
```

4. Update the makefile (line 49):
```makefile
INCLUDES := -I $(INCLUDE_DIR) -I /usr/include -I /usr/local/include
```

5. Build:
```bash
make release
```

### Yosys Setup

For Windows users with OSS CAD Suite:
```bash
D:\oss-cad-suite\start.bat
yosys
```

For Linux/WSL:
```bash
yosys -s <script_file>.ys
```

## Usage

### Running VERICA

Basic execution:
```bash
bin/release/Verica -c config/Verica.json
```

### Key Configuration Parameters

VERICA uses JSON configuration files. Important parameters include:

- **verbose**: Verbosity level (0-3)
  - 0: Minimal output
  - 1: Evaluation summary
  - 2: Normal with annotations
  - 3: Detailed with line-by-line information

- **cores**: Number of CPU cores (0 = automatic maximum)
- **memory**: Memory per core in GB
- **netlist/file**: Path to Verilog netlist
- **library/file**: Gate library definition
  - Use `cell/Instructions.txt` for .nl files
  - Use `cell/nang45.txt` for Verilog gate-level netlists

- **side-channel/enable**: Enable side-channel verification (true/false)
- **side-channel/configuration/order**: Security order analysis (0 = auto-detect maximum)

### Running Yosys Synthesis

Example synthesis flow:
```bash
yosys -s working_yosys_config.ys
```

Basic synthesis script structure:
```tcl
read_verilog design.v
hierarchy -top top_module
proc; opt; memory; fsm; opt
techmap; opt
abc -liberty library.lib
write_verilog synthesized.v
stat
```

## Test Cases

Test cases are organized in:
- `Verica/case-studies/personal-tests/`: Custom verification scenarios
- `Yosys/`: Synthesis test cases with corresponding configurations

## Documentation

Detailed documentation is available in the `Documents/` folder:

- **YOSYS COMMANDS.docx**: Command reference and example flows
- **Setup WSL.docx**: Complete installation instructions for VERICA and related tools
- **Documents And Notes.docx**: Project background, paper summaries, and theoretical foundations

## References

### Key Papers

1. **VERICA**: Knichel et al., "VERICA - Verification of Combined Attacks" (2022)
2. **FORTIFY**: Raghunathan et al., "Analytical Pre-Silicon Side-Channel Characterization" (IEEE 2021)
3. **PLAN**: Joseph et al., "PARAM: A Microprocessor Hardened for Power Side-Channel Attack Resistance" (IEEE 2020)
4. **Borrowed Time**: Moos et al., "On Borrowed Time - Preventing Static Side-Channel Analysis" (NDSS 2025)

### Tool Repositories

- VERICA: https://github.com/Chair-for-Security-Engineering/VERICA
- FORTIFY/PLAN: https://github.com/avlakshmy/power-side-channel-analysis
- Yosys: https://github.com/YosysHQ/yosys

## Known Limitations

### VERICA
- Complexity increases exponentially with circuit size and fault injection count
- Large circuits may exceed computational resources even with increased cores and memory
- Multi-bit fault injection dramatically increases verification time

### Analysis Scope
- Current focus is on combinational logic and register-level leakage
- Dynamic power analysis requires additional simulation tools
- Post-quantum cryptographic implementations remain primary evaluation target

## Contributing

This is a research project. For questions or collaboration inquiries, please refer to the original tool repositories or contact the project maintainers.

## License

This repository contains integration work. Individual tools maintain their original licenses:
- VERICA: Check original repository
- Yosys: ISC License
- FORTIFY/PLAN: Check original repository