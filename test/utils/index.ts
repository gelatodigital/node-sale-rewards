import hre from "hardhat";

const secondsToFinalize = 12 * 60 * 60; // 12 hours

export const fastForwardToFinalize = async () => {
  await hre.network.provider.send("evm_increaseTime", [secondsToFinalize]);
  await hre.network.provider.send("evm_mine", []);
};
