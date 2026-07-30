# CLIR Artifact Requirements

## Packaged and tested platform

- Container format: Docker or Podman using the included `Dockerfile`
- Container operating system: Ubuntu 22.04
- Supported host CPU architectures: x86_64 (amd64) and AArch64 (arm64)
- Rust toolchain used while building the image: 1.91.0
- MongoDB version in the image: 7.0

The four Cranelift profiles (`x86_64`, `aarch64`, `riscv64`, and `s390x`) describe
the generated IR targets. Compatible-mode generation does not require the host
CPU to match all four targets.

## Host software

- Docker Engine 24 or newer, Docker Desktop, or a compatible Podman version
- A POSIX-compatible shell and `make` for the convenience commands

The runtime experiments do not download files or contact external services.
Building the image requires internet access to obtain the pinned Ubuntu,
MongoDB, Rust, and Cargo dependencies.

## Recommended hardware

### Smoke test and reduced evaluation

- 4 CPU cores
- 8 GB RAM
- 15 GB free disk space for the build cache and image
- Less than 1 GB free disk space for generated output

### Full generation experiment

- 8 CPU cores
- 16 GB RAM
- 20 GB free disk space for the build cache and image
- At least 5 GB free disk space for output; increase this proportionally when
  `NUM_CASES` is greater than 1,000

No GPU, privileged container, network access at runtime, or non-commodity
hardware is required.

## Expected time

Times depend strongly on network and CPU performance:

- First image build: approximately 15-45 minutes
- Smoke test after the image is built: under 5 minutes
- Reduced evaluation (10 cases per mode): under 30 minutes
- Full generation experiment (1,000 cases per mode): allow up to 2 hours

These are conservative limits intended for AEC planning. During packaging on
an Apple Silicon host with Docker Desktop, the smoke and reduced procedures
completed in seconds, and the full experiment completed in approximately 42
seconds with 3.1 GB of output. The scripts print progress as each case is
generated.
