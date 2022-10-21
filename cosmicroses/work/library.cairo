// SPDX-License-Identifier: MIT

// This library corresponds to the digital asset of a work. 
// It follows the ERC-721 standard, and each token_id corresponds 
// to a record (a version) of the work. 

%lang starknet

//  * ======================= *
//  * ======= IMPORTS ======= *
//  * ======================= *

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
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
//  * ======= EVENTS ======== *
//  * ======================= *

@event
func RecordCreated(
    createdAt: felt,
    tokenId: Uint256, 
    tokenURI: felt, 
    minter: felt, 
    payees_contract: felt, 
) {
}

//  * ======================= *
//  * ======= STORAGE ======= *
//  * ======================= *

@storage_var
func WORK_work_payees_contract() -> (payees_contract: felt) {
}

@storage_var
func WORK_record_payees_contract(token_id: Uint256) -> (payees_contract: felt) {
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
        }(
            payees_contract: felt, 
            name: felt, 
            symbol: felt, 
            admin: felt
        ){
        
        AccessControl._grant_role(DEFAULT_ADMIN_ROLE, admin);
        AccessControl._grant_role(RECORDING_LICENSEE, admin);
        ERC721.initializer(name, symbol);
        ERC165.register_interface(IWORK_ID);

        WORK_work_payees_contract.write(payees_contract);
        WORK_token_id_counter.write(Uint256(0,0));
        return ();
    }

    //  * ======================= *
    //  * ======= GETTERS ======= *
    //  * ======================= *

    func get_work_payees_contract{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }() -> (payees_contract: felt){
        let (payees_contract) = WORK_work_payees_contract.read();
        return(payees_contract,);
    }  

    func get_record_payees_contract{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(token_id: Uint256) -> (payees_contract: felt){
        let (payees_contract) = WORK_record_payees_contract.read(token_id);
        return(payees_contract,);
    }  

    //  * ======================= *
    //  * ====== EXTERNALS ====== *
    //  * ======================= *

    func create_record{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_uri: felt, payees_contract: felt
    ) {
        alloc_locals;
        AccessControl.assert_only_role(RECORDING_LICENSEE);

        //Increment token_id
        let (current_token_id) = WORK_token_id_counter.read();
        let (new_token_id) = Counter.increment(current_token_id);
        WORK_token_id_counter.write(new_token_id);

        //Mint and set token URI
        let (caller) = get_caller_address();
        ERC721._mint(caller, new_token_id);
        ERC721._set_token_uri(new_token_id, token_uri);

        //Set payees
        WORK_record_payees_contract.write(new_token_id, payees_contract);

        let(timestamp) = get_block_timestamp();

        RecordCreated.emit(
            createdAt=timestamp,
            tokenId=new_token_id, 
            tokenURI=token_uri,
            minter=caller,
            payees_contract= payees_contract
        );
        return ();
    }
}

//  * ======================= *
//  * ====== INTERNALS ====== *
//  * ======================= *

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

