import { keccak256, toUtf8Bytes } from "ethers/lib/utils";
import hre, { ethers } from "hardhat";
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { isFirstDeploy, isTesting } from "../src/utils";
import { EIP173ProxyWithReceive, NodeRewards } from "../typechain";

const isHardhat = isTesting(hre.network.name);

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;
  const { deploy } = deployments;

  const [deployer] = await hre.ethers.getSigners();

  const rewardPerSecond = hre.ethers.utils.parseUnits("10", "gwei");
  const maxRewardTimeWindow = 20 * 60; // 20 minutes
  const refereeAddress = (await ethers.getContract("Referee")).address;
  const nodeKeyAddress = (await ethers.getContract("NodeKey")).address;
  const rewardToken = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
  const adminKycController = deployer.address;

  const isFirst = await isFirstDeploy(hre, "NodeRewards");

  await deploy("NodeRewards", {
    from: deployer.address,
    args: [
      rewardPerSecond,
      maxRewardTimeWindow,
      refereeAddress,
      nodeKeyAddress,
      rewardToken,
    ],
    log: true,
    proxy: {
      proxyContract: "EIP173ProxyWithReceive",
      owner: deployer.address,
      proxyArgs: [ethers.constants.AddressZero, deployer.address, "0x"],
    },
    deterministicDeployment: keccak256(toUtf8Bytes("NodeRewards-prod")),
  });

  if (isFirst || isHardhat) {
    const proxy = (await ethers.getContract(
      "NodeRewards_Proxy"
    )) as EIP173ProxyWithReceive;
    const implementation = (await ethers.getContract(
      "NodeRewards_Implementation"
    )) as NodeRewards;

    const initializeData = implementation.interface.encodeFunctionData(
      "initialize",
      [adminKycController]
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

deploy.skip = async (hre: HardhatRuntimeEnvironment) => {
  const shouldSkip = hre.network.name !== "hardhat";
  return shouldSkip;
};

deploy.tags = ["NodeRewards"];
export default deploy;
