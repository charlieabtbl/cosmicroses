import { expect } from "chai";
import { starknet } from "hardhat";
import { Account, StarknetContract } from "hardhat/types";
import { uint256 } from "starknet";
import { ContributorType } from "./interfaces/contributor.interfaces";
import { RECORDING_LICENSEE, setAndGetContributors } from "./utils";

let default_admin: Account;
let work_contributor_1: Account;
let work_contributor_2: Account;
let work_contributor_3: Account;
let rec_contributor_1: Account;
let rec_contributor_2: Account;
let rec_contributor_3: Account;
let rec_licensee_1: Account;
let rec_licensee_2: Account;
let contract: StarknetContract;

const name = starknet.shortStringToBigInt("test");
const symbol = starknet.shortStringToBigInt("TST");

describe("Test Work.cairo", function () {
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

    const contractFactory = await starknet.getContractFactory("Work");
    console.log("Started deployment");
    contract = await contractFactory.deploy({
      name: name,
      symbol: symbol,
      admin: default_admin.address,
    });

    console.log("Deployment transaction hash:", contract.deployTxHash);
    expect(contract.deployTxHash.startsWith("0x")).to.be.true;
    console.log("Deployed at", contract.address);
    expect(contract.address.startsWith("0x")).to.be.true;
  });

  //  * ======================= *
  //  * ======== ROLES ======== *
  //  * ======================= *

  describe("Test Roles", () => {
    const role = BigInt(RECORDING_LICENSEE);

    it("should grant RECORDING_LICENSEE role", async () => {
      await default_admin.invoke(contract, "grantRole", {
        role,
        user: rec_licensee_1.address,
      });

      const role_rec_licensee_1 = (
        await contract.call("hasRole", {
          role,
          user: rec_licensee_1.address,
        })
      ).has_role;
      const role_rec_licensee_2 = (
        await contract.call("hasRole", {
          role,
          user: rec_licensee_2.address,
        })
      ).has_role;

      expect(role_rec_licensee_1).to.deep.equal(1n);
      expect(role_rec_licensee_2).to.deep.equal(0n);
    });

    it("should revert, only default_admin can grant a role", async () => {
      try {
        await rec_licensee_2.invoke(contract, "grantRole", {
          role,
          user: rec_licensee_2.address,
        });
      } catch (err: any) {
        expect(err.message).to.contain("caller is missing role 0");
      }
    });

    it("should revoke RECORDING_LICENSEE role", async () => {
      await default_admin.invoke(contract, "grantRole", {
        role,
        user: rec_licensee_2.address,
      });

      let role_rec_licensee_2 = (
        await contract.call("hasRole", {
          role,
          user: rec_licensee_2.address,
        })
      ).has_role;
      expect(role_rec_licensee_2).to.deep.equal(1n);

      await default_admin.invoke(contract, "revokeRole", {
        role,
        user: rec_licensee_2.address,
      });

      role_rec_licensee_2 = (
        await contract.call("hasRole", {
          role,
          user: rec_licensee_2.address,
        })
      ).has_role;
      expect(role_rec_licensee_2).to.deep.equal(0n);
    });
  });

  //  * ======================= *
  //  *   WORK CONTRIBUTORS     *
  //  * ======================= *

  describe("Test Work Contributors", () => {
    it("should set single work contributor", async () => {
      await default_admin.invoke(contract, "setWorkContributor", {
        address: work_contributor_1.address,
        share: 100n,
      });

      const { contributor } = await contract.call(
        "getWorkContributorByAddress",
        {
          address: work_contributor_1.address,
        }
      );
      expect(contributor.address).to.deep.equal(
        BigInt(work_contributor_1.address)
      );
      expect(contributor.share).to.deep.equal(100n);
    });
    it("should set multiple work contributors", async () => {
      const contributors = [
        { address: work_contributor_1.address, share: 150n },
        { address: work_contributor_2.address, share: 100n },
        { address: work_contributor_3.address, share: 50n },
      ];

      const _setAndGetContributors = await setAndGetContributors(
        default_admin,
        contract,
        contributors,
        ContributorType.WORK
      );
      _setAndGetContributors.map((contributor, index) => {
        expect(contributor.address).to.deep.equal(
          BigInt(contributors[index].address)
        );
        expect(contributor.share).to.deep.equal(contributors[index].share);
      });
    });
    it("should update multiple work contributors", async () => {
      const updateContributors = [
        { address: work_contributor_1.address, share: 200n },
        { address: work_contributor_3.address, share: 1000n },
      ];
      const _setAndGetContributors = await setAndGetContributors(
        default_admin,
        contract,
        updateContributors,
        ContributorType.WORK
      );
      _setAndGetContributors.map((contributor, index) => {
        expect(contributor.address).to.deep.equal(
          BigInt(updateContributors[index].address)
        );
        expect(contributor.share).to.deep.equal(
          updateContributors[index].share
        );
      });
    });
    it("should revert if the setter is not default_admin", async () => {
      try {
        await work_contributor_1.invoke(contract, "setWorkContributor", {
          address: work_contributor_1.address,
          share: 100n,
        });
      } catch (err: any) {
        expect(err.message).to.contain("caller is missing role 0");
      }
    });
  });

  //  * ======================= *
  //  * ==== CREATE RECORD ==== *
  //  * ======================= *

  describe("Test creating records", () => {
    it("should create two records", async () => {
      const contributors = [
        { address: rec_contributor_1.address, share: 150n },
        { address: rec_contributor_2.address, share: 100n },
        { address: rec_contributor_3.address, share: 50n },
      ];

      await rec_licensee_1.invoke(contract, "createRecord", {
        tokenURI: starknet.shortStringToBigInt("test1.io"),
        contributors: contributors,
      });

      await rec_licensee_1.invoke(contract, "createRecord", {
        tokenURI: starknet.shortStringToBigInt("test2.io"),
        contributors: contributors,
      });

      const owner = (
        await contract.call("ownerOf", {
          tokenId: uint256.bnToUint256(1),
        })
      ).owner;

      const balance = (
        await contract.call("balanceOf", {
          owner: rec_licensee_1.address,
        })
      ).balance.low;

      const tokenURI_1 = (
        await contract.call("tokenURI", {
          tokenId: uint256.bnToUint256(1),
        })
      ).tokenURI;

      const tokenURI_2 = (
        await contract.call("tokenURI", {
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

      //CHECK WHETHER THE RECORD CONTRIBUTORS HAVE BEEN SET UP

      const share_contributor_1 = (
        await contract.call("getRecordContributorByAddress", {
          tokenId: uint256.bnToUint256(1),
          address: rec_contributor_1.address,
        })
      ).contributor.share;
      const share_contributor_2 = (
        await contract.call("getRecordContributorByAddress", {
          tokenId: uint256.bnToUint256(1),
          address: rec_contributor_2.address,
        })
      ).contributor.share;
      const share_contributor_3 = (
        await contract.call("getRecordContributorByAddress", {
          tokenId: uint256.bnToUint256(1),
          address: rec_contributor_3.address,
        })
      ).contributor.share;
      expect(share_contributor_1).to.deep.equal(contributors[0].share);
      expect(share_contributor_2).to.deep.equal(contributors[1].share);
      expect(share_contributor_3).to.deep.equal(contributors[2].share);
    });
  });
});
