// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256
from cosmicroses.work.library import Contributor

@contract_interface
namespace IWORK {

    func getNumberOfWorkContributors() -> (number: felt) {
    }

    func getNumberOfRecordContributors(tokenId: Uint256) -> (number: felt) {
    }

    func getWorkContributorByIndex(index: felt) -> (contributor: Contributor) {
    }

    func getRecordContributorByIndex(index: felt, tokenId: Uint256) -> (contributor: Contributor) {
    }

    func getWorkContributorByAddress(address: felt) -> (contributor: Contributor) {
    }

    func getRecordContributorByAddress(address: felt) -> (contributor: Contributor) {
    }

    func setWorkContributor(address: felt, share: felt) {
    }

    func setRecordContributor(address: felt, share: felt, tokenId: Uint256) {
    }

    func setBatchWorkContributors(contributors_len: felt, contributors: Contributor*) {
    }

    func setBatchRecordContributors(tokenId: Uint256, contributors_len: felt, contributors: Contributor*) {
    }

    func createRecord(tokenURI: felt, contributors_len: felt, contributors: Contributor*) {
    }
}