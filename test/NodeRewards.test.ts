import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { expect } from "chai";
import {
  MockNodeKey,
  MockReferee,
  MockRewardToken,
  NodeRewards,
} from "../typechain";
import { fastForwardToFinalize } from "./utils";
import hre = require("hardhat");
const { ethers } = hre;

describe("NodeKey Tests", function () {
  this.timeout(0);

  let nodeKey: MockNodeKey;
  let nodeRewards: NodeRewards;
  let rewardToken: MockRewardToken;
  let referee: MockReferee;

  let owner: SignerWithAddress;
  let nodeKeyOwner: SignerWithAddress;
  let nodeKeyOwner2: SignerWithAddress;

  this.beforeEach(async function () {
    await hre.deployments.fixture([
      "MockNodeKey",
      "MockReferee",
      "MockRewardToken",
      "MockNodeRewards",
    ]);

    [owner, nodeKeyOwner, nodeKeyOwner2] = await ethers.getSigners();

    nodeKey = (await ethers.getContract("MockNodeKey")) as MockNodeKey;
    rewardToken = (await ethers.getContract(
      "MockRewardToken"
    )) as MockRewardToken;
    nodeRewards = (await ethers.getContract("NodeRewards")) as NodeRewards;
    referee = (await ethers.getContract("MockReferee")) as MockReferee;

    // set node rewards address in referee
    await referee.connect(owner).setNodeRewards(nodeRewards.address);

    // mint reward token to node rewards contract
    await rewardToken
      .connect(owner)
      .mint(nodeRewards.address, ethers.utils.parseEther("100000000"));

    // mint node key to node key owner
    await nodeKey.connect(owner).mint(nodeKeyOwner.address, 1);
    await nodeKey.connect(owner).mint(nodeKeyOwner2.address, 2);

    // grant kyc controller role
    const role = await nodeRewards.KYC_CONTROLLER_ROLE();
    await nodeRewards.connect(owner).grantRole(role, owner.address);

    // add kyc wallets
    await nodeRewards
      .connect(owner)
      .addKycWallets([nodeKeyOwner.address, nodeKeyOwner2.address]);
  });

  it("should be able to claim rewards", async () => {
    const batchNumberToAttest = (
      await referee.latestFinalizedBatchNumber()
    ).add(1);
    await referee.connect(nodeKeyOwner).attest(batchNumberToAttest, 1);

    await fastForwardToFinalize();
    await referee.connect(owner).finalize();

    const balanceBefore = await rewardToken.balanceOf(nodeKeyOwner.address);
    await referee.connect(nodeKeyOwner).claimReward(1, 1);
    const balanceAfter = await rewardToken.balanceOf(nodeKeyOwner.address);

    expect(balanceAfter).to.be.gt(balanceBefore);
  });

  it("should have double the rewards for having second node key", async () => {
    const batchNumberToAttest = (
      await referee.latestFinalizedBatchNumber()
    ).add(1);
    await referee.connect(nodeKeyOwner).attest(batchNumberToAttest, 1);
    await referee
      .connect(nodeKeyOwner2)
      .batchAttest(batchNumberToAttest, [2, 3]);

    await fastForwardToFinalize();
    await referee.connect(owner).finalize();

    const balanceBefore = await rewardToken.balanceOf(nodeKeyOwner.address);
    await referee.connect(nodeKeyOwner).claimReward(1, 1);
    const balanceAfter = await rewardToken.balanceOf(nodeKeyOwner.address);
    const receivedReward = balanceAfter.sub(balanceBefore);

    const balanceBefore2 = await rewardToken.balanceOf(nodeKeyOwner2.address);
    await referee.connect(nodeKeyOwner2).batchClaimReward([2, 3], 1);
    const balanceAfter2 = await rewardToken.balanceOf(nodeKeyOwner2.address);
    const receivedReward2 = balanceAfter2.sub(balanceBefore2);

    expect(receivedReward2).to.be.gt(receivedReward);
    expect(receivedReward2).to.equal(receivedReward.mul(2));
  });

  it("should calculate rewards correctly", async () => {
    const batchNumberToAttest = (
      await referee.latestFinalizedBatchNumber()
    ).add(1);
    await referee.connect(nodeKeyOwner).attest(batchNumberToAttest, 1);

    await referee
      .connect(nodeKeyOwner2)
      .batchAttest(batchNumberToAttest, [2, 3]);

    const previousLatestConfirmedTimestamp =
      await referee.latestConfirmedTimestamp();

    await fastForwardToFinalize();
    await referee.connect(owner).finalize();

    const currentLatestConfirmedTimestamp =
      await referee.latestConfirmedTimestamp();

    const maxRewardTimeWindow = await nodeRewards.MAX_REWARD_TIME_WINDOW();
    const rewardTimeWindow = Math.min(
      currentLatestConfirmedTimestamp
        .sub(previousLatestConfirmedTimestamp)
        .toNumber(),
      maxRewardTimeWindow.toNumber()
    );

    const nrOfSuccessfulAttestations = 3;
    const rewardPerSecond = await nodeRewards.rewardPerSecond();

    const expectedReward = rewardPerSecond
      .mul(rewardTimeWindow)
      .div(nrOfSuccessfulAttestations);
    const reward = await nodeRewards.rewardPerNodeKeyOfBatch(
      batchNumberToAttest
    );

    expect(reward).to.equal(expectedReward);
  });
});
