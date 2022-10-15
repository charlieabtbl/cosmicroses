import { Account, StarknetContract } from "hardhat/types";
import {
  Contributor,
  ContributorType,
} from "./interfaces/contributor.interfaces";

export const RECORDING_LICENSEE =
  "0x4f96f87f6963bb246f2c30526628466840c642dc5c50d5a67777c6cc0e44ab5";

export async function setAndGetContributors(
  caller: Account,
  contract: StarknetContract,
  contributors: Contributor[],
  contributorType: ContributorType
): Promise<Contributor[]> {
  let getContributors: Contributor[] = [];

  if (contributors.length > 0) {
    // SET CONTRIBUTORS
    await caller.invoke(
      contract,
      contributorType == ContributorType.WORK
        ? "setBatchWorkContributors"
        : "setBatchRecordContributors",
      {
        contributors: contributors,
      }
    );

    // GET CONTRIBUTORS

    for (let i = 0; i < contributors.length; i++) {
      const contributor_: Contributor = (
        await contract.call(
          contributorType == ContributorType.WORK
            ? "getWorkContributorByAddress"
            : "getRecordContributorByAddress",
          {
            address: contributors[i].address,
          }
        )
      ).contributor;

      getContributors.push(contributor_);
    }
  }
  return getContributors;
}
