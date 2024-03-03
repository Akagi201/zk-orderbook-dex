use starknet::ContractAddress;

// ["BTC,40000,10,5,2"]
#[derive(Drop, Serde, starknet::storage_access::Store)]
struct MatchResult {
    symbol: felt252,
    price: u128,
    amount: u128,
    taker_order_id: u128,
    maker_order_id: u128,
}

#[derive(Drop, Copy, Serde, starknet::storage_access::Store)]
struct BalanceChange {
    user: ContractAddress,
    diff: i128,
}

#[starknet::interface]
trait IAssetManager<TContractState> {
    fn settle_order(
        ref self: TContractState,
        result: MatchResult,
        btc_changes: Array<BalanceChange>,
        usd_changes: Array<BalanceChange>
    );
}

#[starknet::contract]
mod AssetManager {
    use starknet::storage_access::Store;
    use starknet::{ContractAddress, get_caller_address};
    use super::BalanceChange;

    #[storage]
    struct Storage {
        user_btc_balance: LegacyMap::<ContractAddress, i128>,
        user_usd_balance: LegacyMap::<ContractAddress, i128>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        OrderMatch: OrderMatch,
    }

    #[derive(Drop, starknet::Event)]
    pub struct OrderMatch {
        #[key]
        pub symbol: felt252,
        pub price: u128,
        pub amount: u128,
        pub taker_order_id: u128,
        pub maker_order_id: u128,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.user_btc_balance.write(get_caller_address(), 0);
        self.user_usd_balance.write(get_caller_address(), 0);
    }

    // Public functions
    #[abi(embed_v0)]
    impl AssetManager of super::IAssetManager<ContractState> {
        fn settle_order(
            ref self: ContractState,
            result: super::MatchResult,
            btc_changes: Array<BalanceChange>,
            usd_changes: Array<BalanceChange>
        ) {
            let _caller = get_caller_address(); // todo: check ownership, and verify balance change
            let mut i = 0;
            while i < btc_changes.len() {
                let btc_change = *btc_changes.at(i);
                self
                    .user_btc_balance
                    .write(
                        btc_change.user,
                        self.user_btc_balance.read(btc_change.user) + btc_change.diff
                    );
                i += 1;
            };
            let mut i = 0;
            while i < usd_changes.len() {
                let usd_change = *usd_changes.at(i);
                self
                    .user_usd_balance
                    .write(
                        usd_change.user,
                        self.user_usd_balance.read(usd_change.user) + usd_change.diff
                    );
                i += 1;
            };
            self
                .emit(
                    OrderMatch {
                        symbol: result.symbol,
                        price: result.price,
                        amount: result.amount,
                        taker_order_id: result.taker_order_id,
                        maker_order_id: result.maker_order_id,
                    }
                );
        }
    }
}

#[cfg(test)]
mod tests {
    use core::array::ArrayTrait;
    use starknet::ContractAddress;
    use starknet::contract_address_const;
    use starknet::syscalls::deploy_syscall;
    use starknet::testing;
    use super::AssetManager::OrderMatch;
    use super::AssetManager;
    use super::BalanceChange;
    use super::IAssetManagerDispatcher;
    use super::IAssetManagerDispatcherTrait;
    use super::MatchResult;
    fn deploy(contract_class_hash: felt252, calldata: Array<felt252>) -> ContractAddress {
        let (address, _) = deploy_syscall(
            contract_class_hash.try_into().unwrap(), 0, calldata.span(), false
        )
            .unwrap();
        address
    }
    fn USERA() -> ContractAddress {
        contract_address_const::<'USERA'>()
    }
    fn USERB() -> ContractAddress {
        contract_address_const::<'USERB'>()
    }

    /// Pop the earliest unpopped logged event for the contract as the requested type
    /// and checks there's no more keys or data left on the event, preventing unaccounted params.
    ///
    /// This function also removes the first key from the event, to match the event
    /// structure key params without the event ID.
    ///
    /// This method doesn't currently work for components events that are not flattened
    /// because an extra key is added, pushing the event ID key to the second position.
    fn pop_log<T, +Drop<T>, +starknet::Event<T>>(address: ContractAddress) -> Option<T> {
        let (mut keys, mut data) = testing::pop_log_raw(address)?;

        // Remove the event ID from the keys
        assert!(keys.pop_front().is_some());

        let ret = starknet::Event::deserialize(ref keys, ref data);
        assert!(data.is_empty(), "Event has extra data");
        assert!(keys.is_empty(), "Event has extra keys");
        ret
    }

    fn assert_event_order_match(contract: ContractAddress, price: u128, amount: u128,) {
        let event = pop_log::<OrderMatch>(contract).unwrap();
        assert_eq!(event.price, price);
        assert_eq!(event.amount, amount);
    }

    fn setup_dispatcher() -> IAssetManagerDispatcher {
        let calldata = array![];
        let address = deploy(AssetManager::TEST_CLASS_HASH, calldata);
        IAssetManagerDispatcher { contract_address: address, }
    }

    #[test]
    fn order_match_works() {
        let mut dispatcher = setup_dispatcher();
        let mut btc_changes = array![];
        btc_changes.append(BalanceChange { user: USERA(), diff: -10, });
        btc_changes.append(BalanceChange { user: USERB(), diff: 10, });
        let mut usd_changes = array![];
        usd_changes.append(BalanceChange { user: USERA(), diff: 400000, });
        usd_changes.append(BalanceChange { user: USERB(), diff: -400000, });
        dispatcher
            .settle_order(
                MatchResult {
                    symbol: 0, price: 40000, amount: 10, taker_order_id: 5, maker_order_id: 2,
                },
                btc_changes,
                usd_changes,
            );

        assert_event_order_match(dispatcher.contract_address, 40000, 10);
    }
}
