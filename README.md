# liboqs port to QNX

This is a port of the Open Quantum Safe project's [liboqs](https://github.com/open-quantum-safe/liboqs)  — a C library of post-quantum cryptographic algorithms — to **QNX Neutrino RTOS 8.0**. Only CPU-based reference implementations are built (no OpenSSL or hardware-accelerated backends).

With liboqs on QNX, NIST-standardized and candidate post-quantum algorithms run on safety-critical, automotive, and embedded QNX targets:

- **KEMs** — ML-KEM (Kyber), Classic McEliece, BIKE, FrodoKEM, NTRU, sntrup761, HQC
- **Signatures** — ML-DSA (Dilithium), Falcon, SPHINCS+, SLH-DSA, MAYO, CROSS, UOV, SNOVA


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

# run examples
./example_kem ML-KEM-768
./example_sig ML-DSA-65
./test_kem ML-KEM-768
./test_sig ML-DSA-65
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


```
test_kem ML-KEM-512: passed
test_kem ML-KEM-768: passed
test_kem ML-KEM-1024: passed
test_sig ML-DSA-44: passed
test_sig ML-DSA-65: passed
test_sig ML-DSA-87: passed
test_sig Falcon-512: passed
test_sig Falcon-1024: passed
test_sig SPHINCS+-SHA2-128s-simple: passed
Total: 9  Passed: 9  Failed: 0
```



## Supported architectures

- `aarch64le` 
- `x86_64` 

## License

The build files in this repository are MIT-licensed.
liboqs itself is MIT-licensed — see [`LICENSE.txt`](https://github.com/open-quantum-safe/liboqs/blob/main/LICENSE.txt) upstream.
