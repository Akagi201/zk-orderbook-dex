# build host
build:
  cargo build -p host -r -F metal
  cargo build -p host -r --target-dir cpu

# dry run zkvm without proving
dry-run:
  RUST_LOG="executor=info" RISC0_DEV_MODE=1 ./target/release/host -d

# run and full proving on gpu
full-prove-gpu:
  RUST_LOG="executor=info" RISC0_DEV_MODE=0 ./target/release/host

# run and full proving on cpu
full-prove-cpu:
  RUST_LOG="executor=info" RISC0_DEV_MODE=0 ./cpu/release/host

# run and full proving on bonsai
full-prove-bonsai:
  BONSAI_API_KEY="BTV837rYOU79cF4e9FLSq5sze1sVkzxK775mguK1" BONSAI_API_URL="https://api.bonsai.xyz/" RUST_LOG="executor=info" RISC0_DEV_MODE=0 ./target/release/host

# benchmark different runs
bench:
  hyperfine -r 1 'just dry-run' 'just full-prove-gpu' 'just full-prove-cpu' 'just full-prove-bonsai'