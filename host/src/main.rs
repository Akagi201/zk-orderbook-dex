mod cli;
mod executor;
mod host;

use clap::Parser;

use crate::{cli::Cli, executor::run_guest, host::run_host};

fn main() {
    env_logger::init();
    let cli = Cli::parse();
    let (input, result) = run_host(cli.instructions);
    run_guest(cli.dry_run, input, result);
}
