# syntax=docker/dockerfile:1

ARG UBUNTU_VERSION=22.04
ARG RUST_VERSION=1.91.0

FROM ubuntu:${UBUNTU_VERSION} AS builder

ARG RUST_VERSION
ENV DEBIAN_FRONTEND=noninteractive \
    CARGO_HOME=/opt/cargo \
    RUSTUP_HOME=/opt/rustup \
    PATH=/opt/cargo/bin:${PATH}

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get -o Acquire::Retries=5 update \
    && apt-get -o Acquire::Retries=5 install --fix-missing --yes --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        pkg-config

RUN curl --proto '=https' --tlsv1.2 \
        --fail --silent --show-error --location --retry 5 --retry-all-errors \
        https://sh.rustup.rs \
        | sh -s -- -y --profile minimal --default-toolchain "${RUST_VERSION}"

WORKDIR /artifact
COPY Cargo.toml Cargo.lock rust-toolchain.toml ./
COPY crates ./crates
COPY src ./src
COPY wasmtime ./wasmtime

RUN --mount=type=cache,target=/opt/cargo/registry \
    --mount=type=cache,target=/opt/cargo/git \
    --mount=type=cache,target=/artifact/target \
    cargo build --locked --release --bin ir_generator \
    && strip target/release/ir_generator \
    && install --mode=0755 target/release/ir_generator /opt/clir


FROM ubuntu:${UBUNTU_VERSION} AS artifact

ARG MONGODB_MAJOR=7.0
ENV DEBIAN_FRONTEND=noninteractive \
    CLIR_ROOT=/artifact \
    CLIR_OUTPUT=/output
LABEL org.opencontainers.image.title="CLIR ISSTA 2026 Artifact" \
      org.opencontainers.image.description="Liveness-driven and structure-aware Cranelift IR generator" \
      org.opencontainers.image.source="https://github.com/security-pride/CLIR" \
      org.opencontainers.image.licenses="MIT"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get -o Acquire::Retries=5 update \
    && apt-get -o Acquire::Retries=5 install --fix-missing --yes --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
    && curl --fail --silent --show-error --location --retry 5 --retry-all-errors \
        "https://www.mongodb.org/static/pgp/server-${MONGODB_MAJOR}.asc" \
        | gpg --dearmor --output /usr/share/keyrings/mongodb-server.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-server.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/${MONGODB_MAJOR} multiverse" \
        > /etc/apt/sources.list.d/mongodb-org.list \
    && apt-get -o Acquire::Retries=5 update \
    && apt-get -o Acquire::Retries=5 install --fix-missing --yes --no-install-recommends \
        mongodb-database-tools \
        mongodb-org-server

RUN useradd --create-home --uid 1000 --shell /bin/bash clir \
    && mkdir -p /artifact /output \
    && chown clir:clir /output

WORKDIR /artifact
COPY --chown=clir:clir . .
COPY --from=builder /opt/clir /usr/local/bin/clir

RUN chmod +x /artifact/start.sh /artifact/scripts/*.sh

USER clir
ENTRYPOINT ["/artifact/scripts/entrypoint.sh"]
CMD ["help"]
