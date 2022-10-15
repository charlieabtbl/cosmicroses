import { expect } from "chai";
import { starknet } from "hardhat";
import {
  Account,
  StarknetContract,
  StarknetContractFactory,
} from "hardhat/types";
import { uint256 } from "starknet";
import { ContributorType } from "./interfaces/contributor.interfaces";
import { RECORDING_LICENSEE, setAndGetContributors } from "./utils";

let proxy_admin: Account;
let default_admin: Account;
let proxyFactory: StarknetContractFactory;
let proxy: StarknetContract;

const name = starknet.shortStringToBigInt("test");
const symbol = starknet.shortStringToBigInt("TST");

describe("Test WorkUpgradeable.cairo", function () {
  this.timeout(300_000);

  before(async () => {
    proxy_admin = await starknet.deployAccount("OpenZeppelin");
    default_admin = await starknet.deployAccount("OpenZeppelin");

    const implementationFactory = await starknet.getContractFactory(
      "WorkUpgradeable"
    );
    const implementationClassHash = await proxy_admin.declare(
      implementationFactory
    );

    // uses delegate proxy defined in contracts/upgrades/Proxy.cairo
    proxyFactory = await starknet.getContractFactory("Proxy");
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

    console.log("Work proxy is initialized!");
  });

  describe("Test upgradeContract", () => {
    it("should upgrade contract", async () => {
      // Get and Upgrade new implementation
      const newImplementationFactory = await starknet.getContractFactory(
        "WorkUpgradeableV2"
      );
      const implementationClassHash = await proxy_admin.declare(
        newImplementationFactory
      );
      await proxy_admin.invoke(proxy, "upgradeContract", {
        newImplementation: implementationClassHash,
      });

      // Update ABI
      proxy.setImplementation(newImplementationFactory);
      const newAbi = proxy.getAbi();
      expect(JSON.stringify(newAbi)).contains("setVar");
      expect(JSON.stringify(newAbi)).contains("getVar");

      // Test new functions
      await default_admin.invoke(proxy, "setVar", {
        var: 2n,
      });
      const variable = (await proxy.call("getVar")).var;
      expect(variable).to.deep.equal(2n);
    });
  });
});
