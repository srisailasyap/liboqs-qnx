# liboqs port to QNX

This is a port of the Open Quantum Safe project's [liboqs](https://github.com/open-quantum-safe/liboqs) <img src="https://avatars.githubusercontent.com/u/31419478?s=48&v=4" width=24 /> — a C library of post-quantum cryptographic algorithms — to **QNX Neutrino RTOS 8.0**. Only CPU-based reference implementations are built (no OpenSSL or hardware-accelerated backends).

With liboqs on QNX, NIST-standardized and candidate post-quantum algorithms run on safety-critical, automotive, and embedded QNX targets:

- **KEMs** — ML-KEM (Kyber), Classic McEliece, BIKE, FrodoKEM, NTRU, sntrup761, HQC
- **Signatures** — ML-DSA (Dilithium), Falcon, SPHINCS+, SLH-DSA, MAYO, CROSS, UOV, SNOVA

The latest release was tested with **liboqs `v0.15.0`** on a Raspberry Pi 5 (QNX 8.0, `aarch64le`) and an x86_64 QNX target (QEMU). All NIST-standardized algorithms pass `test_kem` / `test_sig`.

| | |
|---|---|
| **liboqs tag** | `v0.15.0` |
| **Source fork** (QNX patches applied) | [`srisailasyap/liboqs @ qnx-0.15.0`](https://github.com/srisailasyap/liboqs/tree/qnx-0.15.0) |
| **QNX SDP** | 8.0 |
| **Tested targets** | Raspberry Pi 5 (`nto-aarch64-le`), `nto-x86_64-o` (QEMU) |

> **NOTE:** QNX ports are only supported from a Linux host operating system.

Use `$(nproc)` in place of `4` in `JLEVEL=` / `-j` to use all cores. 32 GB of RAM is recommended with `JLEVEL=$(nproc)`.

## Build in a Docker container

Pre-requisite: [Install Docker on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

```bash
# Create a workspace
mkdir -p ~/qnx_workspace && cd ~/qnx_workspace

# Clone the QNX build-files repo (provides the Docker scripts)
git clone https://github.com/qnx-ports/build-files.git

# Build the Docker image and create a container
cd build-files/docker
./docker-build-qnx-image.sh
./docker-create-container.sh

# --- inside the Docker container ---
source ~/qnx800/qnxsdp-env.sh

cd ~/qnx_workspace
git clone https://github.com/srisailasyap/liboqs-qnx.git build-files/ports/liboqs
git clone -b qnx-0.15.0 https://github.com/srisailasyap/liboqs.git

QNX_PROJECT_ROOT="$(pwd)/liboqs" make -C build-files/ports/liboqs install -j4
```

## Build natively on a host

```bash
mkdir -p ~/qnx_workspace && cd ~/qnx_workspace

git clone https://github.com/qnx-ports/build-files.git
git clone https://github.com/srisailasyap/liboqs-qnx.git build-files/ports/liboqs
git clone -b qnx-0.15.0 https://github.com/srisailasyap/liboqs.git

source ~/qnx800/qnxsdp-env.sh

QNX_PROJECT_ROOT="$(pwd)/liboqs" make -C build-files/ports/liboqs install -j4
```

Library and headers install into `$QNX_TARGET/{aarch64le,x86_64}/usr/local/`.
Test/example/benchmark binaries live under `nto-{aarch64-le,x86_64-o}/build/tests/`.

## Run on the target

Transfer the library and the binaries you need to the QNX target:

```bash
TARGET_HOST=<target-ip-or-hostname>
BUILD=build-files/ports/liboqs/nto-aarch64-le/build

# Shared library
scp -p $QNX_TARGET/aarch64le/usr/local/lib/liboqs.so* qnxuser@$TARGET_HOST:/tmp/

# Tests + examples + benchmarks
scp $BUILD/tests/test_kem $BUILD/tests/test_sig \
    $BUILD/tests/example_kem $BUILD/tests/example_sig \
    $BUILD/tests/speed_kem $BUILD/tests/speed_sig \
    qnxuser@$TARGET_HOST:/tmp/
```

On the target:

```bash
ssh qnxuser@$TARGET_HOST
cd /tmp
export LD_LIBRARY_PATH=/tmp:$LD_LIBRARY_PATH

# Minimal smoke test
./example_kem ML-KEM-768
./example_sig ML-DSA-65

# Correctness tests
./test_kem ML-KEM-768
./test_sig ML-DSA-65

# 3-second throughput benchmarks
./speed_kem --duration 3 ML-KEM-768
./speed_sig --duration 3 ML-DSA-65
```

## Run the test suite

The helper script **`run-tests.sh`** runs `test_kem` / `test_sig` for the NIST-standardized algorithms (ML-KEM, ML-DSA, Falcon, SPHINCS+-SHA2-128s) and completes in ~1–2 minutes on a Pi 5.

```bash
scp run-tests.sh $BUILD/tests/test_kem $BUILD/tests/test_sig \
    qnxuser@$TARGET_HOST:/tmp/

ssh qnxuser@$TARGET_HOST
cd /tmp
chmod +x run-tests.sh
./run-tests.sh
```

The script prints a `pass`/`fail` line per algorithm and ends with a summary:

```
Total: 9  Passed: 9  Failed: 0
```

## Benchmarks

Measured on a **Raspberry Pi 5** (Cortex-A76 @ 2.4 GHz) running QNX 8.0 (`aarch64le`)

| Algorithm | Operation | Time (µs) | Ops / sec |
|---|---|---:|---:|
| **ML-KEM-768** | keygen | 74.1  | 13,503 |
|                | encaps | 76.3  | 13,098 |
|                | decaps | 61.4  | 16,285 |
| **ML-DSA-65**  | keypair | 225.6 | 4,433  |
|                | sign    | 887.9 | 1,127  |
|                | verify  | 196.2 | 5,097  |


## Supported architectures

- `aarch64le` — Raspberry Pi 5
- `x86_64` — QNX QEMU

## License

The build files in this repository are MIT-licensed.
liboqs itself is MIT-licensed — see [`LICENSE.txt`](https://github.com/open-quantum-safe/liboqs/blob/main/LICENSE.txt) upstream.
