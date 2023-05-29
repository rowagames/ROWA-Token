// Import the necessary libraries
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber, Contract, Signer } from "ethers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
describe("Vesting Contract Constructor", function () {
    let RowaToken: any,
    rowaToken: Contract,
    VestingContract: any,
    vestingContract: Contract,
    owner: Signer,
    addrs: Signer[];

  const DECIMALS = 5;

  beforeEach(async function () {
    // Get the ContractFactory and Signers here
    RowaToken = await ethers.getContractFactory("RowaToken");
    [owner, ...addrs] = await ethers.getSigners();

    // Deploy the RowaToken contract
    rowaToken = await RowaToken.deploy();
    await rowaToken.deployed();

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
    await vestingContract.deployed();
  });
  it("Should fail if token_ address is 0", async function () {
    await expect(
      VestingContract.deploy(
        ethers.constants.AddressZero,
        (await addrs[0].getAddress()),
        (await addrs[1].getAddress()),
        (await addrs[2].getAddress()),
        (await addrs[3].getAddress())
      )
    ).to.be.revertedWith("Token address cannot be 0");
  });

  it("Should fail if VGP_FUND_ address is 0", async function () {
    await expect(
      VestingContract.deploy(
        rowaToken.address,
        ethers.constants.AddressZero,
        (await addrs[0].getAddress()),
        (await addrs[1].getAddress()),
        (await addrs[2].getAddress()),
        
      )
    ).to.be.revertedWith("VGP_FUND address cannot be 0");
  });

  it("Should fail if LP_FUND_ address is 0", async function () {
    await expect(
      VestingContract.deploy(
        rowaToken.address,
        (await addrs[0].getAddress()),
        ethers.constants.AddressZero,


        (await addrs[2].getAddress()),
        (await addrs[3].getAddress())
      )
    ).to.be.revertedWith("LP_FUND address cannot be 0");
  });

  it("Should fail if LIQ_FUND_ address is 0", async function () {
    await expect(
      VestingContract.deploy(
        rowaToken.address,
        (await addrs[2].getAddress()),
        (await addrs[3].getAddress()),
        ethers.constants.AddressZero,
        (await addrs[0].getAddress()),
      )
    ).to.be.revertedWith("LIQ_FUND address cannot be 0");
  });

  it("Should fail if RESERVE_FUND_ address is 0", async function () {
    await expect(
      VestingContract.deploy(
        rowaToken.address,
        (await addrs[0].getAddress()),
        (await addrs[1].getAddress()),
        (await addrs[2].getAddress()),
        ethers.constants.AddressZero
      )
    ).to.be.revertedWith("RESERVE_FUND address cannot be 0");
  });

  it("Should deploy successfully with non-zero addresses", async function () {
    const vestingContract = await VestingContract.deploy(
      rowaToken.address,
      (await addrs[0].getAddress()),
      (await addrs[1].getAddress()),
      (await addrs[2].getAddress()),
      (await addrs[3].getAddress())
    );
    await vestingContract.deployed();
    expect(vestingContract.address).to.properAddress;
  });

  describe("Vesting Schedule Retrieval", function () {

    it("Should return correct vesting schedule for given holder and index", async function () {
      // Assuming a function to set a VestingSchedule for testing
      await rowaToken.startVesting(vestingContract.address);

      const index = 0;
      const holderAddress = await addrs[0].getAddress();

      // Add a VestingSchedule for testing
      await vestingContract.createPublicSaleVesting(
        await addrs[0].getAddress(),
        BigNumber.from(10000000000));

      // Calculate the vestingScheduleId
      const vestingScheduleId = await vestingContract.computeVestingScheduleIdForAddressAndIndex(holderAddress, index);

      // Retrieve the VestingSchedule directly
      const directVestingSchedule = await vestingContract.getVestingSchedule(vestingScheduleId);

      // Retrieve the VestingSchedule via getVestingScheduleByAddressAndIndex
      const retrievedVestingSchedule = await vestingContract.getVestingScheduleByAddressAndIndex(holderAddress, index);

      // Check that the two retrieval methods return the same result
      expect(directVestingSchedule).to.deep.equal(retrievedVestingSchedule);
    });

  });
  describe("Token Address Retrieval", function () {
    
    it("Should return the correct token address", async function () {
      // Get the token address directly from the contract
      const tokenAddressDirectly = await rowaToken.address;

      // Retrieve the token address via getTokenAddress
      const retrievedTokenAddress = await vestingContract.getTokenAddress();

      // Check that the two retrieval methods return the same result
      expect(retrievedTokenAddress).to.equal(tokenAddressDirectly);
    });

  });
  describe("Vesting Schedules Total Amount", function () {
    it("Should return the correct total amount of vesting schedules", async function () {
        await rowaToken.startVesting(vestingContract.address);

      // Assume addTestVestingSchedule function adds a VestingSchedule and increments vestingSchedulesTotalAmount
      const holderAddress1 = await addrs[0].getAddress();
      const holderAddress2 = await addrs[1].getAddress();

      await vestingContract.createPublicSaleVesting(
        holderAddress1,
        BigNumber.from(1000000));
        
      await vestingContract.createPublicSaleVesting(
        holderAddress2,
        BigNumber.from(1000000));

      const totalAmount = await vestingContract.getVestingSchedulesTotalAmount();

      expect(totalAmount).to.equal(2000000);
    });
  });

});