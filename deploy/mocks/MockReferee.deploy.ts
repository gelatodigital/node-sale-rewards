import { keccak256, toUtf8Bytes } from "ethers/lib/utils";
import hre, { ethers } from "hardhat";
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { isFirstDeploy, isTesting } from "../../src/utils";
import { EIP173Proxy, MockReferee } from "../../typechain";

const isHardhat = isTesting(hre.network.name);

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;
  const { deploy } = deployments;

  const [deployer] = await hre.ethers.getSigners();

  const nodeKeyAddress = (await ethers.getContract("MockNodeKey")).address;

  const isFirst = await isFirstDeploy(hre, "MockReferee");

  console.log("DEPLOYING MOCK REFEREE");
  await deploy("MockReferee", {
    from: deployer.address,
    args: [nodeKeyAddress],
    log: !isHardhat,
    proxy: {
      proxyContract: "EIP173ProxyWithReceive",
      owner: deployer.address,
      proxyArgs: [ethers.constants.AddressZero, deployer.address, "0x"],
    },
    deterministicDeployment: keccak256(toUtf8Bytes("Referee-mock")),
  });

  if (isFirst || isHardhat) {
    const proxy = (await ethers.getContract(
      "MockReferee_Proxy"
    )) as EIP173Proxy;
    const implementation = (await ethers.getContract(
      "MockReferee_Implementation"
    )) as MockReferee;

    console.log(`Setting implementation to ${implementation.address}`);
    const tx = await proxy.upgradeTo(implementation.address);
    const receipt = await tx.wait();
    console.log(`Implementation set in tx: ${receipt.transactionHash}`);
  }
};

deploy.skip = async () => {
  return !isHardhat;
};

deploy.tags = ["MockReferee"];
export default deploy;
