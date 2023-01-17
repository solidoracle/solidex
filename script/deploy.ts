const { ethers } = require("hardhat");

async function main() {
  const Solidex = await ethers.getContractFactory("Solidex");
  const solidex = await Solidex.deploy();
  await solidex.deployed();

  console.log("dwin deployed to: ", solidex.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
