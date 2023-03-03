const hre = require("hardhat");

async function main() {
  const Trust = await hre.ethers.getContractFactory("Trust");
  const trust = await Trust.deploy();

  await trust.deployed();

  console.log("Trust contract deployed to:", trust.address);
  storeContractData(trust);
}

function storeContractData(contract) {
  const fs = require("fs");
  const contractsDir = __dirname + "/../contracts";

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  fs.writeFileSync(
    contractsDir + "/Trust-address.json",
    JSON.stringify({ Trust: contract.address }, undefined, 2)
  );

  const TrustArtifact = artifacts.readArtifactSync("Trust");

  fs.writeFileSync(
    contractsDir + "/Trust.json",
    JSON.stringify(TrustArtifact, null, 2)
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });