#![no_main]

use risc0_zkvm::guest::env;
use match_engine::parser::run_engine;
risc0_zkvm::guest::entry!(main);

pub fn main() {
    let input: Vec<String> = env::read();

    let result = run_engine(&input);

    // write public output to the journal
    env::commit(&result);
}
