use methods::{MATCH_ORDER_ELF, MATCH_ORDER_ID};
use risc0_zkvm::{default_executor, default_prover, ExecutorEnv};

pub fn run_guest(dry_run: bool, input: Vec<String>, result: Vec<String>) {
    let env = ExecutorEnv::builder()
        .write(&input)
        .unwrap()
        .build()
        .unwrap();

    if dry_run {
        let executor = default_executor();
        let session_info = executor.execute_elf(env, MATCH_ORDER_ELF).unwrap();
        let guest_result: Vec<String> = session_info.journal.decode().unwrap();
        if guest_result == result {
            println!("Dry run match result success, result: {:?}", guest_result);
        } else {
            println!("Dry run match result failed");
        }
    } else {
        let prover = default_prover();
        let receipt = prover.prove_elf(env, MATCH_ORDER_ELF).unwrap();
        let guest_result: Vec<String> = receipt.journal.decode().unwrap();
        if guest_result == result {
            println!(
                "Full proving match result success, result: {:?}",
                guest_result
            );
        } else {
            println!("Full proving match result failed");
            return;
        }
        receipt.verify(MATCH_ORDER_ID).expect(
            "Code you have proven should successfully verify; did you specify the correct image ID?",
        );
        println!("Proof verified successfully");
    }
}
