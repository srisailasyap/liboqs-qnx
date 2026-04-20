#!/bin/sh
# Fast smoke test: only the NIST-standardized post-quantum algorithms
# (ML-KEM = Kyber, ML-DSA = Dilithium, Falcon, SPHINCS+ SHA2-128s).
# Takes ~1-2 minutes on Pi 5 vs 15-30 min for the full sweep.

export LD_LIBRARY_PATH="$(pwd):$LD_LIBRARY_PATH"

total=0
passed=0
failed=0

run() {
    bin=$1; alg=$2
    printf "%s %s: " "$bin" "$alg"
    ./$bin "$alg" >/tmp/liboqs-last.log 2>&1
    if [ $? -eq 0 ]; then
        echo passed; passed=$((passed + 1))
    else
        echo failed; failed=$((failed + 1))
    fi
    total=$((total + 1))
}

for alg in ML-KEM-512 ML-KEM-768 ML-KEM-1024; do
    run test_kem "$alg"
done

for alg in ML-DSA-44 ML-DSA-65 ML-DSA-87 Falcon-512 Falcon-1024 SPHINCS+-SHA2-128s-simple; do
    run test_sig "$alg"
done

echo ""
echo "Total: $total  Passed: $passed  Failed: $failed"
