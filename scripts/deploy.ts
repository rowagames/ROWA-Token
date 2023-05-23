import { ethers } from "hardhat";
import { Contract, Signer } from "ethers";

async function main() {
  let RowaToken: any,
    rowaToken: Contract,
    VestingContract: any,
    vestingContract: Contract,
    owner: Signer,
    addr1: Signer,
    addr2: Signer;

  RowaToken = await ethers.getContractFactory("RowaToken");
  [owner, addr1, addr2] = await ethers.getSigners();

  // Deploy the RowaToken contract
  rowaToken = await RowaToken.deploy();
  await rowaToken.deployed();
  console.log(" Token contract deployed to:", rowaToken.address);

  // Deploy a mock VestingContract for testing purposes
  VestingContract = await ethers.getContractFactory("RowaVesting");
  let ownerAddress = await owner.getAddress();
  vestingContract = await VestingContract.deploy(
    rowaToken.address,
    ownerAddress,
    ownerAddress,
    ownerAddress,
    ownerAddress
  );
  let contract = await vestingContract.deployed();
  // print the address of the contract
  console.log(" Vesting contract deployed to:", contract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
