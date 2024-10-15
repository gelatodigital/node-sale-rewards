import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { expect } from "chai";
import { NodeKey } from "../typechain";
import hre = require("hardhat");
const { ethers } = hre;

describe("NodeKey Tests", function () {
  this.timeout(0);

  let nodeKey: NodeKey;

  let owner: SignerWithAddress;
  let nodeKeyOwner: SignerWithAddress;
  let random: SignerWithAddress;

  beforeEach(async function () {
    [owner, nodeKeyOwner, random] = await ethers.getSigners();

    const proxyFactory = await ethers.getContractFactory("EIP173Proxy");

    const nodeKeyContractFactory = await ethers.getContractFactory("NodeKey");

    const nodeKeyImplementation = await nodeKeyContractFactory.deploy();
    const nodeKeyInitData = nodeKeyImplementation.interface.encodeFunctionData(
      "initialize",
      ["Key", "KEY"]
    );
    const nodeKeyProxy = await proxyFactory.deploy(
      nodeKeyImplementation.address,
      owner.address,
      nodeKeyInitData
    );

    nodeKey = (await ethers.getContractAt(
      "NodeKey",
      nodeKeyProxy.address
    )) as NodeKey;
  });

  it("revert if not proxy admin", async () => {
    await expect(
      nodeKey.connect(random).mint(nodeKeyOwner.address, 1)
    ).to.be.revertedWith("NOT_AUTHORIZED");
  });

  it("mint to node key owner", async () => {
    await nodeKey.connect(owner).mint(nodeKeyOwner.address, 1);

    expect(await nodeKey.ownerOf(1)).to.be.eql(nodeKeyOwner.address);
    expect((await nodeKey.totalSupply()).toNumber()).to.be.eql(1);
  });

  it("mint multiple keys to node key owner", async () => {
    await nodeKey.connect(owner).mint(nodeKeyOwner.address, 3);

    expect(await nodeKey.ownerOf(1)).to.be.eql(nodeKeyOwner.address);
    expect(await nodeKey.ownerOf(2)).to.be.eql(nodeKeyOwner.address);
    expect(await nodeKey.ownerOf(3)).to.be.eql(nodeKeyOwner.address);
    expect((await nodeKey.totalSupply()).toNumber()).to.be.eql(3);
  });

  it("revert when transferFrom", async () => {
    await nodeKey.connect(owner).mint(nodeKeyOwner.address, 1);

    await expect(
      nodeKey
        .connect(owner)
        .transferFrom(nodeKeyOwner.address, random.address, 1)
    ).to.be.revertedWith("NonTransferable");
  });
});
