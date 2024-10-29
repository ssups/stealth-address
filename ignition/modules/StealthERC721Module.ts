import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const StealthERC721_Module = buildModule("StealthERC721_Module", (m) => {
  const stealthERC721 = m.contract("StealthERC721");
  return { stealthERC721 };
});

export default StealthERC721_Module;
