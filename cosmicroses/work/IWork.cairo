// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IWORK {

    func getWorkPayeesContract() -> (payeesContract: felt) {
    }

    func getRecordPayeesContract(tokenId: Uint256) -> (payees_contract: felt) {
    }

    func createRecord(tokenURI: felt, payeesContract: felt) {
    }
}