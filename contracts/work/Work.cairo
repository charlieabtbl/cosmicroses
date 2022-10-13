// SPDX-License-Identifier: MIT

//  * ======================= *
//  * ===== DESCRIPTION ===== *
//  * ======================= *
//
//  This contract corresponds to the digital asset of a work. 
//  It follows the ERC-721 standard, and each token_id corresponds 
//  to a record (a version) of the work.
//  
//  A work can have several contributors: workContributors.
//  A record can also have several contributors: recContributors.

%lang starknet

//  * ======================= *
//  * ======= IMPORTS ======= *
//  * ======================= *

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_equal

from openzeppelin.upgrades.library import Proxy
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.access.accesscontrol.library import AccessControl
from openzeppelin.utils.constants.library import DEFAULT_ADMIN_ROLE
from openzeppelin.security.pausable.library import Pausable

from contracts.utils.counter.library import Counter

//  * ======================= *
//  * ====== CONSTANTS ====== *
//  * ======================= *

const RECORDING_LICENSEE = 0x4f96f87f6963bb246f2c30526628466840c642dc5c50d5a67777c6cc0e44ab5;

//  * ======================= *
//  * ======= STRUCTS ======= *
//  * ======================= *

struct Contributor {
    address: felt,
    share: felt,
}

//  * ======================= *
//  * ======= STORAGE ======= *
//  * ======================= *

//  CONTRIBUTORS

@storage_var
func workContributors(i: felt) -> (contributor: Contributor) {
}

@storage_var
func workContributorsLen() -> (len: felt) {
}

@storage_var
func recContributors(token_id: Uint256, i: felt) -> (contributor: Contributor) {
}

@storage_var
func recContributorsLen(token_id: Uint256) -> (len: felt) {
}

//  TOKEN

@storage_var
func _tokenIdCounter() -> (count: Uint256) {
}

//  * ======================= *
//  * ======= EVENTS ======== *
//  * ======================= *

@event
func WorkContributorAdded(
    address: felt, share: felt
) {
}

@event
func WorkContributorUpdated(
    address: felt, share: felt
) {
}

@event
func RecContributorAdded(
    tokenId: Uint256, address: felt, share: felt
) {
}

@event
func RecContributorUpdated(
    tokenId: Uint256, address: felt, share: felt
) {
}

@event
func RecordCreated(
    tokenId: Uint256, 
    tokenURI: felt, 
    minter: felt, 
    contributors_len: felt, 
    contributors: Contributor*
) {
}

//  * ======================= *
//  * ====== MODIFIERS ====== *
//  * ======================= *

func assert_only_token_owner{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(token_id: Uint256){

    alloc_locals;
    let (caller) = get_caller_address();
    let (owner_of) = ownerOf(token_id);

    with_attr error_message("Caller is not the owner of the tokenId"){
        assert caller = owner_of;
    }
    return ();
}

//  * ======================= *
//  * ===== CONSTRUCTOR ===== *
//  * ======================= *

@external
func initializer{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(name: felt, symbol: felt, admin: felt, proxy_admin: felt){
    
    Proxy.initializer(proxy_admin);
    AccessControl._grant_role(DEFAULT_ADMIN_ROLE, admin);
    AccessControl._grant_role(RECORDING_LICENSEE, admin);

    ERC721.initializer(name, symbol);
    _tokenIdCounter.write(Uint256(0,0));

    return ();
}

//  * ======================= *
//  * ======= GETTERS ======= *
//  * ======================= *

//  CONTRIBUTORS

@view
func findWorkContributorByAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) -> (contributor: Contributor) {

    alloc_locals;
    let (contributors_len) = workContributorsLen.read();
    let (index) = _findIndexOfWorkContributor(address, contributors_len);

    with_attr error_message("Contributor not found"){
        assert_not_equal(index, -1);
    }

    let (contributor) = workContributors.read(index);

    return(contributor,);
}

@view
func findRecContributorByAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256, address: felt
) -> (contributor: Contributor) {

    alloc_locals;
    let (contributors_len) = recContributorsLen.read(tokenId);
    let (index) = _findIndexOfRecContributor(tokenId, address, contributors_len);

    with_attr error_message("Contributor not found"){
        assert_not_equal(index, -1);
    }

    let (contributor) = recContributors.read(tokenId, index);

    return(contributor,);
}

//  ERC-721

@view
func supportsInterface{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(interfaceId: felt) -> (success: felt) {
    return ERC165.supports_interface(interfaceId);
}

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
}(token_id: Uint256) -> (owner: felt) {
    return ERC721.owner_of(token_id);
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
}(token_id: Uint256) -> (approved: felt) {
    return ERC721.get_approved(token_id);
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

//  PAUSABLE

@view
func paused{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
}() -> (paused: felt) {
    return Pausable.is_paused();
}

//  * ======================= *
//  * ====== EXTERNALS ====== *
//  * ======================= *

//  CONTRIBUTORS

@external
func setWorkContributor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt, share: felt
) {

    alloc_locals;
    Pausable.assert_not_paused();
    AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE);

    let (contributors_len) = workContributorsLen.read();
    let (index) = _findIndexOfWorkContributor(address, contributors_len);

    //If contributor does not exist
    if(index == -1) {
        workContributors.write(
            contributors_len,
            Contributor(
                address=address,
                share=share,
            )
        );
        workContributorsLen.write(contributors_len + 1);
        WorkContributorAdded.emit(address, share);
        return();
    }

    workContributors.write(
        index,
        Contributor(
            address=address,
            share=share,
        )
    );
    WorkContributorUpdated.emit(address, share);
    return();
}

@external
func setRecContributor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt, share: felt, tokenId: Uint256
) {

    alloc_locals;
    Pausable.assert_not_paused();
    assert_only_token_owner(tokenId);

    let (contributors_len) = recContributorsLen.read(tokenId);
    let (index) = _findIndexOfRecContributor(tokenId, address, contributors_len);

    //If contributor does not exist
    if(index == -1) {
        recContributors.write(
            tokenId,
            contributors_len,
            Contributor(
                address=address,
                share=share,
            )
        );
        recContributorsLen.write(tokenId, contributors_len + 1);
        RecContributorAdded.emit(tokenId, address, share);
        return();
    }

    recContributors.write(
        tokenId,
        index,
        Contributor(
            address=address,
            share=share,
        )
    );
    RecContributorUpdated.emit(tokenId, address, share);
    return();
}

@external
func setBatchWorkContributors{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributors_len: felt, contributors: Contributor*
) {

    alloc_locals;
    Pausable.assert_not_paused();
    AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE);

    if(contributors_len == 0) {
        return();
    }

    let current_index = contributors_len - 1;
    let contributor = contributors[current_index];

    setWorkContributor(
        address=contributor.address,
        share=contributor.share,
    );

    let _setBatchWorkContributors = setBatchWorkContributors(
        contributors_len=current_index,
        contributors=contributors
    );
    return _setBatchWorkContributors;
}

@external
func setBatchRecContributors{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256, contributors_len: felt, contributors: Contributor*
) {

    alloc_locals;
    Pausable.assert_not_paused();
    assert_only_token_owner(tokenId);

    if(contributors_len == 0) {
        return();
    }

    let current_index = contributors_len - 1;
    let contributor = contributors[current_index];

    setRecContributor(
        address=contributor.address,
        share=contributor.share,
        tokenId=tokenId
    );

    let _setBatchRecContributors = setBatchRecContributors(
        tokenId=tokenId,
        contributors_len=current_index,
        contributors=contributors
    );
    return _setBatchRecContributors;
}

//  RECORDS

@external
func createRecord{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenURI: felt, contributors_len: felt, contributors: Contributor*
) {
    alloc_locals;
    Pausable.assert_not_paused();
    AccessControl.assert_only_role(RECORDING_LICENSEE);

    //Increment tokenId
    let (currentTokenId) = _tokenIdCounter.read();
    let (tokenIdIncremented) = Counter.increment(currentTokenId);
    _tokenIdCounter.write(tokenIdIncremented);

    //Mint and set token URI
    let (caller) = get_caller_address();
    ERC721._mint(caller, tokenIdIncremented);
    ERC721._set_token_uri(tokenIdIncremented, tokenURI);

    //Set contributors
    setBatchRecContributors(
        tokenId=tokenIdIncremented,
        contributors_len=contributors_len,
        contributors=contributors
    );

    RecordCreated.emit(
        tokenId=tokenIdIncremented, 
        tokenURI=tokenURI,
        minter=caller,
        contributors_len= contributors_len, 
        contributors=contributors 
    );
    return ();
}

//  ERC-721
@external
func transferToken{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
}(to: felt, tokenId: Uint256) {

    Pausable.assert_not_paused();
    assert_only_token_owner(tokenId);
    let (caller) = get_caller_address();

    ERC721.transfer_from(caller, to, tokenId);
    return ();
}

@external
func approve{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
}(to: felt, tokenId: Uint256) {
    Pausable.assert_not_paused();
    ERC721.approve(to, tokenId);
    return ();
}

@external
func setApprovalForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
}(operator: felt, approved: felt) {
    Pausable.assert_not_paused();
    ERC721.set_approval_for_all(operator, approved);
    return ();
}

//  ACCESS_CONTROL

@external
func grantRole{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(role: felt, user: felt){
    AccessControl.grant_role(role, user);
    return ();
}

@external
func revokeRole{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(role: felt, user: felt){
    AccessControl.revoke_role(role, user);
    return ();
}

@external
func renounceRole{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(role: felt, user: felt){
    AccessControl.renounce_role(role, user);
    return ();
}

//  PAUSABLE

@external
func pause{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
}() {
    AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE);
    Pausable._pause();
    return ();
}

@external
func unpause{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
}() {
    AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE);
    Pausable._unpause();
    return ();
}

//  UPGRADE

@external
func upgradeContract{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(new_implementation: felt) -> (){
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}

//  * ======================= *
//  * ====== INTERNALS ====== *
//  * ======================= *

func _findIndexOfRecContributor {
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(tokenId: Uint256, address: felt, counter: felt) -> (res: felt) {

    if(counter == 0) {
        return(-1,);
    }

    let current_index = counter - 1;
    let (contributor) = recContributors.read(tokenId, current_index);
    if(contributor.address == address){
        return (counter-1,);
    }
    let(indexOfRecContributor) = _findIndexOfRecContributor(tokenId, address, counter-1);
    return(indexOfRecContributor,);
}

func _findIndexOfWorkContributor {
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(address: felt, counter: felt) -> (res: felt) {

    if(counter == 0) {
        return(-1,);
    }

    let current_index = counter - 1;
    let (contributor) = workContributors.read(current_index);
    if(contributor.address == address){
        return (counter-1,);
    }
    let(indexOfWorkContributor) = _findIndexOfWorkContributor(address, counter-1);
    return(indexOfWorkContributor,);
}
