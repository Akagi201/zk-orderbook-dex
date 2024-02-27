# zk orderbook dex

A simplistic in memory LOB(Limit Order Book) match engine on zkVM.

## Run

```sh
just -l
just build
just bench
```

## Poc Explain

* <https://akagi201.notion.site/ZK-Orderbook-Dex-0567b96c3e864271b7c3f17072ff14a5?pvs=4>

## Benchmarks

My macOS hardware info:

![macos_info](assets/macos_info.png)

Bencharks on macOS (Metal for GPU)

![match_on_macos](assets/match_on_macos.png)

My linux hardware info:

![linux_info](assets/linux_info.png)

Bencharks on macOS (CUDA for GPU)

![match_on_linux](assets/match_on_linux.png)
