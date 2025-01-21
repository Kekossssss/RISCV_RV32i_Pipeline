# RISCV_RV32i_Pipeline
First try at implementing a RISCV RV32i pipeline architecture, started for a school project and some personnal work on my monocycle architecture I've previously done. This is a very simple implementation, which do not currently include branch prediction, but does have a full bypass.

The repository is organized as follow :
   - In the "hdl_src" folder, you will find all of the ".sv" files containing the modules that compose the architecture
   - In the "testbench" folder, you will find all of the ".sv" files containing testbench made to stress and test almost all modules composing the architecture
   - In the "firmware" folder, you will find a bunch of assembly programms made to stress test the architecture, as well as their compiled version and some data_memory files to use with each one
