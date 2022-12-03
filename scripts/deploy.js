const hre = require('hardhat');

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const GrantsCubeNFTFactory = await hre.ethers.getContractFactory('GrantsCubeNFTFactory');
  const grantsCubeNFTFactory = await GrantsCubeNFTFactory.deploy(deployer.address);

  await grantsCubeNFTFactory.deployed();
  console.log('GrantsCubeNFTFactory deployed to:', grantsCubeNFTFactory.address);


  const ProjectFactory = await hre.ethers.getContractFactory('ProjectFactory');
  const projectFactory = await ProjectFactory.deploy();

  await projectFactory.deployed();
  console.log('ProjectFactory deployed to:', projectFactory.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

