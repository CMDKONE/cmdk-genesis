import keccak256 from "keccak256";
import { MerkleTree } from "merkletreejs";
import { Web3 } from "web3";
import Papa from "papaparse";
import fs from "fs";

const web3 = new Web3();

const generateProofsForWhitelist = (filename: string, content: string) => {
  const csv: { data: string[][] } = Papa.parse(content);
  csv.data.shift();

  const allocations = csv.data.map((row) => {
    const address = row[0];
    const allocationAmount = BigInt(web3.utils.toWei(row[1], "ether"));
    return { address, allocationAmount };
  });

  const leafNodes = allocations.map(({ address, allocationAmount }) => {
    return keccak256(
      Buffer.concat([
        Buffer.from(address.replace("0x", ""), "hex"),
        Buffer.from(
          web3.eth.abi
            .encodeParameter("uint256", allocationAmount.toString())
            .replace("0x", ""),
          "hex"
        ),
      ])
    );
  });
  const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });

  const addresses = allocations.reduce((acc, allocation, index) => {
    const { address, allocationAmount } = allocation;
    const lowerCaseAddress = address.toLowerCase();
    return {
      ...acc,
      [lowerCaseAddress]: {
        proofs: merkleTree.getHexProof(leafNodes[index]),
        allocation: allocationAmount.toString(),
      },
    };
  }, {});

  const json = {
    merkleRoot: merkleTree.getHexRoot(),
    addresses,
  };
  fs.writeFileSync(`${filename}.json`, JSON.stringify(json, null, 2));
  console.log("Merkle Root:", json.merkleRoot);
};

const main = () => {
  const filename = "whitelist";
  fs.readFile(`${filename}.csv`, "utf-8", function (err, content) {
    if (err) {
      throw new Error(err.message);
    }
    generateProofsForWhitelist(filename, content);
  });
};

main();
