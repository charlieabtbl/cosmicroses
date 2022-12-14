// SPDX-License-Identifier: Apache 2.0

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE

from openzeppelin.access.accesscontrol.library import AccessControl

from cosmicroses.payees.library import PAYEES, Payee

//  * ======================= *
//  * ===== CONSTRUCTOR ===== *
//  * ======================= *

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        admin: felt, 
        payees_len: felt, 
        payees: Payee*
    ){
    PAYEES.initializer(admin, payees_len, payees);
    return ();
}

//  * ======================= *
//  * ======= GETTERS ======= *
//  * ======================= *

// PAYEES

@view
func balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token: felt) -> (
    balance: Uint256
) {
    let (balance) = PAYEES.balance(token);
    return (balance,);
}

@view
func payeesCount{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
}() -> (payeesCount: felt){
    let (count) = PAYEES.payees_count();
    return(count,);
}

@view
func getPayeeByIndex{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
}(index: felt) -> (payee: Payee){
    let (payee) = PAYEES.get_payee_by_index(index);
    return(payee,);
}  

@view
func getPayeeByAddress{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
}(address: felt) -> (payee: Payee) {
    let (payee) = PAYEES.get_payee_by_address(address);
    return(payee,);
}

@view
func totalShares{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    totalShares: felt
) {
    let (total) = PAYEES.total_shares();
    return (total,);
}

@view
func totalReleased{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token: felt
) -> (totalReleased: Uint256) {
    let (total) = PAYEES.total_released(token);
    return (total,);
}

@view
func released{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token: felt, payeeAddress: felt
) -> (released: Uint256) {
    let (released) = PAYEES.released(token, payeeAddress);
    return (released,);
}

@view
func pendingPayment{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token: felt, payeeAddress: felt
) -> (payment: Uint256) {
    let (payment: Uint256) = PAYEES.pending_payment(token, payeeAddress);
    return (payment,);
}

//  ACCESS_CONTROL

@view
func hasRole{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(role: felt, user: felt) -> (has_role: felt){
    let (has_role) = AccessControl.has_role(role, user);
    return (has_role,);
}

@view
func getRoleAdmin{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(role: felt) -> (admin: felt){
    let (admin) = AccessControl.get_role_admin(role);
    return (admin,);
}

//  * ======================= *
//  * ====== EXTERNALS ====== *
//  * ======================= *

// PAYEES

@external
func setPayee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt, shares: felt
) -> (success: felt) {
    PAYEES.set_payee(address, shares);
    return(TRUE,);
}

@external
func setBatchPayees{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    payees_len: felt, payees: Payee*
) -> (success: felt) {
    PAYEES.set_batch_payees(payees_len, payees);
    return(TRUE,);
}

@external
func release{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token: felt, payeeAddress: felt
) -> (success: felt) {
    PAYEES.release(token, payeeAddress);
    return (TRUE,);
}

//  ACCESS_CONTROL

@external
func grantRole{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(role: felt, user: felt) -> (success: felt) {
    AccessControl.grant_role(role, user);
    return(TRUE,);
}

@external
func revokeRole{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(role: felt, user: felt) -> (success: felt) {
    AccessControl.revoke_role(role, user);
    return(TRUE,);
}

@external
func renounceRole{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(role: felt, user: felt) -> (success: felt) {
    AccessControl.renounce_role(role, user);
    return(TRUE,);
}

