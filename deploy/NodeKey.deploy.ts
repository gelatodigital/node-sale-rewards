import { keccak256, toUtf8Bytes } from "ethers/lib/utils";
import hre, { ethers } from "hardhat";
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { isFirstDeploy, isTesting } from "../src/utils";
import { EIP173Proxy, NodeKey } from "../typechain";

const isHardhat = isTesting(hre.network.name);

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;
  const { deploy } = deployments;

  const [deployer] = await hre.ethers.getSigners();

  const isFirst = await isFirstDeploy(hre, "NodeKey");

  console.log("DEPLOYING NODE KEY");
  await deploy("NodeKey", {
    from: deployer.address,
    args: [],
    log: true,
    proxy: {
      proxyContract: "EIP173Proxy",
      owner: deployer.address,
      proxyArgs: [ethers.constants.AddressZero, deployer.address, "0x"],
    },
    deterministicDeployment: keccak256(toUtf8Bytes("NodeKey-prod")),
  });

  if (isFirst || isHardhat) {
    const proxy = (await ethers.getContract("NodeKey_Proxy")) as EIP173Proxy;
    const implementation = (await ethers.getContract(
      "NodeKey_Implementation"
    )) as NodeKey;

    const initializeData = implementation.interface.encodeFunctionData(
      "initialize",
      ["Key", "KEY"]
    );

    console.log(`Setting implementation to ${implementation.address}`);
    const tx = await proxy.upgradeToAndCall(
      implementation.address,
      initializeData
    );
    const receipt = await tx.wait();
    console.log(`Implementation set in tx: ${receipt.transactionHash}`);
  }
};

deploy.skip = async () => {
  return !isHardhat;
};

deploy.tags = ["NodeKey"];
export default deploy;
