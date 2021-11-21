const hre = require("hardhat");

async function main() {
  const WEther = await hre.ethers.getContractFactory("WEther");
  const wEther = await WEther.deploy();
  const wEthAddress = wEther.address;

  const SimpleArbitrator = await hre.ethers.getContractFactory(
    "SimpleArbitrator"
  );
  const arbitrator = await SimpleArbitrator.deploy();
  const arbAddress = arbitrator.address;

  const AgreementManager = await hre.ethers.getContractFactory(
    "AgreementManager"
  );
  const agreementManager = await AgreementManager.deploy(
    wEthAddress,
    arbAddress
  );
  const agreementManagerAddress = agreementManager.address;

  console.log({
    wEthAddress,
    arbAddress,
    agreementManagerAddress
  })
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
