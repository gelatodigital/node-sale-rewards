import { keccak256, toUtf8Bytes } from "ethers/lib/utils";
import hre, { ethers } from "hardhat";
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { isFirstDeploy, isTesting } from "../../src/utils";
import { EIP173Proxy, MockRewardToken } from "../../typechain";

const isHardhat = isTesting(hre.network.name);

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;
  const { deploy } = deployments;

  const [deployer] = await hre.ethers.getSigners();

  const isFirst = await isFirstDeploy(hre, "MockRewardToken");

  await deploy("MockRewardToken", {
    from: deployer.address,
    args: [],
    log: true,
    proxy: {
      proxyContract: "EIP173Proxy",
      owner: deployer.address,
      proxyArgs: [ethers.constants.AddressZero, deployer.address, "0x"],
    },
    deterministicDeployment: keccak256(toUtf8Bytes("RewardToken-mock")),
  });

  if (isFirst || isHardhat) {
    const proxy = (await ethers.getContract(
      "MockRewardToken_Proxy"
    )) as EIP173Proxy;
    const implementation = (await ethers.getContract(
      "MockRewardToken_Implementation"
    )) as MockRewardToken;

    const initializeData = implementation.interface.encodeFunctionData(
      "initialize",
      ["MockRewardToken", "REWARDTOKEN"]
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

// deploy.skip = async (hre: HardhatRuntimeEnvironment) => {
//   const shouldSkip = hre.network.name !== "hardhat";
//   return shouldSkip;
// };

deploy.tags = ["MockRewardToken"];
export default deploy;
