import { toPackedUserOperation } from "./packUserOperation";
import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import dotenv from "dotenv";
dotenv.config();

async function main() {
  const argv = await yargs(hideBin(process.argv))
    .option("operation", {
      alias: "o",
      description: "The unpacked user operation as a JSON string",
      type: "string",
    })
    .parse();

  if (argv.operation) {
    try {
      const unpackedUserOperation = JSON.parse(argv.operation);

      const packedOperation = toPackedUserOperation(unpackedUserOperation);

      console.log(JSON.stringify(packedOperation));
    } catch (error) {
      console.error("Failed to parse unpacked user operation:", error);
    }
  } else {
    console.error(
      "No operation provided. Please pass an operation using the --operation flag."
    );
  }
}

main();
