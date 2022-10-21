// SPDX-License-Identifier: MIT

//  * ======================= *
//  * ===== DESCRIPTION ===== *
//  * ======================= *
//
//  This contract deploys a proxy of the Work.cairo contract. 
//  

%lang starknet

//  * ======================= *
//  * ======= IMPORTS ======= *
//  * ======================= *

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import deploy, get_caller_address, call_contract


from openzeppelin.upgrades.library import Proxy

//  * ======================= *
//  * ====== CONSTANTS ====== *
//  * ======================= *

const INITIALIZE_SELECTOR = 0x2dd76e7ad84dbed81c314ffe5e7a7cacfb8f4836f01af4e913f275f89a3de1a;

//  * ======================= *
//  * ======= STORAGE ======= *
//  * ======================= *

@storage_var
func salt() -> (value: felt) {
}

@storage_var
func work_class_hash() -> (value: felt) {
}

@storage_var
func work_proxy_class_hash() -> (value: felt) {
}

//  * ======================= *
//  * ======= EVENTS ======== *
//  * ======================= *

@event
func WorkContractDeployed(
    name: felt, 
    caller: felt, 
    contract_address: felt,
    payees_contract: felt    
) {
}

//  * ======================= *
//  * ===== CONSTRUCTOR ===== *
//  * ======================= *

@external
func initializer{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
}(work_proxy_class_hash_: felt, work_class_hash_: felt, proxy_admin: felt) {
    work_proxy_class_hash.write(value=work_proxy_class_hash_);
    work_class_hash.write(value=work_class_hash_);
    Proxy.initializer(proxy_admin);
    return ();
}

//  * ======================= *
//  * ====== EXTERNALS ====== *
//  * ======================= *

//  DEPLOY WORK CONTRACT

@external
func deploy_work_proxy_contract{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
} (
    payeesContract: felt, name: felt, symbol: felt,
) ->(contract_address: felt) {

    let (current_salt) = salt.read();
    let (proxy_class_hash) = work_proxy_class_hash.read();
    let (class_hash) = work_class_hash.read();
    let (caller_address) = get_caller_address();
    let (proxy_admin) = Proxy.get_admin();
    let (deploy_calldata: felt*) = alloc();
    assert deploy_calldata[0] = class_hash;
    let (contract_address) = deploy(
        class_hash=proxy_class_hash,
        contract_address_salt=current_salt,
        constructor_calldata_size=1,
        constructor_calldata=deploy_calldata,
        deploy_from_zero=FALSE,
    );

    salt.write(value=current_salt + 1);

    let (initialize_calldata: felt*) = alloc();
    assert initialize_calldata[0] = payeesContract;
    assert initialize_calldata[1] = name;
    assert initialize_calldata[2] = symbol;
    assert initialize_calldata[3] = caller_address; //contract admin
    assert initialize_calldata[4] = proxy_admin;    //proxy admin

    let res = call_contract(
        contract_address=contract_address,
        function_selector=INITIALIZE_SELECTOR,
        calldata_size=4,
        calldata=initialize_calldata,
    );

    WorkContractDeployed.emit(
        name=name, 
        caller=caller_address, 
        contract_address=contract_address,
        payees_contract=payeesContract
    );

    return(contract_address,);
}

//  UPGRADE

@external
func upgrade{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
}(new_implementation: felt) -> () {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}