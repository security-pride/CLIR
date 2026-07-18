# CLIR

CLIR: Liveness-Driven and Structure-Aware Fuzzing for the Cranelift Compiler


## Overview

The **architecture-aware profiles** mentioned in the paper refer to the TOML configuration files located in the `configs/` directory. CLIR operates in two primary modes:

* **`single` mode**: Corresponds to the **Target-Specific Mode** in the paper. It generates IR tailored to a single backend's full feature set.
* **`compatible` mode**: Corresponds to the **Compatible Mode** in the paper. It computes the feature intersection of multiple profiles to generate portable IR for **differential testing**.


## Getting Started

1. Set environments.

CLIR should run well on a server with Ubuntu 22.04.
Please download [Docker](https://docs.docker.com/get-docker/) first.
```bash
sudo docker build -t clir .
sudo docker run -it clir # run a docker container
```

2. Start generating cranelift ir files

```bash
# in the docker container 
cd home/ubuntu/CLIR/
cargo run --bin ir_generator
# single mode example
cargo run --bin ir_generator -- --num 1000 single configs/arch_x86.toml output
# compatible mode example 
cargo run --bin ir_generator -- --num 1000 compatible configs/arch_x86.toml configs/arch_aarch64.toml configs/arch_riscv64.toml configs/arch_s390x.toml output
```

The generated IR files are stored in `home/ubuntu/CLIR/output`.


## Found Bugs

Within 72 hours of testing, **CLIR** discovered **24 unique bugs** in the Cranelift compiler, with **19 confirmed** and **9 fixed**.

> **Note on Issue Count:** The number of listed GitHub issues below may be fewer than the total number of unique bugs detected. This is because **multiple distinct bugs were consolidated into single tracking issues** by the maintainers (e.g., grouping similar crash patterns or architecture-specific failures) to facilitate efficient triage and fixing.

[#10852](https://github.com/bytecodealliance/wasmtime/issues/10852)
[#10906](https://github.com/bytecodealliance/wasmtime/issues/10906)
[#10921](https://github.com/bytecodealliance/wasmtime/issues/10921)
[#10929](https://github.com/bytecodealliance/wasmtime/issues/10929)
[#10951](https://github.com/bytecodealliance/wasmtime/issues/10951)
[#10976](https://github.com/bytecodealliance/wasmtime/issues/10976)
[#10982](https://github.com/bytecodealliance/wasmtime/issues/10982)
[#10996](https://github.com/bytecodealliance/wasmtime/issues/10996)
[#11050](https://github.com/bytecodealliance/wasmtime/issues/11050)
[#11133](https://github.com/bytecodealliance/wasmtime/issues/11133)
[#11183](https://github.com/bytecodealliance/wasmtime/issues/11183)
[#11233](https://github.com/bytecodealliance/wasmtime/issues/11233)
[#11234](https://github.com/bytecodealliance/wasmtime/issues/11234)
[#11240](https://github.com/bytecodealliance/wasmtime/issues/11240)
[#12170](https://github.com/bytecodealliance/wasmtime/issues/12170)
[#12195](https://github.com/bytecodealliance/wasmtime/issues/12195)
[#12197](https://github.com/bytecodealliance/wasmtime/issues/12197)