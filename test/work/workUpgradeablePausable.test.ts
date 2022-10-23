import { expect } from "chai";
import { starknet } from "hardhat";
import {
  Account,
  StarknetContract,
  StarknetContractFactory,
} from "hardhat/types";

let proxy_admin: Account;
let default_admin: Account;
let work_contributor_1: Account;
let work_contributor_2: Account;
let work_contributor_3: Account;

let proxyFactory: StarknetContractFactory;
let proxy: StarknetContract;
let workPayeesContract: StarknetContract;

const name = starknet.shortStringToBigInt("test");
const symbol = starknet.shortStringToBigInt("TST");

describe("Test WorkUpgradeablePausable.cairo", function () {
  this.timeout(300_000);

  before(async () => {
    /* ==== DEPLOY ACCOUNTS ==== */

    proxy_admin = await starknet.deployAccount("OpenZeppelin");
    default_admin = await starknet.deployAccount("OpenZeppelin");
    work_contributor_1 = await starknet.deployAccount("OpenZeppelin");
    work_contributor_2 = await starknet.deployAccount("OpenZeppelin");
    work_contributor_3 = await starknet.deployAccount("OpenZeppelin");

    /* ==== DEPLOY PAYEES CONTRACTS ==== */
    const workContributors = [
      { address: work_contributor_1.address, shares: 150n },
      { address: work_contributor_2.address, shares: 100n },
      { address: work_contributor_3.address, shares: 50n },
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

    /* ==== DEPLOY PROXY ==== */

    const implementationFactory = await starknet.getContractFactory(
      "WorkUpgradeablePausable"
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
      payeesContract: workPayeesContract.address,
      name: name,
      symbol: symbol,
      admin: default_admin.address,
      proxyAdmin: proxy_admin.address,
    });

    console.log("Work proxy is initialized!");
  });

  describe("Test upgradeContract", () => {
    it("should upgrade contract", async () => {
      // Get and Upgrade new implementation
      const newImplementationFactory = await starknet.getContractFactory(
        "WorkUpgradeablePausableV2"
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
