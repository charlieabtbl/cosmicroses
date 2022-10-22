// SPDX-License-Identifier: MIT

%lang starknet

//  * ======================= *
//  * ======= IMPORTS ======= *
//  * ======================= *

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE

from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.access.accesscontrol.library import AccessControl

from cosmicroses.work.library import WORK

//  * ======================= *
//  * ===== CONSTRUCTOR ===== *
//  * ======================= *

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        payeesContract: felt, 
        name: felt, 
        symbol: felt,
        admin: felt
    ){
    WORK.initializer(payeesContract, name, symbol, admin);
    return ();
}

//  * ======================= *
//  * ======= GETTERS ======= *
//  * ======================= *

// WORK

func getWorkPayeesContract{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
}() -> (payeesContract: felt){
    let(payeesContract) = WORK.get_work_payees_contract();
    return (payeesContract,);
}  

func getRecordPayeesContract{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
}(tokenId: Uint256) -> (payeesContract: felt){
    let(payeesContract) = WORK.get_record_payees_contract(tokenId);
    return (payeesContract,);
}  

// ERC165

@view
func supportsInterface{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(interfaceId: felt) -> (success: felt) {
    return ERC165.supports_interface(interfaceId);
}

// ERC721

@view
func balanceOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
}(owner: felt) -> (balance: Uint256) {
    return ERC721.balance_of(owner);
}

@view
func ownerOf{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(tokenId: Uint256) -> (owner: felt) {
    return ERC721.owner_of(tokenId);
}

@view
func tokenURI{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(tokenId: Uint256) -> (tokenURI: felt) {
    let (tokenURI) = ERC721.token_uri(tokenId);
    return (tokenURI=tokenURI);
}

@view
func getApproved{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
}(tokenId: Uint256) -> (approved: felt) {
    return ERC721.get_approved(tokenId);
}

@view
func isApprovedForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
}(owner: felt, operator: felt) -> (isApproved: felt) {
    let (isApproved) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved=isApproved);
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

// WORK

@external
func createRecord{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenURI: felt, payeesContract: felt
) -> (success: felt) {
    WORK.create_record(tokenURI, payeesContract);
    return(TRUE,);
}

// ERC721

@external
func approve{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
}(to: felt, tokenId: Uint256) -> (success: felt) {
    ERC721.approve(to, tokenId);
    return(TRUE,);
}

@external
func setApprovalForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
}(operator: felt, approved: felt) -> (success: felt) {
    ERC721.set_approval_for_all(operator, approved);
    return(TRUE,);
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