import { ethers } from "hardhat";
import { NodeKey } from "../typechain";

const main = async () => {
  let receiver: string | undefined; //TBA
  if (!receiver) throw new Error(`Receiver not defined.`);

  const nodeKey = (await ethers.getContract("NodeKey")) as NodeKey;

  const tx = await (await nodeKey.mint(receiver, 1)).wait();

  console.log(`tx: ${tx.transactionHash}`);
};

main();
