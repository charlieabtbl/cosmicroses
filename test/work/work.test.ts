import { expect } from "chai";
import { starknet } from "hardhat";
import { Account, StarknetContract } from "hardhat/types";
import { uint256 } from "starknet";
import { IERC721_ID, IWORK_ID, RECORDING_LICENSEE } from "../utils";

let default_admin: Account;
let work_contributor_1: Account;
let work_contributor_2: Account;
let work_contributor_3: Account;
let rec_contributor_1: Account;
let rec_contributor_2: Account;
let rec_contributor_3: Account;
let rec_licensee_1: Account;
let rec_licensee_2: Account;

let workContract: StarknetContract;
let workPayeesContract: StarknetContract;
let recordPayeesContract: StarknetContract;

const name = starknet.shortStringToBigInt("work");
const symbol = starknet.shortStringToBigInt("WRK");

describe("TEST WORK.CAIRO", function () {
  this.timeout(300_000);

  before(async () => {
    /* ==== DEPLOY ACCOUNTS ==== */

    default_admin = await starknet.deployAccount("OpenZeppelin");
    work_contributor_1 = await starknet.deployAccount("OpenZeppelin");
    work_contributor_2 = await starknet.deployAccount("OpenZeppelin");
    work_contributor_3 = await starknet.deployAccount("OpenZeppelin");
    rec_contributor_1 = await starknet.deployAccount("OpenZeppelin");
    rec_contributor_2 = await starknet.deployAccount("OpenZeppelin");
    rec_contributor_3 = await starknet.deployAccount("OpenZeppelin");
    rec_licensee_1 = await starknet.deployAccount("OpenZeppelin");
    rec_licensee_2 = await starknet.deployAccount("OpenZeppelin");

    /* ==== DEPLOY PAYEES CONTRACTS ==== */
    const workContributors = [
      { address: work_contributor_1.address, shares: 150n },
      { address: work_contributor_2.address, shares: 100n },
      { address: work_contributor_3.address, shares: 50n },
    ];

    const recContributors = [
      { address: rec_contributor_1.address, shares: 150n },
      { address: rec_contributor_2.address, shares: 100n },
      { address: rec_contributor_3.address, shares: 50n },
    ];

    const payeesContractFactory = await starknet.getContractFactory("Payees");

    // WORK CONTRIBUTORS:
    workPayeesContract = await payeesContractFactory.deploy({
      admin: default_admin.address,
      payees: workContributors,
    });

    expect(workPayeesContract.deployTxHash.startsWith("0x")).to.be.true;
    console.log("WORK CONTRIBUTORS: Deployed at", workPayeesContract.address);
    expect(workPayeesContract.address.startsWith("0x")).to.be.true;

    // RECORD CONTRIBUTORS:
    recordPayeesContract = await payeesContractFactory.deploy({
      admin: default_admin.address,
      payees: recContributors,
    });

    expect(recordPayeesContract.deployTxHash.startsWith("0x")).to.be.true;
    console.log(
      "RECORD CONTRIBUTORS: Deployed at",
      recordPayeesContract.address
    );
    expect(recordPayeesContract.address.startsWith("0x")).to.be.true;

    /* ==== DEPLOY WORK CONTRACT ==== */

    const workContractFactory = await starknet.getContractFactory("Work");
    workContract = await workContractFactory.deploy({
      payeesContract: workPayeesContract.address,
      name: name,
      symbol: symbol,
      admin: default_admin.address,
    });

    expect(workContract.deployTxHash.startsWith("0x")).to.be.true;
    console.log("WORK CONTRACT: Deployed at", workContract.address);
    expect(workContract.address.startsWith("0x")).to.be.true;
  });

  describe("TEST ROLES", () => {
    const role = BigInt(RECORDING_LICENSEE);

    it("should grant RECORDING_LICENSEE role", async () => {
      await default_admin.invoke(workContract, "grantRole", {
        role,
        user: rec_licensee_1.address,
      });

      const role_rec_licensee_1 = (
        await workContract.call("hasRole", {
          role,
          user: rec_licensee_1.address,
        })
      ).has_role;
      const role_rec_licensee_2 = (
        await workContract.call("hasRole", {
          role,
          user: rec_licensee_2.address,
        })
      ).has_role;

      expect(role_rec_licensee_1).to.deep.equal(1n);
      expect(role_rec_licensee_2).to.deep.equal(0n);
    });

    it("should revert, only default_admin can grant a role", async () => {
      try {
        await rec_licensee_2.invoke(workContract, "grantRole", {
          role,
          user: rec_licensee_2.address,
        });
      } catch (err: any) {
        expect(err.message).to.contain("caller is missing role 0");
      }
    });

    it("should revoke RECORDING_LICENSEE role", async () => {
      await default_admin.invoke(workContract, "grantRole", {
        role,
        user: rec_licensee_2.address,
      });

      let role_rec_licensee_2 = (
        await workContract.call("hasRole", {
          role,
          user: rec_licensee_2.address,
        })
      ).has_role;
      expect(role_rec_licensee_2).to.deep.equal(1n);

      await default_admin.invoke(workContract, "revokeRole", {
        role,
        user: rec_licensee_2.address,
      });

      role_rec_licensee_2 = (
        await workContract.call("hasRole", {
          role,
          user: rec_licensee_2.address,
        })
      ).has_role;
      expect(role_rec_licensee_2).to.deep.equal(0n);
    });
  });

  describe("TEST CREATE RECORDS", () => {
    it("should create two records", async () => {
      await rec_licensee_1.invoke(workContract, "createRecord", {
        tokenURI: starknet.shortStringToBigInt("test1.io"),
        payeesContract: recordPayeesContract.address,
      });

      await rec_licensee_1.invoke(workContract, "createRecord", {
        tokenURI: starknet.shortStringToBigInt("test2.io"),
        payeesContract: recordPayeesContract.address,
      });

      const owner = (
        await workContract.call("ownerOf", {
          tokenId: uint256.bnToUint256(1),
        })
      ).owner;

      const balance = (
        await workContract.call("balanceOf", {
          owner: rec_licensee_1.address,
        })
      ).balance.low;

      const tokenURI_1 = (
        await workContract.call("tokenURI", {
          tokenId: uint256.bnToUint256(1),
        })
      ).tokenURI;

      const tokenURI_2 = (
        await workContract.call("tokenURI", {
          tokenId: uint256.bnToUint256(2),
        })
      ).tokenURI;

      expect(balance).to.deep.equal(2n);
      expect(owner).to.deep.equal(BigInt(rec_licensee_1.address));
      expect(tokenURI_1).to.deep.equal(
        starknet.shortStringToBigInt("test1.io")
      );
      expect(tokenURI_2).to.deep.equal(
        starknet.shortStringToBigInt("test2.io")
      );

      //CHECK WHETHER THE RECORD PAYEES HAVE BEEN SET UP

      const getRecordPayeesContract = (
        await workContract.call("getRecordPayeesContract", {
          tokenId: uint256.bnToUint256(1),
        })
      ).payeesContract;

      expect(getRecordPayeesContract).to.deep.equal(
        BigInt(recordPayeesContract.address)
      );
    });
  });

  describe("TEST PAYEES", () => {
    it("should return return work payees contract", async () => {
      const _workPayeesContract = (
        await workContract.call("getWorkPayeesContract")
      ).payeesContract;

      expect(_workPayeesContract).to.deep.equal(
        BigInt(workPayeesContract.address)
      );
    });

    it("should return record payees contract", async () => {
      const _recordPayeesContract = (
        await workContract.call("getRecordPayeesContract", {
          tokenId: uint256.bnToUint256(1),
        })
      ).payeesContract;

      expect(_recordPayeesContract).to.deep.equal(
        BigInt(recordPayeesContract.address)
      );
    });
  });

  describe("TEST SUPPORT INTERFACES", () => {
    it("should return TRUE if interface is supported", async () => {
      const supportsWorkInterface = (
        await workContract.call("supportsInterface", {
          interfaceId: IWORK_ID,
        })
      ).success;

      const supportsERC721Interface = (
        await workContract.call("supportsInterface", {
          interfaceId: IERC721_ID,
        })
      ).success;

      expect(supportsWorkInterface).to.be.equal(1n);
      expect(supportsERC721Interface).to.be.equal(1n);
    });

    it("should return FALSE if interface is not supported", async () => {
      const supportsRandomInterface = (
        await workContract.call("supportsInterface", {
          interfaceId: 0x894c58cd,
        })
      ).success;

      expect(supportsRandomInterface).to.be.equal(0n);
    });
  });
});
