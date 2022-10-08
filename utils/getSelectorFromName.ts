import { getSelectorFromName } from "starknet/dist/utils/hash";

async function main() {
  const selector = getSelectorFromName("initializer");

  console.log("Selector: ", selector);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
