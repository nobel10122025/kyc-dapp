// deploy.js
const hre = require("hardhat");
async function main() {
  //to get the contract deployed over the testnet
  const KYC_contract = await hre.ethers.getContractFactory(
    "KYC"
  );
  const kyc_contract = await KYC_contract.deploy();
  await kyc_contract.deployed();
  console.log("kyc contract is deployed to:", kyc_contract.address);
}
//to handle errors
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
