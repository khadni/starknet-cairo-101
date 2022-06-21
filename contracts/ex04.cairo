# ######## Ex 04
# Reading a mapping
# In this exercise, you need to:
# - Use a function to read a variable
# - Use a function to read a value in a mapping, where the slot you read is the value from the first call
# - Use a function to show you know the correct value of the value in the mapping
# - Your points are credited by the contract

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero
from contracts.utils.ex00_base import (
    tderc20_address,
    has_validated_exercise,
    distribute_points,
    validate_exercise,
    ex_initializer,
)

#
# Declaring storage vars
# Storage vars are by default not visible through the ABI. They are similar to "private" variables in Solidity
#

@storage_var
func user_slots_storage(account : felt) -> (user_slots_storage : felt):
end

@storage_var
func values_mapped_storage(slot : felt) -> (values_mapped_storage : felt):
end

@storage_var
func was_initialized() -> (was_initialized : felt):
end

@storage_var
func next_slot() -> (next_slot : felt):
end

#
# Declaring getters
# Public variables should be declared explicitly with a getter
#

@view
func user_slots{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    account : felt
) -> (user_slot : felt):
    let (user_slot) = user_slots_storage.read(account)
    return (user_slot)
end

@view
func values_mapped{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    slot : felt
) -> (value : felt):
    let (value) = values_mapped_storage.read(slot)
    return (value)
end

#
# Constructor
#
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _tderc20_address : felt, _players_registry : felt, _workshop_id : felt, _exercise_id : felt
):
    ex_initializer(_tderc20_address, _players_registry, _workshop_id, _exercise_id)
    return ()
end

#
# External functions
#

@external
func claim_points{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    expected_value : felt
):
    # Reading caller address
    let (sender_address) = get_caller_address()
    with_attr error_message("User slot not assigned. Call assign_user_slot"):
        # Checking that the user got a slot assigned
        let (user_slot) = user_slots_storage.read(sender_address)
        assert_not_zero(user_slot)
    end
    # Checking that the value provided by the user is the one we expect
    # Yes, I'm sneaky
    let (value) = values_mapped_storage.read(user_slot)
    with_attr error_message("Input value is not the expected secret value"):
        assert value = expected_value + 32
    end
    # Checking if the user has validated the exercice before
    validate_exercise(sender_address)
    # Sending points to the address specified as parameter
    distribute_points(sender_address, 2)
    return ()
end

@external
func assign_user_slot{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    # Reading caller address
    let (sender_address) = get_caller_address()
    let (next_slot_temp) = next_slot.read()
    let (next_value) = values_mapped_storage.read(next_slot_temp + 1)
    if next_value == 0:
        user_slots_storage.write(sender_address, 1)
        next_slot.write(0)
    else:
        user_slots_storage.write(sender_address, next_slot_temp + 1)
        next_slot.write(next_slot_temp + 1)
    end
    return ()
end

#
# External functions - Administration
# Only admins can call these. You don't need to understand them to finish the exercice.
#

@external
func set_random_values{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    values_len : felt, values : felt*
):
    # Check if the random values were already initialized
    let (was_initialized_read) = was_initialized.read()
    with_attr error_message("random values already initialized"):
        assert was_initialized_read = 0
    end

    # Storing passed values in the store
    set_a_random_value(values_len, values)

    # Mark that value store was initialized
    was_initialized.write(1)
    return ()
end

func set_a_random_value{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    values_len : felt, values : felt*
):
    if values_len == 0:
        # Start with sum=0.
        return ()
    end

    set_a_random_value(values_len=values_len - 1, values=values + 1)
    values_mapped_storage.write(values_len - 1, [values])

    return ()
end
