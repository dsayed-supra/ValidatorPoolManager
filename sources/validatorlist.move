module ValidatorListByDelegator::ValidatorPoolManager {

    use std::signer;
    use std::vector;
    use 0x1::pbo_delegation_pool;    

    struct ValidatorPools has key {
        owner: address,
        pools: vector<address>,
        max_pools: u64,
    }

    // Initialize the ValidatorPools resource with an empty list
    public entry fun initialize(owner: &signer,initial_max_pools: u64, new_pools: vector<address>) {
        let owner_addr = signer::address_of(owner);
        move_to(owner, ValidatorPools {
            owner: owner_addr,
            pools: new_pools,
            max_pools: initial_max_pools,
            
        });
    }

    // Add or update the validator pool addresses, only callable by the owner
    public entry fun update_pools(owner: &signer, new_pools: vector<address>) acquires ValidatorPools{
        let validator_pools = borrow_global_mut<ValidatorPools>(signer::address_of(owner));
        assert!(signer::address_of(owner) == validator_pools.owner, 403); // Unauthorized

        assert!(vector::length(&new_pools) <= validator_pools.max_pools, 401); // Exceeds max allowed
        validator_pools.pools = new_pools;
    }

    // Function to retrieve all validator pools where the delegator has staked
    #[view]
    public fun get_delegator_staked_pools(delegator: address, admin: address): (vector<address>, vector<vector<u64>>) acquires ValidatorPools {
        let validator_pools = borrow_global<ValidatorPools>(admin);
        let pools_with_stake = vector::empty<address>();
        //let staked_amount = vector::empty<u64>();
        let staked_details = vector::empty<vector<u64>>(); 
        
        // Loop over each validator pool and check if delegator has active stake
        let  i = 0;
        while (i < vector::length(&validator_pools.pools)) {
            let pool_address = *vector::borrow(&validator_pools.pools, i);

            let (active, inactive, pending_inactive) = pbo_delegation_pool::get_stake(pool_address, delegator);
            
            // If active stake is greater than 0, add to result vector
            if (active > 0 || inactive > 0 || pending_inactive > 0) {
                vector::push_back(&mut pools_with_stake, pool_address);

                let stake_info = vector::empty<u64>();
                vector::push_back(&mut stake_info, active);
                vector::push_back(&mut stake_info, inactive);
                vector::push_back(&mut stake_info, pending_inactive);

                vector::push_back(&mut staked_details, stake_info);

            };
            i = i + 1;
        };
        
        (pools_with_stake,staked_details)
    }

    // Function to get the current list of validator pools
    public fun get_validator_pools(admin: address): vector<address> acquires ValidatorPools {
        let validator_pools = borrow_global<ValidatorPools>(admin);
        validator_pools.pools
    }

    #[view]
    public fun get_max_pools(admin:address): u64 acquires ValidatorPools {
        let validator_pools = borrow_global<ValidatorPools>(admin);
        validator_pools.max_pools
    }

    // Function to update max_pools, only callable by the owner
    public entry fun set_max_pools(owner: &signer, new_max_pools: u64) acquires ValidatorPools {
        let validator_pools = borrow_global_mut<ValidatorPools>(signer::address_of(owner));
        assert!(signer::address_of(owner) == validator_pools.owner, 403); // Unauthorized

        validator_pools.max_pools = new_max_pools;
    }
}