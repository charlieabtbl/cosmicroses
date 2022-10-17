// SPDX-License-Identifier: MIT

// This library corresponds to the digital asset of a work. 
// It follows the ERC-721 standard, and each token_id corresponds 
// to a record (a version) of the work. 
// A work can have several contributors: WORK_work_contributors. 
// A work and a record can have several contributors.

%lang starknet

//  * ======================= *
//  * ======= IMPORTS ======= *
//  * ======================= *

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_equal

from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.access.accesscontrol.library import AccessControl
from openzeppelin.utils.constants.library import DEFAULT_ADMIN_ROLE

from cosmicroses.utils.counter.library import Counter
from cosmicroses.utils.constants.library import IWORK_ID

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
//  * ======= STORAGE ======= *
//  * ======================= *

@storage_var
func WORK_work_contributors(i: felt) -> (contributor: Contributor) {
}

@storage_var
func WORK_work_contributors_len() -> (len: felt) {
}

@storage_var
func WORK_record_contributors(token_id: Uint256, i: felt) -> (contributor: Contributor) {
}

@storage_var
func WORK_record_contributors_len(token_id: Uint256) -> (len: felt) {
}

@storage_var
func WORK_token_id_counter() -> (count: Uint256) {
}

namespace WORK {

    //  * ======================= *
    //  * ===== CONSTRUCTOR ===== *
    //  * ======================= *

    func initializer{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(name: felt, symbol: felt, admin: felt){
        
        AccessControl._grant_role(DEFAULT_ADMIN_ROLE, admin);
        AccessControl._grant_role(RECORDING_LICENSEE, admin);
        ERC721.initializer(name, symbol);
        ERC165.register_interface(IWORK_ID);
        WORK_token_id_counter.write(Uint256(0,0));
        return ();
    }

    //  * ======================= *
    //  * ======= GETTERS ======= *
    //  * ======================= *


    func get_number_of_work_contributors{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }() -> (number: felt){
        let (number) = WORK_work_contributors_len.read();
        return(number,);
    }

    func get_number_of_record_contributors{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(token_id: Uint256) -> (len: felt){
        let (len) = WORK_record_contributors_len.read(token_id);
        return(len,);
    }

    func get_work_contributor_by_index{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(index: felt) -> (contributor: Contributor){
        let (contributor) = WORK_work_contributors.read(index);
        return(contributor,);
    }  

    func get_record_contributor_by_index{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(index: felt, token_id: Uint256) -> (contributor: Contributor){
        let (contributor) = WORK_record_contributors.read(token_id, index);
        return(contributor,);
    }        
      
    func get_work_contributor_by_address{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(address: felt) -> (contributor: Contributor) {

        alloc_locals;
        let (contributors_len) = WORK_work_contributors_len.read();
        let (index) = _find_index_of_work_contributor(address, contributors_len);

        with_attr error_message("WORK: Contributor not found"){
            assert_not_equal(index, -1);
        }

        let (contributor) = WORK_work_contributors.read(index);

        return(contributor,);
    }
    
    func get_record_contributor_by_address{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(token_id: Uint256, address: felt) -> (contributor: Contributor) {

        alloc_locals;
        let (contributors_len) = WORK_record_contributors_len.read(token_id);
        let (index) = _find_index_of_record_contributor(token_id, address, contributors_len);

        with_attr error_message("WORK: Contributor not found"){
            assert_not_equal(index, -1);
        }

        let (contributor) = WORK_record_contributors.read(token_id, index);

        return(contributor,);
    }

    //  * ======================= *
    //  * ====== EXTERNALS ====== *
    //  * ======================= *

    func set_work_contributor{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        address: felt, share: felt
    ) {

        alloc_locals;
        AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE);

        let (contributors_len) = WORK_work_contributors_len.read();
        let (index) = _find_index_of_work_contributor(address, contributors_len);

        //If contributor does not exist
        if(index == -1) {
            WORK_work_contributors.write(
                contributors_len,
                Contributor(
                    address=address,
                    share=share,
                )
            );
            WORK_work_contributors_len.write(contributors_len + 1);
            WorkContributorAdded.emit(address, share);
            return();
        }

        WORK_work_contributors.write(
            index,
            Contributor(
                address=address,
                share=share,
            )
        );
        WorkContributorUpdated.emit(address, share);
        return();
    }

    func set_record_contributor{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        address: felt, share: felt, token_id: Uint256
    ) {

        alloc_locals;
        _assert_only_token_owner(token_id);

        let (contributors_len) = WORK_record_contributors_len.read(token_id);
        let (index) = _find_index_of_record_contributor(token_id, address, contributors_len);

        //If contributor does not exist
        if(index == -1) {
            WORK_record_contributors.write(
                token_id,
                contributors_len,
                Contributor(
                    address=address,
                    share=share,
                )
            );
            WORK_record_contributors_len.write(token_id, contributors_len + 1);
            RecContributorAdded.emit(token_id, address, share);
            return();
        }

        WORK_record_contributors.write(
            token_id,
            index,
            Contributor(
                address=address,
                share=share,
            )
        );
        RecContributorUpdated.emit(token_id, address, share);
        return();
    }

    func set_batch_work_contributors{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        contributors_len: felt, contributors: Contributor*
    ) {

        alloc_locals;
        AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE);

        if(contributors_len == 0) {
            return();
        }

        let current_index = contributors_len - 1;
        let contributor = contributors[current_index];

        set_work_contributor(
            address=contributor.address,
            share=contributor.share,
        );

        let _set_batch_work_contributors = set_batch_work_contributors(
            contributors_len=current_index,
            contributors=contributors
        );
        return _set_batch_work_contributors;
    }


    func set_batch_record_contributors{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256, contributors_len: felt, contributors: Contributor*
    ) {

        alloc_locals;
        _assert_only_token_owner(token_id);

        if(contributors_len == 0) {
            return();
        }

        let current_index = contributors_len - 1;
        let contributor = contributors[current_index];

        set_record_contributor(
            address=contributor.address,
            share=contributor.share,
            token_id=token_id
        );

        let _set_batch_record_contributors = set_batch_record_contributors(
            token_id=token_id,
            contributors_len=current_index,
            contributors=contributors
        );
        return _set_batch_record_contributors;
    }

    func create_record{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_uri: felt, contributors_len: felt, contributors: Contributor*
    ) {
        alloc_locals;
        AccessControl.assert_only_role(RECORDING_LICENSEE);

        //Increment token_id
        let (current_token_id) = WORK_token_id_counter.read();
        let (token_id_incremented) = Counter.increment(current_token_id);
        WORK_token_id_counter.write(token_id_incremented);

        //Mint and set token URI
        let (caller) = get_caller_address();
        ERC721._mint(caller, token_id_incremented);
        ERC721._set_token_uri(token_id_incremented, token_uri);

        //Set contributors
        set_batch_record_contributors(
            token_id=token_id_incremented,
            contributors_len=contributors_len,
            contributors=contributors
        );

        RecordCreated.emit(
            tokenId=token_id_incremented, 
            tokenURI=token_uri,
            minter=caller,
            contributors_len= contributors_len, 
            contributors=contributors 
        );
        return ();
    }
}

//  * ======================= *
//  * ====== INTERNALS ====== *
//  * ======================= *

func _find_index_of_record_contributor {
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(token_id: Uint256, address: felt, counter: felt) -> (res: felt) {

    if(counter == 0) {
        return(-1,);
    }

    let current_index = counter - 1;
    let (contributor) = WORK_record_contributors.read(token_id, current_index);
    if(contributor.address == address){
        return (counter-1,);
    }
    let(index_of_contributor) = _find_index_of_record_contributor(token_id, address, counter-1);
    return(index_of_contributor,);
}

func _find_index_of_work_contributor {
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(address: felt, counter: felt) -> (res: felt) {

    if(counter == 0) {
        return(-1,);
    }

    let current_index = counter - 1;
    let (contributor) = WORK_work_contributors.read(current_index);
    if(contributor.address == address){
        return (counter-1,);
    }
    let(index_of_contributor) = _find_index_of_work_contributor(address, counter-1);
    return(index_of_contributor,);
}

func _assert_only_token_owner{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(token_id: Uint256){

    alloc_locals;
    let (caller) = get_caller_address();
    let (owner_of) = ERC721.owner_of(token_id);

    with_attr error_message("WORK: caller is not the owner of the token_id"){
        assert caller = owner_of;
    }
    return ();
}

