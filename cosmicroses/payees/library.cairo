// SPDX-License-Identifier: Apache 2.0

//This library defines the payees and split the payment among them.

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.math import assert_not_zero, assert_lt
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_lt
from starkware.cairo.common.math import assert_not_equal

from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.access.accesscontrol.library import AccessControl
from openzeppelin.utils.constants.library import DEFAULT_ADMIN_ROLE
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.security.safemath.library import SafeUint256

from cosmicroses.utils.constants.library import IPAYEES_ID

//  * ======================= *
//  * ======= STRUCTS ======= *
//  * ======================= *

struct Payee {
    address: felt,
    shares: felt,
}

//  * ======================= *
//  * ======= EVENTS ======== *
//  * ======================= *

@event
func PaymentReleased(token: felt, to: felt, amount: Uint256) {
}

@event
func PayeeAdded(
    createdAt: felt,
    address: felt, 
    shares: felt
) {
}

@event
func PayeeUpdated(
    updatedAt: felt,
    address: felt, 
    shares: felt
) {
}

//  * ======================= *
//  * ======= STORAGE ======= *
//  * ======================= *

@storage_var
func PAYEES_payees(index: felt) -> (payee: Payee) {
}

@storage_var
func PAYEES_payees_len() -> (length: felt) {
}

@storage_var
func PAYEES_total_shares() -> (total_shares: felt) {
}

@storage_var
func PAYEES_total_released(token: felt) -> (total_released: Uint256) {
}


@storage_var
func PAYEES_released(token: felt, payee_address: felt) -> (released: Uint256) {
}

namespace PAYEES {

    //  * ======================= *
    //  * ===== CONSTRUCTOR ===== *
    //  * ======================= *

    func initializer{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        admin: felt, payees_len: felt, payees: Payee*
    ) {
        with_attr error_message("PAYEES: number of payees must be greater than zero") {
            assert_not_zero(payees_len);
        }

        AccessControl._grant_role(DEFAULT_ADMIN_ROLE, admin);
        ERC165.register_interface(IPAYEES_ID);
        _set_batch_payees(payees_len, payees);
        return ();
    }

    //  * ======================= *
    //  * ======= GETTERS ======= *
    //  * ======================= *

    func balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token: felt) -> (
        balance: Uint256
    ) {
        let (balance) = _get_balance(token);
        return (balance,);
    }

    func payee_count{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }() -> (payee_count: felt){
        let (count) = PAYEES_payees_len.read();
        return(count,);
    }

    func get_payee_by_index{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(index: felt) -> (payee: Payee){
        let (payee) = PAYEES_payees.read(index);
        return(payee,);
    }  

    func get_payee_by_address{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(address: felt) -> (payee: Payee) {
        let (payee) = _get_payee_by_address(address);
        return(payee,);
    }

    func total_shares{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        total_shares: felt
    ) {
        let (total) = PAYEES_total_shares.read();
        return (total,);
    }

    func total_released{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token: felt
    ) -> (total_released: Uint256) {
        let (total) = PAYEES_total_released.read(token);
        return (total,);
    }

    func released{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token: felt, payee_address: felt
    ) -> (released: Uint256) {
        let (released) = PAYEES_released.read(token, payee_address);
        return (released,);
    }

    func pending_payment{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token: felt, payee_address: felt
    ) -> (payment: Uint256) {
        let (payment: Uint256) = _get_pending_payment(token, payee_address);
        return (payment,);
    }

    
    //  * ======================= *
    //  * ====== EXTERNALS ====== *
    //  * ======================= *

    func set_payee{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        address: felt, shares: felt
    ) {
        AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE);
        _set_payee(address, shares);
        return();
    }

    func set_batch_payees{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        payees_len: felt, payees: Payee*
    ) {
        AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE);
        _set_batch_payees(payees_len, payees);
        return ();
    }

    func release{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token: felt, payee_address: felt
    ) {
        alloc_locals;
        let (payment) = _get_pending_payment(token, payee_address);

        with_attr error_message("PAYEES: payee is not due any payment") {
            let (gt_zero) = uint256_lt(Uint256(0, 0), payment);
            assert_not_zero(gt_zero);
        }

        // Update payee released
        let (already_released: Uint256) = PAYEES_released.read(token, payee_address);
        let (new_released: Uint256) = SafeUint256.add(payment, already_released);
        PAYEES_released.write(token, payee_address, new_released);

        // Update total released
        let (total_released: Uint256) = PAYEES_total_released.read(token);
        let (new_total_released: Uint256) = SafeUint256.add(payment, total_released);
        PAYEES_total_released.write(token, new_total_released);

        // Transfer the ERC20 tokens to payee
        IERC20.transfer(token, payee_address, payment);
        // Emit PaymentReleased event
        PaymentReleased.emit(token, payee_address, payment);
        return ();
    }

}

//  * ======================= *
//  * ====== INTERNALS ====== *
//  * ======================= *

func _find_index_of_payee {
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(address: felt, counter: felt) -> (res: felt) {

    if(counter == 0) {
        return(-1,);
    }

    let current_index = counter - 1;
    let (payee) = PAYEES_payees.read(current_index);
    if(payee.address == address){
        return (counter-1,);
    }
    let(index_of_contributor) = _find_index_of_payee(address, counter-1);
    return(index_of_contributor,);
}

func _get_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token: felt) -> (
    balance: Uint256
) {
    let (contract_address) = get_contract_address();
    with_attr error_message("PAYEES: Failed to call balanceOf on token contract") {
        let (balance) = IERC20.balanceOf(token, contract_address);
    }
    return (balance,);
}

func _get_payee_by_address{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
}(address: felt) -> (payee: Payee) {

    alloc_locals;
    let (payees_len) = PAYEES_payees_len.read();
    let (index) = _find_index_of_payee(address, payees_len);

    with_attr error_message("PAYEES: Payee not found"){
        assert_not_equal(index, -1);
    }

    let (payee) = PAYEES_payees.read(index);

    return(payee,);
}

func _get_pending_payment{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token: felt, payee_address: felt
) -> (pending_payment: Uint256) {
    alloc_locals;

    let (payees_len) = PAYEES_payees_len.read();
    let (index) = _find_index_of_payee(payee_address, payees_len);
    let (payee) = PAYEES_payees.read(index);
    local shares = payee.shares;

    with_attr error_message("PAYEES: payee has no shares") {
        assert_lt(0, shares);
    }
    let (total_shares) = PAYEES_total_shares.read();

    // total tokens received by contract = current contract balance + released tokens
    let (contract_balance) = _get_balance(token);
    let (total_released: Uint256) = PAYEES_total_released.read(token);
    let (total_received: Uint256) = SafeUint256.add(contract_balance, total_released);
    let (already_released: Uint256) = PAYEES_released.read(token, payee_address);

    // calculate pending payment
    // (total_received * (shares / total_shares)) - already_released
    let (x: Uint256) = SafeUint256.mul(total_received, Uint256(shares, 0));
    let (total_owed: Uint256, _) = SafeUint256.div_rem(x, Uint256(total_shares, 0));
    let (pending_payment) = SafeUint256.sub_le(total_owed, already_released);
    return (pending_payment,);
}

func _set_payee{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
}(
    address: felt, shares: felt
) {
    alloc_locals;

    let (payees_len) = PAYEES_payees_len.read();
    let (index) = _find_index_of_payee(address, payees_len);

    let (timestamp) = get_block_timestamp();

    //If payee does not exist
    if(index == -1) {
        PAYEES_payees.write(
            payees_len,
            Payee(
                address=address,
                shares=shares,
            )
        );
        PAYEES_payees_len.write(payees_len + 1);
        PayeeAdded.emit(
            createdAt=timestamp,
            address=address, 
            shares=shares
        );
        return();
    }

    PAYEES_payees.write(
        index,
        Payee(
            address=address,
            shares=shares,
        )
    );

    // add new shares to total shares
    let (total_shares) = PAYEES_total_shares.read();
    PAYEES_total_shares.write(total_shares + shares);

    PayeeUpdated.emit(
        updatedAt=timestamp,
        address=address, 
        shares=shares,
    );
    return();
}

func _set_batch_payees{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
}(
    payees_len: felt, payees: Payee*
) {
    alloc_locals;

    if(payees_len == 0) {
        return();
    }

    let current_index = payees_len - 1;
    let payee = payees[current_index];

    _set_payee(
        address=payee.address,
        shares=payee.shares,
    );

    let _set_batch_payees_ = _set_batch_payees(
        payees_len=current_index,
        payees=payees
    );
    return _set_batch_payees_;
}