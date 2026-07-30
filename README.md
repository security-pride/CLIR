# CLIR

Artifact for **“CLIR: Liveness-Driven and Structure-Aware Fuzzing for the
Cranelift Compiler”** (ISSTA 2026).

CLIR generates random [Cranelift IR (CLIF)](https://github.com/bytecodealliance/wasmtime/tree/main/cranelift)
files. The repository includes the generator, architecture configurations, the
preprocessed IR corpus, and the Wasmtime/Cranelift revision used by CLIR.

## Build

Build the Docker image from the repository root:

```bash
docker build -t clir .
```

## Generate Cranelift IR

Create an output directory first:

```bash
mkdir -p output
```

Generate 10 x86-64 test cases:

```bash
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$PWD/output:/output" \
  clir single 10 /artifact/configs/arch_x86.toml /output/x86
```

To target another architecture, replace the configuration file with one of:

```text
configs/arch_x86.toml
configs/arch_aarch64.toml
configs/arch_riscv64.toml
configs/arch_s390x.toml
```

For example, on an AArch64 machine:

```bash
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$PWD/output:/output" \
  clir single 10 /artifact/configs/arch_aarch64.toml /output/aarch64
```

CLIR produces three CLIF files for every generated program:

```text
cranelift_ir_0_none.clif
cranelift_ir_0_speed.clif
cranelift_ir_0_speed_and_size.clif
```

They contain the same program with different Cranelift optimization levels.

CLIR also provides a compatible mode that generates shared programs for all
four architectures:

```bash
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$PWD/output:/output" \
  clir compatible 10 /output/compatible
```

Run `docker run --rm clir help` to see the other convenience commands.

## Run a generated CLIF file

The vendored `wasmtime/` directory contains Cranelift's command-line utility.
Build it on the host:

```bash
cd wasmtime
cargo build --release -p cranelift-tools --bin clif-util
cd ..
```

The resulting executable is:

```text
wasmtime/target/release/clif-util
```

Run one generated file:

```bash
./wasmtime/target/release/clif-util run \
  output/x86/cranelift_ir_0_none.clif
```

The generated CLIF files contain `; print: %main()`, so this command compiles
the program to native code, runs `%main`, and prints its return value.

The target in the CLIF file must match the host architecture. For example, run
files generated with `arch_x86.toml` on x86-64 and files generated with
`arch_aarch64.toml` on AArch64.

To run the Cranelift file-test directives without executing the program:

```bash
./wasmtime/target/release/clif-util test \
  output/x86/cranelift_ir_0_none.clif
```

## License

CLIR is released under the [MIT License](License). The vendored Wasmtime source
retains its upstream license in [`wasmtime/LICENSE`](wasmtime/LICENSE).

Artifact environment requirements and badge information are recorded in
[`REQUIREMENTS.md`](REQUIREMENTS.md) and [`STATUS`](STATUS).
