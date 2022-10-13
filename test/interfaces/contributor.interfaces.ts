export enum ContributorType {
  WORK = "WORK",
  RECORD = "RECORD",
}

export type Contributor = {
  address: string;
  share: bigint;
};
