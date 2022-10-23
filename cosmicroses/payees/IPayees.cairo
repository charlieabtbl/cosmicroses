// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

from cosmicroses.payees.library import Payee

@contract_interface
namespace IWORK {

    func balance() -> (balance: Uint256) {
    }
    
    func payeesCount() -> (payeesCount: felt) {
    }

    func getPayeeByIndex(index: felt) -> (payee: Payee) {
    }

    func getPayeeByAddress(address: felt) -> (payee: Payee) {
    }

    func totalShares(address: felt) -> (totalShares: felt) {
    }

    func totalReleased(token: felt) -> (totalReleased: felt) {
    }

    func released(token: felt, payeeAddress: felt) -> (released: felt) {
    }

    func pendingPayment(token: felt, payeeAddress: felt) -> (payment: Uint256) {
    }

    func setPayee(address: felt, shares: felt){
    }

    func setBatchPayees(payees_len: felt, payees: Payee*){
    }

    func release(token: felt, payee_address: felt){
    }
}