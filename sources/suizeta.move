module suizeta::connected;

use sui::address::from_bytes;
use sui::coin::Coin;
use suizeta::cetusmock::{GlobalConfig, Partner, Pool, Clock, swap_a2b};

public entry fun on_call<SOURCE_COIN, TARGET_COIN>(
    in_coins: Coin<SOURCE_COIN>,
    cetus_config: &GlobalConfig,
    pool: &mut Pool<SOURCE_COIN, TARGET_COIN>,
    cetus_partner: &mut Partner,
    clock: &Clock,
    data: vector<u8>,
    ctx: &mut TxContext,
) {
    let coins_out = swap_a2b<SOURCE_COIN, TARGET_COIN>(
        cetus_config,
        pool,
        cetus_partner,
        in_coins,
        clock,
        ctx,
    );

    let receiver = decode_receiver(data);

    // transfer the coins to the provided address
    transfer::public_transfer(coins_out, receiver)
}

fun decode_receiver(data: vector<u8>): address {
    from_bytes(data)
}
