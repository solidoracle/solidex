const { ethers } = require("hardhat");

async function main() {
  const Solids = await ethers.getContractFactory("Solids");
  const solids = await Solids.deploy();
  await solids.deployed();
  console.log("solids deployed to: ", solids.address);
  const balance = await solids.balanceOf(
    "0xc5e92e7f2e1cf916b97db500587b79da23fadeb1"
  );

  console.log("my balance of solids: ", balance.toString());

  const Solidex = await ethers.getContractFactory("Solidex");
  const solidex = await Solidex.deploy(solids.address);
  await solidex.deployed();

  console.log("solidex deployed to: ", solidex.address);

  // Approving DEX to take Solids from main account
  await solids.approve(solidex.address, ethers.utils.parseEther("100"));
  console.log("INIT exchange...");
  await solidex.init(ethers.utils.parseEther("0.01"), {
    value: ethers.utils.parseEther("0.01"),
    gasLimit: 200000,
  });

  const totalLiquidity = solidex.totalLiquidity();
  console.log("totalLiquidity", totalLiquidity);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
