module suizeta::universal;

use sui::balance::{Self, Balance};
use sui::coin::Coin;

public struct Vault<phantom COIN_TYPE> has key, store {
    id: UID,
    balance: Balance<COIN_TYPE>,
}

public entry fun on_call<COIN_TYPE>(
    coins: Coin<COIN_TYPE>,
    _randomValue: u64,
    ctx: &mut TxContext,
) {
    let mut vault = Vault {
        id: object::new(ctx),
        balance: balance::zero<COIN_TYPE>(),
    };

    balance::join(&mut vault.balance, coins.into_balance());

    // make the vault shared
    transfer::share_object(vault);
}
