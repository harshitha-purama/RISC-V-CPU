# RISC-V CPU Design Project

## Introduction

This project implements a fully functional **single-cycle and 5-stage pipelined RISC-V RV32I processor** designed in Verilog. The processor supports the full base RV32I instruction set including arithmetic, logical, memory access, and control flow instructions. The design is verified through simulation using open-source tools like **Icarus Verilog** and **GTKWave**. 

Additionally, this project incorporates **memory-mapped I/O** peripherals, such as LED outputs and switches inputs, to simulate real-world embedded system interactions.

## Methodology

The project was developed incrementally following these key steps:

1. **Initial Single-Cycle CPU Design:**
   - Designed the datapath and control logic for a single-cycle RV32I processor.
   - Implemented modules including the ALU, register file, instruction and data memory.
   - Built a testbench to simulate example programs like factorial and Fibonacci.
   - Verified functionality by cross-comparison with the Ripes simulator and waveform inspection.

2. **Transition to a Pipelined Architecture:**
   - Extended the design to a 5-stage pipeline: Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory Access (MEM), and Write Back (WB).
   - Added pipeline registers between stages to pass instruction and data along the pipeline.
   - Implemented simplified hazard detection and forwarding logic to handle data dependencies.
   - Added program counter (PC) update logic and control signal pipeline.

3. **Memory-Mapped I/O Integration:**
   - Extended data memory to recognize special high-address ranges for I/O.
   - Created a simulated LED peripheral that can be controlled by writes to a specific address.
   - Created a simulated switch peripheral that reads input from a memory-mapped address.
   - Verified I/O operations through testbench stimulus and waveform observation.

4. **Verification and Debugging:**
   - Inspected waveforms in GTKWave to analyze pipeline behavior and timing.
   - Modified testbench and program memory to test corner cases and coverage.

## How This Processor Works

- The processor fetches instructions from an instruction memory based on the **Program Counter (PC)**.
- Instructions are decoded to generate control signals and extract operand registers.
- Execution occurs in the ALU, performing operations such as addition, subtraction, logical and comparison.
- Memory operations read or write to data memory; loads fetch data into registers, stores write data back to memory.
- Memory-mapped I/O allows the CPU to send output signals (e.g., turn on LEDs) or read input signals (e.g., switches).
- The 5-stage pipeline allows overlapping execution of multiple instructions, improving throughput.
- Pipeline registers hold intermediate signals between stages.
- Hazard detection logic prevents data corruption and stalls the pipeline when necessary.
- At the write-back stage, results are written into the register file.
- Textual debug outputs trace every register write and key state changes.

## Learnings

- Deep understanding of **RISC-V RV32I instruction set architecture** and how instructions operate at the microarchitectural level.
- Experience building a **CPU datapath and control unit**, including instruction decoding and ALU design.
- Practical implementation of a **5-stage pipeline**, learning how to handle hazards and forwarding.
- Insight into **memory-mapped I/O design**, connecting CPU operation with simulated hardware peripherals.
- Mastery of hardware description language **Verilog** for RTL coding and simulation.
- Familiarity with open-source EDA tools—**Icarus Verilog for simulation** and **GTKWave for waveform analysis**.
- Debugging techniques with **textual outputs** and waveform examination.
- Incremental design and verification methodologies in digital design.

## Outcomes

- Successfully designed and simulated a **fully functional pipelined RISC-V CPU** with working memory-mapped I/O.
- Verified correctness by running various test programs including **factorial, Fibonacci, and custom algorithm implementations**.
- Developed a reusable testbench and modular RTL code that can be extended with additional ISA features.
- Created a foundation for further exploration into advanced microarchitecture topics such as branch prediction, interrupts, and multi-core design.
- Documented design flow and verification process that can be showcased in interviews and portfolios.

## Challenges and Hard Points

- **Pipeline Hazards:** Managing data hazards and forwarding properly to avoid incorrect results was conceptually and practically challenging.
- **Branching and Control Flow:** Implementing and testing branch instructions in the pipeline required careful handling of control hazards and pipeline flushing.
- **Immediate Value Decoding:** Correctly extracting and sign-extending immediate values for various instruction types required detailed bit-field manipulations.
- **Memory-Mapped I/O Integration:** Mapping peripheral behavior into memory address space and simulating realistic hardware interaction took careful address decoding and signal coordination.
- **Debugging in Simulation:** Interpreting waveform data and combining it with textual debug output was key to identifying subtle bugs.
- **Modular Design:** Balancing clarity and modularity in Verilog coding to keep the design maintainable was a continuous focus.

---

Feel free to customize or expand this README based on your preferences or additional project details. If you want, I can help you generate a ready-to-commit `README.md` file text that you can directly push to your repo. Just say!
