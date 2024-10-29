import { ethers } from "hardhat";
import { HDNodeWallet, Wallet } from "ethers/lib.commonjs";
import { expect, assert } from "chai";
import "@nomicfoundation/hardhat-chai-matchers";
import { StealthERC721__factory, StealthERC721 } from "../typechain-types";

describe("e2e test", () => {
  let contract: StealthERC721;
  let sender: HDNodeWallet;
  let receiver: HDNodeWallet;
  let stealthAccount: Wallet;

  let stealthAddress: string;
  let publishedDataX: string;
  let publishedDataY: string;

  const TOKEN_ID = 10;
  const SECRET = "0xaaa";

  before(async () => {
    const signer = (await ethers.getSigners())[0];
    sender = ethers.Wallet.createRandom().connect(ethers.provider);
    receiver = ethers.Wallet.createRandom().connect(ethers.provider);

    const sendEthTx1 = await signer.sendTransaction({
      to: sender.address,
      value: ethers.parseEther("100"),
    });
    await sendEthTx1.wait();
    const sendEthTx2 = await signer.sendTransaction({
      to: receiver.address,
      value: ethers.parseEther("100"),
    });
    await sendEthTx2.wait();

    contract = await new StealthERC721__factory().connect(signer).deploy();
    await contract.waitForDeployment();
  });

  it("Sender mint token", async () => {
    const mintTx = await contract.mint(sender.address, TOKEN_ID);
    await mintTx.wait();
    assert((await contract.ownerOf(TOKEN_ID)) == sender.address, "token not minted to sender");
  });

  it("Receiver register public key", async () => {
    const pub = receiver.signingKey.publicKey.slice(4); // prefix(0x), 비압축방식 prefix(04)
    const pubX = "0x" + pub.slice(0, 64);
    const pubY = "0x" + pub.slice(64);

    const registerTx = await contract.connect(receiver).register(pubX, pubY);
    await registerTx.wait();
    const registerdPub = await contract.publicKeyOf(receiver.address);
    assert(registerdPub.x == pubX, "registered pubX wrong");
    assert(registerdPub.y == pubY, "registered pubY wrong");
  });

  it("Sender transfer token to stealth address", async () => {
    [stealthAddress, publishedDataX, publishedDataY] = await contract.getStealthAddress(
      receiver.address,
      SECRET
    );

    const transferTx = await contract
      .connect(sender)
      .stealthTransfer(stealthAddress, TOKEN_ID, publishedDataX, publishedDataY);
    await expect(transferTx)
      .to.emit(contract, "StealthTransfer")
      .withArgs(stealthAddress, publishedDataX, publishedDataY);
  });

  it("Receiver compute stealth account pk", async () => {
    const stealthAccountPK = await contract.computeStealthAccountPK(
      receiver.privateKey,
      publishedDataX,
      publishedDataY
    );
    stealthAccount = new ethers.Wallet(stealthAccountPK);

    expect(stealthAccount.address).to.equal(stealthAddress);
  });

  it("Transfer token from stealth account", async () => {
    const etherTransferTx = await receiver.sendTransaction({
      to: stealthAddress,
      value: ethers.parseEther("10"),
    });
    await etherTransferTx.wait();

    const tokenTransferTx = await contract
      .connect(stealthAccount.connect(ethers.provider))
      .transferFrom(stealthAddress, receiver.address, TOKEN_ID);
    await tokenTransferTx.wait();

    expect(await contract.ownerOf(TOKEN_ID)).to.equal(receiver.address);
  });
});
