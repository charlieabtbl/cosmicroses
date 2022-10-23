import { Account, StarknetContract } from "hardhat/types";
import { PayeeInterface } from "./interface";

export const RECORDING_LICENSEE =
  "0x4f96f87f6963bb246f2c30526628466840c642dc5c50d5a67777c6cc0e44ab5";

export async function setAndGetPayees(
  caller: Account,
  contract: StarknetContract,
  payees: PayeeInterface[]
): Promise<PayeeInterface[]> {
  let getPayees: PayeeInterface[] = [];

  if (payees.length > 0) {
    // SET PAYEES
    await caller.invoke(contract, "setBatchPayees", {
      payees: payees,
    });

    // GET PAYEES

    for (let i = 0; i < payees.length; i++) {
      const _payee: PayeeInterface = (
        await contract.call("getPayeeByAddress", {
          address: payees[i].address,
        })
      ).payee;

      getPayees.push(_payee);
    }
  }
  return getPayees;
}
