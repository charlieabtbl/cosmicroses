import { expect } from "chai";
import { starknet } from "hardhat";
import { Account, StarknetContract } from "hardhat/types";
import { uint256 } from "starknet";
import { setAndGetPayees } from "../utils";

let payee_1: Account;
let payee_2: Account;
let payee_3: Account;
let payeesContract: StarknetContract;
let token: StarknetContract;

const initial_supply = 10000;
const shares_payee_1 = 150n;
const shares_payee_2 = 100n;
const shares_payee_3 = 50n;

const total_shares = shares_payee_1 + shares_payee_2 + shares_payee_3;
const release_amount_payee_1 =
  (Number(shares_payee_1) / Number(total_shares)) * initial_supply;

const release_amount_payee_2 =
  (Number(shares_payee_2) / Number(total_shares)) * initial_supply;

describe("TEST PAYEE.CAIRO", function () {
  this.timeout(300_000);

  before(async () => {
    /* ==== DEPLOY ACCOUNTS ==== */
    payee_1 = await starknet.deployAccount("OpenZeppelin");
    payee_2 = await starknet.deployAccount("OpenZeppelin");
    payee_3 = await starknet.deployAccount("OpenZeppelin");

    const payees = [{ address: payee_1.address, shares: 100n }];

    /* ==== DEPLOY PAYEES CONTRACT ==== */

    const payeesContractFactory = await starknet.getContractFactory("Payees");

    payeesContract = await payeesContractFactory.deploy({
      admin: payee_1.address,
      payees: payees,
    });

    expect(payeesContract.deployTxHash.startsWith("0x")).to.be.true;
    console.log("PAYEES: Deployed at", payeesContract.address);
    expect(payeesContract.address.startsWith("0x")).to.be.true;

    /* ==== DEPLOY TOKEN ==== */

    const name = starknet.shortStringToBigInt("token");
    const symbol = starknet.shortStringToBigInt("TKN");
    const ERC20ContractFactory = await starknet.getContractFactory("ERC20");

    token = await ERC20ContractFactory.deploy({
      name: name,
      symbol: symbol,
      decimals: 18,
      initial_supply: uint256.bnToUint256(initial_supply),
      recipient: payeesContract.address,
    });

    expect(token.deployTxHash.startsWith("0x")).to.be.true;
    console.log("TOKEN: Deployed at", payeesContract.address);
    expect(token.address.startsWith("0x")).to.be.true;
  });

  describe("TEST EXTERNALS", () => {
    describe("Test set payees", () => {
      it("should add a single payee", async () => {
        await payee_1.invoke(payeesContract, "setPayee", {
          address: payee_2.address,
          shares: 100n,
        });

        const { payee } = await payeesContract.call("getPayeeByAddress", {
          address: payee_2.address,
        });
        expect(payee.address).to.deep.equal(BigInt(payee_2.address));
        expect(payee.shares).to.deep.equal(100n);
      });

      it("should set batch of payees", async () => {
        const payees = [
          { address: payee_1.address, shares: shares_payee_1 },
          { address: payee_2.address, shares: shares_payee_2 },
          { address: payee_3.address, shares: shares_payee_3 },
        ];

        const _setAndGetPayees = await setAndGetPayees(
          payee_1,
          payeesContract,
          payees
        );
        _setAndGetPayees.map((payee, index) => {
          expect(payee.address).to.deep.equal(BigInt(payees[index].address));
          expect(payee.shares).to.deep.equal(payees[index].shares);
        });
      });

      it("should revert if the setter is not default admin", async () => {
        try {
          await payee_2.invoke(payeesContract, "setPayee", {
            address: payee_2.address,
            shares: 200n,
          });
        } catch (err: any) {
          expect(err.message).to.contain("caller is missing role 0");
        }
      });
    });

    describe("Test release function", () => {
      it("should release tokens of payee_1", async () => {
        await payee_1.invoke(payeesContract, "release", {
          token: token.address,
          payeeAddress: payee_1.address,
        });

        const balanceOfPayee1 = (
          await token.call("balanceOf", {
            account: payee_1.address,
          })
        ).balance;

        const expectedBalance = release_amount_payee_1;

        expect(balanceOfPayee1.low).to.deep.equal(BigInt(expectedBalance));
      });

      it("should be reverted if the payee has no payment pending", async () => {
        try {
          await payee_1.invoke(payeesContract, "release", {
            token: token.address,
            payeeAddress: payee_1.address,
          });
        } catch (err: any) {
          expect(err.message).to.contain(
            "PAYEES: payee is not due any payment"
          );
        }
      });
    });
  });

  describe("TEST GETTERS", () => {
    it("should return balance", async () => {
      const balance = (
        await payeesContract.call("balance", {
          token: token.address,
        })
      ).balance;

      const expectedBalance = initial_supply - release_amount_payee_1;

      expect(Number(uint256.uint256ToBN(balance))).to.deep.equal(
        expectedBalance
      );
    });

    it("should return numbers of payees", async () => {
      const payeesCount = (await payeesContract.call("payeesCount"))
        .payeesCount;

      expect(Number(payeesCount)).to.deep.equal(3);
    });

    it("should return payee by index", async () => {
      const payee = (
        await payeesContract.call("getPayeeByIndex", {
          index: 0,
        })
      ).payee;

      expect(payee.address).to.deep.equal(BigInt(payee_1.address));
      expect(payee.shares).to.deep.equal(shares_payee_1);
    });

    it("should return payee by address", async () => {
      const payee = (
        await payeesContract.call("getPayeeByAddress", {
          address: payee_1.address,
        })
      ).payee;

      expect(payee.address).to.deep.equal(BigInt(payee_1.address));
      expect(payee.shares).to.deep.equal(shares_payee_1);
    });

    it("should return total shares", async () => {
      const totalShares = (await payeesContract.call("totalShares"))
        .totalShares;

      expect(totalShares).to.deep.equal(total_shares);
    });

    it("should return total released", async () => {
      const totalReleased = (
        await payeesContract.call("totalReleased", {
          token: token.address,
        })
      ).totalReleased;

      expect(Number(uint256.uint256ToBN(totalReleased))).to.deep.equal(
        release_amount_payee_1
      );
    });

    it("should return released of payee_1 and payee_2", async () => {
      const releasedPayee1 = (
        await payeesContract.call("released", {
          token: token.address,
          payeeAddress: payee_1.address,
        })
      ).released;

      expect(Number(uint256.uint256ToBN(releasedPayee1))).to.deep.equal(
        release_amount_payee_1
      );

      const releasedPayee2 = (
        await payeesContract.call("released", {
          token: token.address,
          payeeAddress: payee_2.address,
        })
      ).released;

      expect(Number(uint256.uint256ToBN(releasedPayee2))).to.deep.equal(0);
    });

    it("should return pending payment of payee_1 and payee_2", async () => {
      const pendingPaymentPayee1 = (
        await payeesContract.call("pendingPayment", {
          token: token.address,
          payeeAddress: payee_1.address,
        })
      ).payment;

      expect(Number(uint256.uint256ToBN(pendingPaymentPayee1))).to.deep.equal(
        0
      );

      const pendingPaymentPayee2 = (
        await payeesContract.call("pendingPayment", {
          token: token.address,
          payeeAddress: payee_2.address,
        })
      ).payment;

      expect(Number(uint256.uint256ToBN(pendingPaymentPayee2))).to.deep.equal(
        Math.round(release_amount_payee_2)
      );
    });
  });
});
