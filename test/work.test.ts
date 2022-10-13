import { expect } from "chai";
import { starknet } from "hardhat";
import { Account, StarknetContract } from "hardhat/types";
import { uint256 } from "starknet";
import { ContributorType } from "./interfaces/contributor.interfaces";
import { RECORDING_LICENSEE, setAndFindContributors } from "./utils";

let proxy_admin: Account;
let default_admin: Account;
let work_contributor_1: Account;
let work_contributor_2: Account;
let work_contributor_3: Account;
let rec_contributor_1: Account;
let rec_contributor_2: Account;
let rec_contributor_3: Account;
let rec_licensee_1: Account;
let rec_licensee_2: Account;
let other_account: Account;
let proxy: StarknetContract;

const name = starknet.shortStringToBigInt("test");
const symbol = starknet.shortStringToBigInt("TST");

describe("Test Work.cairo", function () {
  this.timeout(300_000);

  before(async () => {
    /* ==== DEPLOY ACCOUNTS ==== */
    proxy_admin = await starknet.deployAccount("OpenZeppelin");
    default_admin = await starknet.deployAccount("OpenZeppelin");
    work_contributor_1 = await starknet.deployAccount("OpenZeppelin");
    work_contributor_2 = await starknet.deployAccount("OpenZeppelin");
    work_contributor_3 = await starknet.deployAccount("OpenZeppelin");
    rec_contributor_1 = await starknet.deployAccount("OpenZeppelin");
    rec_contributor_2 = await starknet.deployAccount("OpenZeppelin");
    rec_contributor_3 = await starknet.deployAccount("OpenZeppelin");
    rec_licensee_1 = await starknet.deployAccount("OpenZeppelin");
    rec_licensee_2 = await starknet.deployAccount("OpenZeppelin");
    other_account = await starknet.deployAccount("OpenZeppelin");

    const implementationFactory = await starknet.getContractFactory("Work");
    const implementationClassHash = await proxy_admin.declare(
      implementationFactory
    );

    // uses delegate proxy defined in contracts/upgrades/Proxy.cairo
    const proxyFactory = await starknet.getContractFactory("Proxy");
    proxy = await proxyFactory.deploy({
      implementation_hash: implementationClassHash,
    });
    console.log("Deployed proxy to", proxy.address);

    proxy.setImplementation(implementationFactory);

    await proxy_admin.invoke(proxy, "initializer", {
      name,
      symbol,
      admin: default_admin.address,
      proxy_admin: proxy_admin.address,
    });

    console.log("Work contract is initialized!");
  });

  //  * ======================= *
  //  * ======== ROLES ======== *
  //  * ======================= *

  describe("Test Roles", () => {
    const role = BigInt(RECORDING_LICENSEE);

    it("should grant RECORDING_LICENSEE role", async () => {
      await default_admin.invoke(proxy, "grantRole", {
        role,
        user: rec_licensee_1.address,
      });

      const role_rec_licensee_1 = (
        await proxy.call("hasRole", {
          role,
          user: rec_licensee_1.address,
        })
      ).has_role;
      const role_rec_licensee_2 = (
        await proxy.call("hasRole", {
          role,
          user: rec_licensee_2.address,
        })
      ).has_role;

      expect(role_rec_licensee_1).to.deep.equal(1n);
      expect(role_rec_licensee_2).to.deep.equal(0n);
    });

    it("should revert, only default_admin can grant a role", async () => {
      try {
        await rec_licensee_2.invoke(proxy, "grantRole", {
          role,
          user: rec_licensee_2.address,
        });
      } catch (err: any) {
        expect(err.message).to.contain("caller is missing role 0");
      }
    });

    it("should revoke RECORDING_LICENSEE role", async () => {
      await default_admin.invoke(proxy, "grantRole", {
        role,
        user: rec_licensee_2.address,
      });

      let role_rec_licensee_2 = (
        await proxy.call("hasRole", {
          role,
          user: rec_licensee_2.address,
        })
      ).has_role;
      expect(role_rec_licensee_2).to.deep.equal(1n);

      await default_admin.invoke(proxy, "revokeRole", {
        role,
        user: rec_licensee_2.address,
      });

      role_rec_licensee_2 = (
        await proxy.call("hasRole", {
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
      await default_admin.invoke(proxy, "setWorkContributor", {
        address: work_contributor_1.address,
        share: 100n,
      });

      const { contributor } = await proxy.call("findWorkContributorByAddress", {
        address: work_contributor_1.address,
      });
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

      const _setAndFindContributors = await setAndFindContributors(
        default_admin,
        proxy,
        contributors,
        ContributorType.WORK
      );
      _setAndFindContributors.map((contributor, index) => {
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
      const _setAndFindContributors = await setAndFindContributors(
        default_admin,
        proxy,
        updateContributors,
        ContributorType.WORK
      );
      _setAndFindContributors.map((contributor, index) => {
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
        await work_contributor_1.invoke(proxy, "setWorkContributor", {
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

      await rec_licensee_1.invoke(proxy, "createRecord", {
        tokenURI: starknet.shortStringToBigInt("test1.io"),
        contributors: contributors,
      });

      await rec_licensee_1.invoke(proxy, "createRecord", {
        tokenURI: starknet.shortStringToBigInt("test2.io"),
        contributors: contributors,
      });

      const owner = (
        await proxy.call("ownerOf", {
          token_id: uint256.bnToUint256(1),
        })
      ).owner;

      const balance = (
        await proxy.call("balanceOf", {
          owner: rec_licensee_1.address,
        })
      ).balance.low;

      const tokenURI_1 = (
        await proxy.call("tokenURI", {
          tokenId: uint256.bnToUint256(1),
        })
      ).tokenURI;

      const tokenURI_2 = (
        await proxy.call("tokenURI", {
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
        await proxy.call("findRecContributorByAddress", {
          tokenId: uint256.bnToUint256(1),
          address: rec_contributor_1.address,
        })
      ).contributor.share;
      const share_contributor_2 = (
        await proxy.call("findRecContributorByAddress", {
          tokenId: uint256.bnToUint256(1),
          address: rec_contributor_2.address,
        })
      ).contributor.share;
      const share_contributor_3 = (
        await proxy.call("findRecContributorByAddress", {
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
