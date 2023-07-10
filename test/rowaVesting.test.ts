// Import the necessary libraries
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber, Contract, Signer } from "ethers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { float } from "hardhat/internal/core/params/argumentTypes";

// Define the test suite
describe("RowaToken and Vesting Contract", function () {
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
  it("createPublicSaleVesting should fail when called by non-owner", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const nonOwnerVesting = vestingContract.connect(addr1);

    // Assert
    await expect(
      nonOwnerVesting.createPublicSaleVesting(addr2.address, 100000)
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });
  it("createTeamVesting should fail when called by non-owner", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const nonOwnerVesting = vestingContract.connect(addr1);

    // Assert
    await expect(
      nonOwnerVesting.createTeamVesting(addr2.address, 100000, false)
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });
  it("createAdvisorVesting should fail when called by non-owner", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const nonOwnerVesting = vestingContract.connect(addr1);

    // Assert
    await expect(
      nonOwnerVesting.createAdvisorVesting(addr2.address, 100000, false)
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });
  it("createPartnershipsVesting should fail when called by non-owner", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const nonOwnerVesting = vestingContract.connect(addr1);

    // Assert
    await expect(
      nonOwnerVesting.createPartnershipsVesting(addr2.address, 100000, false)
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });
  // Test 1: Smart contract deployment
  it("should deploy the smart contract correctly", async function () {
    expect(rowaToken.address).to.exist;
    expect(vestingContract.address).to.exist;
  });

  // Test 3: Validate the total initial supply and owner's balance
  it("should not mint the total supply to the owner", async function () {
    let ownerAddress = await owner.getAddress();
    const ownerBalance = await rowaToken.balanceOf(ownerAddress);
    expect(ownerBalance).to.equal(0);
  });

  // Test 4: Verify the contract starts in paused state
  it("should not start in paused state", async function () {
    expect(await rowaToken.paused()).to.equal(false);
  });

  // Test 5: Check if the vesting starts correctly and mints initial supply to the vesting contract
  it("should correctly start vesting and mints initial supply to vesting contract", async function () {
    await rowaToken.startVesting(vestingContract.address);
    const vestingContractBalance = await rowaToken.balanceOf(
      vestingContract.address
    );
    expect(vestingContractBalance).to.equal(await rowaToken.totalSupply());
  });

  it("should correctly start vesting and mints initial supply to vesting contract", async function () {
    await rowaToken.startVesting(vestingContract.address);
    const vestingContractBalance = await rowaToken.balanceOf(
      vestingContract.address
    );
    expect(vestingContractBalance).to.equal(await rowaToken.totalSupply());
  });

  it("should not allow adding to the vesting schedules if exceed the total supply", async function () {
    await rowaToken.startVesting(vestingContract.address);
    await expect(
      vestingContract.createPublicSaleVesting(
        await addrs[0].getAddress(),
        BigNumber.from(1000000000000000)
      )
    ).to.be.revertedWith("Public sale vesting amount exceeds total amount");
  });

  describe("Public Sale Vesting Revoke", () => {
    it("Should fail when trying to revoke a non-revokable public sale vesting", async () => {
      // Start vesting
      await rowaToken.startVesting(vestingContract.address);

      // Beneficiary address
      const beneficiaryAddress = await addrs[0].getAddress();

      // Vesting amount
      const amount = BigNumber.from("1000").mul(
        BigNumber.from(10).pow(DECIMALS)
      );

      // Create public sale vesting
      await expect(
        vestingContract
          .connect(owner)
          .createPublicSaleVesting(beneficiaryAddress, amount)
      ).to.be.emit(vestingContract, "PublicSaleVestingScheduleCreated");

      // Get the public sale vesting ID
      const vestingIndex =
        await vestingContract.getVestingSchedulesCountByBeneficiary(
          beneficiaryAddress
        );
      const vestingScheduleId =
        await vestingContract.computeVestingScheduleIdForAddressAndIndex(
          beneficiaryAddress,
          vestingIndex - 1
        );

      // Try to revoke the vesting and expect an error
      await expect(
        vestingContract.connect(owner).revoke(vestingScheduleId)
      ).to.be.revertedWith("TokenVesting: vesting is not revocable");
    });
  });

  // Each test will attempt to create a vesting schedule after unpause
  for (let i = 0; i < 10; i++) {
    it(`Should not allow creating new vesting schedules before vesting started (Test ${
      i + 1
    })`, async function () {
      const beneficiary = await addrs[i].getAddress();
      const amount = BigNumber.from(1000);

      await expect(
        vestingContract.createPublicSaleVesting(beneficiary, amount)
      ).to.be.revertedWith(
        "TokenVesting: cannot create vesting schedule because not sufficient tokens"
      );

      await expect(
        vestingContract.createPrivateSaleVesting(beneficiary, amount)
      ).to.be.revertedWith(
        "TokenVesting: cannot create vesting schedule because not sufficient tokens"
      );

      await expect(
        vestingContract.createSeedSaleVesting(beneficiary, amount)
      ).to.be.revertedWith(
        "TokenVesting: cannot create vesting schedule because not sufficient tokens"
      );

      await expect(
        vestingContract.createTeamVesting(beneficiary, amount, true)
      ).to.be.revertedWith(
        "TokenVesting: cannot create vesting schedule because not sufficient tokens"
      );

      await expect(
        vestingContract.createAdvisorVesting(beneficiary, amount, true)
      ).to.be.revertedWith(
        "TokenVesting: cannot create vesting schedule because not sufficient tokens"
      );

      await expect(
        vestingContract.createPartnershipsVesting(beneficiary, amount, true)
      ).to.be.revertedWith(
        "TokenVesting: cannot create vesting schedule because not sufficient tokens"
      );
    });
  }

  it("Should revert when a non-owner tries to unpause the contract", async function () {
    await expect(
      rowaToken.connect(addrs[0]).startVesting(await addrs[0].getAddress())
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  //Test the require statement in the createPublicSaleVesting function:

  it("Should revert when trying to vest more than the total allowed for public sale", async function () {
    const beneficiary = await addrs[0].getAddress();
    const amount = ethers.utils.parseEther("1000000001"); // An arbitrary large number

    await expect(
      vestingContract.createPublicSaleVesting(beneficiary, amount)
    ).to.be.revertedWith("Public sale vesting amount exceeds total amount");
  });

  //Test the require statement in the createPrivateSaleVesting function

  it("Should revert when trying to vest more than the total allowed for private sale", async function () {
    const beneficiary = await addrs[1].getAddress();
    const amount = ethers.utils.parseEther("1000000001");

    await expect(
      vestingContract.createPrivateSaleVesting(beneficiary, amount)
    ).to.be.revertedWith("Private sale vesting amount exceeds total amount");
  });

  //Test the require statement in the createSeedSaleVesting function

  it("Should revert when trying to vest more than the total allowed for seed sale", async function () {
    const beneficiary = await addrs[2].getAddress();
    const amount = ethers.utils.parseEther("1000000001");

    await expect(
      vestingContract.createSeedSaleVesting(beneficiary, amount)
    ).to.be.revertedWith("Seed sale vesting amount exceeds total amount");
  });

  //Test the require statement in the createTeamVesting function

  it("Should revert when trying to vest more than the total allowed for team", async function () {
    const beneficiary = await addrs[3].getAddress();
    const amount = ethers.utils.parseEther("1000000001");

    await expect(
      vestingContract.createTeamVesting(beneficiary, amount, true)
    ).to.be.revertedWith("Team vesting amount exceeds total amount");
  });

  //Test the require statement in the createAdvisorVesting function:

  it("Should revert when trying to vest more than the total allowed for advisors", async function () {
    const beneficiary = await addrs[4].getAddress();
    const amount = ethers.utils.parseEther("1000000001");

    await expect(
      vestingContract.createAdvisorVesting(beneficiary, amount, true)
    ).to.be.revertedWith("Advisor vesting amount exceeds total amount");
  });

  //Test the require statement in the createPartnershipsVesting function:

  it("Should revert when trying to vest more than the total allowed for partnerships", async function () {
    await rowaToken.startVesting(vestingContract.address);

    const beneficiary = await addrs[5].getAddress();
    const amount = BigNumber.from(1000000000000001);

    await expect(
      vestingContract.createPartnershipsVesting(beneficiary, amount, true)
    ).to.be.revertedWith("Partnerships vesting amount exceeds total amount");
  });

  //Test the require statement in the revoke function:

  it("Should revert when trying to revoke a non-revocable vesting", async function () {
    await rowaToken.startVesting(vestingContract.address);

    const beneficiary = await addrs[7].getAddress();
    const amount = BigNumber.from(1000);

    await vestingContract.createPublicSaleVesting(beneficiary, amount);

    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        beneficiary,
        0
      );

    await expect(vestingContract.revoke(vestingScheduleId)).to.be.revertedWith(
      "TokenVesting: vesting is not revocable"
    );
  });

  //Test the require statement in the release function:

  it("Should revert when trying to release before the freeze period", async function () {
    await rowaToken.startVesting(vestingContract.address);
    const beneficiary = await addrs[8].getAddress();
    const amount = BigNumber.from(1000);

    await vestingContract
      .connect(owner)
      .createPublicSaleVesting(beneficiary, amount);

    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        beneficiary,
        0
      );

    await expect(
      vestingContract.release(vestingScheduleId, amount)
    ).to.be.revertedWith(
      "TokenVesting: cannot release tokens, not enough vested tokens"
    );
  });

  //Test the require statement in the release function:

  it("Should revert startVGPVesting when trying to start vesting as a non-owner", async function () {
    await rowaToken.startVesting(vestingContract.address);
    const beneficiary = await addrs[8].getAddress();
    const amount = BigNumber.from(1000000);

    const beneficiarySigner = await ethers.getSigner(beneficiary);

    await expect(
      vestingContract.connect(beneficiarySigner).startVGPVesting()
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should revert startVGPVesting when trying to release more than initial locked amount", async function () {
    await rowaToken.startVesting(vestingContract.address);
    const beneficiary = await addrs[5].getAddress();
    const amount = BigNumber.from(10000000000000);

    await vestingContract.connect(owner).startVGPVesting();

    const ownerAddress = await owner.getAddress();

    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        ownerAddress,
        0
      );

    await expect(
      vestingContract.release(vestingScheduleId, amount)
    ).to.be.revertedWith(
      "TokenVesting: cannot release tokens, not enough vested tokens"
    );
  });

  it("Should emit a VGPVestingScheduleCreated event when starting vesting for startVGPVesting", async function () {
    await rowaToken.startVesting(vestingContract.address);
    const beneficiary = await addrs[5].getAddress();
    const amount = BigNumber.from(100000000000);

    await expect(vestingContract.connect(owner).startVGPVesting()).to.be.emit(
      vestingContract,
      "VGPVestingScheduleCreated"
    );

    const ownerAddress = await owner.getAddress();

    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        ownerAddress,
        0
      );

    await vestingContract.release(vestingScheduleId, amount);
  });

  it("Should revert startVGPVesting when trying to start vesting more than once", async function () {
    await rowaToken.startVesting(vestingContract.address);
    const beneficiary = await addrs[5].getAddress();
    const amount = BigNumber.from(100000000000);

    await expect(vestingContract.connect(owner).startVGPVesting()).to.be.emit(
      vestingContract,
      "VGPVestingScheduleCreated"
    );

    await expect(
      vestingContract.connect(owner).startVGPVesting()
    ).to.be.revertedWith("VGP vesting already started");
  });

  it("Should revert startLPVesting when trying to start vesting more than once", async function () {
    await rowaToken.startVesting(vestingContract.address);
    const beneficiary = await addrs[5].getAddress();
    const amount = BigNumber.from(100000000000);

    await expect(vestingContract.connect(owner).startLPVesting()).to.be.emit(
      vestingContract,
      "LPVestingScheduleCreated"
    );

    await expect(
      vestingContract.connect(owner).startLPVesting()
    ).to.be.revertedWith("LP vesting already started");
  });

  it("Should revert startLPVesting when trying to release more than initial locked amount", async function () {
    await rowaToken.startVesting(vestingContract.address);
    const beneficiary = await addrs[5].getAddress();
    const amount = BigNumber.from(10000000000000);

    await vestingContract.connect(owner).startLPVesting();

    const ownerAddress = await owner.getAddress();

    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        ownerAddress,
        0
      );

    await expect(
      vestingContract.release(vestingScheduleId, amount)
    ).to.be.revertedWith(
      "TokenVesting: cannot release tokens, not enough vested tokens"
    );
  });

  it("Should revert startLPVesting when trying to start vesting as a non-owner", async function () {
    await rowaToken.startVesting(vestingContract.address);
    const beneficiary = await addrs[8].getAddress();
    const amount = BigNumber.from(1000000);

    const beneficiarySigner = await ethers.getSigner(beneficiary);

    await expect(
      vestingContract.connect(beneficiarySigner).startLPVesting()
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should revert startLiqVesting when trying to start vesting more than once", async function () {
    await rowaToken.startVesting(vestingContract.address);
    const beneficiary = await addrs[5].getAddress();
    const amount = BigNumber.from(100000000000);

    await expect(vestingContract.connect(owner).startLiqVesting()).to.be.emit(
      vestingContract,
      "LiqVestingScheduleCreated"
    );

    await expect(
      vestingContract.connect(owner).startLiqVesting()
    ).to.be.revertedWith("Liq vesting already started");
  });

  it("Should revert startLiqVesting when trying to release more than initial locked amount", async function () {
    await rowaToken.startVesting(vestingContract.address);
    const beneficiary = await addrs[5].getAddress();
    const amount = BigNumber.from(10000000000000);

    await vestingContract.connect(owner).startLiqVesting();

    const ownerAddress = await owner.getAddress();

    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        ownerAddress,
        0
      );

    await expect(
      vestingContract.release(vestingScheduleId, amount)
    ).to.be.revertedWith(
      "TokenVesting: cannot release tokens, not enough vested tokens"
    );
  });

  it("Should revert startLiqVesting when trying to start vesting as a non-owner", async function () {
    await rowaToken.startVesting(vestingContract.address);
    const beneficiary = await addrs[8].getAddress();
    const amount = BigNumber.from(1000000);

    const beneficiarySigner = await ethers.getSigner(beneficiary);

    await expect(
      vestingContract.connect(beneficiarySigner).startLiqVesting()
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should revert startReserveVesting when trying to start vesting more than once", async function () {
    await rowaToken.startVesting(vestingContract.address);
    const beneficiary = await addrs[5].getAddress();
    const amount = BigNumber.from(100000000000);

    await expect(
      vestingContract.connect(owner).startReserveVesting()
    ).to.be.emit(vestingContract, "ReserveVestingScheduleCreated");

    await expect(
      vestingContract.connect(owner).startReserveVesting()
    ).to.be.revertedWith("Reserve vesting already started");
  });

  it("Should revert startReserveVesting when trying to release more than initial locked amount", async function () {
    await rowaToken.startVesting(vestingContract.address);
    const beneficiary = await addrs[5].getAddress();
    const amount = BigNumber.from(10000000000000);

    await vestingContract.connect(owner).startReserveVesting();

    const ownerAddress = await owner.getAddress();

    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        ownerAddress,
        0
      );

    await expect(
      vestingContract.release(vestingScheduleId, amount)
    ).to.be.revertedWith(
      "TokenVesting: cannot release tokens, not enough vested tokens"
    );
  });

  it("Should revert startLiqVesting when trying to start vesting as a non-owner", async function () {
    await rowaToken.startVesting(vestingContract.address);
    const beneficiary = await addrs[8].getAddress();
    const amount = BigNumber.from(1000000);

    const beneficiarySigner = await ethers.getSigner(beneficiary);

    await expect(
      vestingContract.connect(beneficiarySigner).startReserveVesting()
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  //Test the require statement in the releasableAmount function:

  it("Should revert when trying to check releasable amount of a non-existent vesting", async function () {
    const beneficiary = await addrs[9].getAddress();

    const vestingScheduleId =
      await vestingContract.computeNextVestingScheduleIdForHolder(beneficiary);

    await expect(vestingContract.computeReleasableAmount(vestingScheduleId)).to
      .be.reverted;
  });

  it("public Sale allocation vesting", async () => {
    const ownerAddress = await owner.getAddress();
    const vestingAmount = BigNumber.from(10000);

    await rowaToken.startVesting(vestingContract.address);

    // 1. Create a Public Sale Vesting for the owner with 10000 ROWA tokens
    await vestingContract
      .connect(owner)
      .createPublicSaleVesting(ownerAddress, vestingAmount);

    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        ownerAddress,
        0
      );

    let vested = await vestingContract.computeReleasableAmount(
      vestingScheduleId
    );
    expect(vested).to.equal(vestingAmount.div(4));

    await time.increase(3600 * 24 * 30 * 15);

    // Check that half of the vested amount is available for withdrawal
    vested = await vestingContract.computeReleasableAmount(vestingScheduleId);
    expect(vested).to.equal(vestingAmount);

    // Release half of the tokens
    await vestingContract.connect(owner).release(vestingScheduleId, vested / 2);

    // Check that all vested amount is now available for release
    vested = await vestingContract.computeReleasableAmount(vestingScheduleId);
    expect(vested).to.equal(vestingAmount.div(2));

    // Release the remaining tokens
    await expect(
      vestingContract.connect(owner).release(vestingScheduleId, vested)
    ).emit(vestingContract, "Released");

    await expect(
      vestingContract.connect(owner).release(vestingScheduleId, vested)
    ).to.be.revertedWith(
      "TokenVesting: cannot release tokens, not enough vested tokens"
    );

    // 5. Check that all vested tokens have been withdrawn and balance is now zero
    vested = await vestingContract.computeReleasableAmount(vestingScheduleId);
    expect(vested).to.equal(0);
  });

  it("Should revoke a revocable vesting schedule for team vesting", async () => {
    const ownerAddress = await owner.getAddress();
    const vestingAmount = BigNumber.from(10000);

    await rowaToken.startVesting(vestingContract.address);

    await vestingContract
      .connect(owner)
      .createTeamVesting(ownerAddress, vestingAmount, true);
    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        ownerAddress,
        0
      );

    await expect(vestingContract.revoke(vestingScheduleId)).to.emit(
      vestingContract,
      "Revoked"
    );

    // advance time by one hour and mine a new block
    await time.increase(3600 * 24 * 30 * 15);

    await expect(vestingContract.computeReleasableAmount(vestingScheduleId)).to
      .be.reverted;

    // try to release it after revoking
    await expect(
      vestingContract.connect(owner).release(vestingScheduleId, vestingAmount)
    ).to.be.revertedWith("Vesting schedule revoked");

    // try to revoke again
    await expect(vestingContract.revoke(vestingScheduleId)).to.be.reverted;
  });

  it("Should revert revoke non owner", async () => {
    const ownerAddress = await owner.getAddress();
    const addr1Address = await addrs[1].getAddress();
    const vestingAmount = BigNumber.from(10000);

    await rowaToken.startVesting(vestingContract.address);

    await vestingContract
      .connect(owner)
      .createTeamVesting(ownerAddress, vestingAmount, true);
    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        ownerAddress,
        0
      );

    await expect(
      vestingContract.connect(addrs[1]).revoke(vestingScheduleId)
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should revoke a revocable vesting schedule for advisor vesting", async () => {
    const ownerAddress = await owner.getAddress();
    const vestingAmount = BigNumber.from(10000);

    await rowaToken.startVesting(vestingContract.address);

    await vestingContract
      .connect(owner)
      .createAdvisorVesting(ownerAddress, vestingAmount, true);
    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        ownerAddress,
        0
      );

    await expect(vestingContract.revoke(vestingScheduleId)).to.emit(
      vestingContract,
      "Revoked"
    );
  });

  it("Should revoke a revocable vesting schedule for partnerships vesting", async () => {
    const ownerAddress = await owner.getAddress();
    const vestingAmount = BigNumber.from(10000);

    await rowaToken.startVesting(vestingContract.address);

    await vestingContract
      .connect(owner)
      .createPartnershipsVesting(ownerAddress, vestingAmount, true);
    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        ownerAddress,
        0
      );

    await expect(vestingContract.revoke(vestingScheduleId)).to.emit(
      vestingContract,
      "Revoked"
    );
  });

  it("Should be able to create a createPrivateSaleVesting vesting schedule", async () => {
    const ownerAddress = await owner.getAddress();
    const vestingAmount = BigNumber.from(10000);

    await rowaToken.startVesting(vestingContract.address);

    await expect(
      vestingContract
        .connect(owner)
        .createPrivateSaleVesting(ownerAddress, vestingAmount)
    ).to.be.emit(vestingContract, "PrivateSaleVestingScheduleCreated");
  });

  it("Should revert when trying to create a createPrivateSaleVesting vesting schedule as a non-owner", async () => {
    const ownerAddress = await owner.getAddress();
    const beneficiary = await addrs[1].getAddress();
    const beneficiarySigner = await ethers.getSigner(beneficiary);

    const vestingAmount = BigNumber.from(10000);

    await rowaToken.connect(owner).startVesting(vestingContract.address);

    await expect(
      vestingContract
        .connect(beneficiarySigner)
        .createPrivateSaleVesting(ownerAddress, vestingAmount)
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should revert when trying to release a createPrivateSaleVesting non beneficiary and non owner can release vested tokens", async () => {
    const ownerAddress = await owner.getAddress();
    const secondAddress = await addrs[1];
    const vestingAmount = BigNumber.from(10000);

    await rowaToken.connect(owner).startVesting(vestingContract.address);

    await expect(
      vestingContract
        .connect(owner)
        .createPrivateSaleVesting(ownerAddress, vestingAmount)
    ).to.be.emit(vestingContract, "PrivateSaleVestingScheduleCreated");

    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        ownerAddress,
        0
      );

    await expect(
      vestingContract.connect(secondAddress).release(vestingScheduleId, 1000)
    ).to.be.revertedWith(
      "TokenVesting: only beneficiary and owner can release vested tokens"
    );
  });

  it("Vesting Flow: Should be able to release vested tokens for createPrivateSaleVesting vesting schedule", async () => {
    const ownerAddress = await owner.getAddress();
    const secondAddress = await addrs[1];
    const vestingAmount = BigNumber.from(10000);

    await rowaToken.connect(owner).startVesting(vestingContract.address);

    await vestingContract
      .connect(owner)
      .createPrivateSaleVesting(ownerAddress, vestingAmount);

    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        ownerAddress,
        0
      );

    let releasableAmount = await vestingContract
      .connect(owner)
      .computeReleasableAmount(vestingScheduleId);

    await expect(releasableAmount).to.equal(500);

    await vestingContract.connect(owner).release(vestingScheduleId, 100);

    // advance time by 10 weeks
    await time.increase(time.duration.weeks(10));
    releasableAmount = await vestingContract
      .connect(owner)
      .computeReleasableAmount(vestingScheduleId);

    expect(releasableAmount).to.equal(400);

    await time.increase(time.duration.weeks(12));
    releasableAmount = await vestingContract
      .connect(owner)
      .computeReleasableAmount(vestingScheduleId);

    let expectedAmount = Math.floor(9500 / 12 + 400);

    expect(releasableAmount).to.equal(expectedAmount);

    await vestingContract.connect(owner).release(vestingScheduleId, 400);

    releasableAmount = await vestingContract
      .connect(owner)
      .computeReleasableAmount(vestingScheduleId);

    expectedAmount = Math.floor(9500 / 12 + 400) - 400;

    expect(releasableAmount).to.equal(expectedAmount);

    await time.increase(time.duration.weeks(100));
    releasableAmount = await vestingContract
      .connect(owner)
      .computeReleasableAmount(vestingScheduleId);

    expectedAmount = 9500;

    expect(releasableAmount).to.equal(expectedAmount);
  });

  it("Vesting Flow: Shouldn't be able to release non initial vested tokens for createPrivateSaleVesting vesting schedule if not started (before freeze)", async () => {
    const ownerAddress = await owner.getAddress();
    const secondAddress = await addrs[1];
    const vestingAmount = BigNumber.from(10000);

    await rowaToken.connect(owner).startVesting(vestingContract.address);

    await vestingContract
      .connect(owner)
      .createPrivateSaleVesting(ownerAddress, vestingAmount);

    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        ownerAddress,
        0
      );

    let releasableAmount = await vestingContract
      .connect(owner)
      .computeReleasableAmount(vestingScheduleId);

    await expect(releasableAmount).to.equal(500);

    // advance time by 10 weeks
    await time.increase(time.duration.weeks(10));
    releasableAmount = await vestingContract
      .connect(owner)
      .computeReleasableAmount(vestingScheduleId);

    expect(releasableAmount).to.equal(500);

    await vestingContract.connect(owner).release(vestingScheduleId, 500);

    releasableAmount = await vestingContract
      .connect(owner)
      .computeReleasableAmount(vestingScheduleId);

    expect(releasableAmount).to.equal(0);

    await expect(vestingContract.connect(owner).release(vestingScheduleId, 1))
      .to.be.reverted;
  });

  it("Vesting Flow: Should be able to release vested tokens for createPrivateSaleVesting vesting schedule without no release until the end of the vesting period", async () => {
    const ownerAddress = await owner.getAddress();
    const secondAddress = await addrs[1];
    const vestingAmount = BigNumber.from(10000);

    await rowaToken.connect(owner).startVesting(vestingContract.address);

    await vestingContract
      .connect(owner)
      .createPrivateSaleVesting(ownerAddress, vestingAmount);

    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        ownerAddress,
        0
      );

    let releasableAmount = await vestingContract
      .connect(owner)
      .computeReleasableAmount(vestingScheduleId);

    await expect(releasableAmount).to.equal(500);

    // advance time by 10 weeks
    await time.increase(time.duration.weeks(10));
    releasableAmount = await vestingContract
      .connect(owner)
      .computeReleasableAmount(vestingScheduleId);

    expect(releasableAmount).to.equal(500);

    await time.increase(time.duration.weeks(12));
    releasableAmount = await vestingContract
      .connect(owner)
      .computeReleasableAmount(vestingScheduleId);

    let expectedAmount = Math.floor(9500 / 12 + 500);

    expect(releasableAmount).to.equal(expectedAmount);

    releasableAmount = await vestingContract
      .connect(owner)
      .computeReleasableAmount(vestingScheduleId);

    expectedAmount = Math.floor(9500 / 12 + 500);

    expect(releasableAmount).to.equal(expectedAmount);

    await time.increase(time.duration.weeks(100));
    releasableAmount = await vestingContract
      .connect(owner)
      .computeReleasableAmount(vestingScheduleId);

    expectedAmount = 10000;

    expect(releasableAmount).to.equal(expectedAmount);
  });

  it("Should revert when trying to release a createPrivateSaleVesting with excess amount", async () => {
    const ownerAddress = await owner.getAddress();
    const secondAddress = await addrs[1];
    const vestingAmount = BigNumber.from(10000000000000);

    await rowaToken.connect(owner).startVesting(vestingContract.address);

    await expect(
      vestingContract
        .connect(owner)
        .createPrivateSaleVesting(ownerAddress, vestingAmount)
    ).to.be.revertedWith("Private sale vesting amount exceeds total amount");
  });

  it("Should be able to create a createSeedSaleVesting vesting schedule", async () => {
    const ownerAddress = await owner.getAddress();
    const vestingAmount = BigNumber.from(10000);

    await rowaToken.startVesting(vestingContract.address);

    await expect(
      vestingContract
        .connect(owner)
        .createSeedSaleVesting(ownerAddress, vestingAmount)
    ).to.be.emit(vestingContract, "SeedSaleVestingScheduleCreated");
  });

  it("Should revert when trying to create a createSeedSaleVesting vesting schedule as a non-owner", async () => {
    const ownerAddress = await owner.getAddress();
    const beneficiary = await addrs[1].getAddress();
    const beneficiarySigner = await ethers.getSigner(beneficiary);

    const vestingAmount = BigNumber.from(10000);

    await rowaToken.connect(owner).startVesting(vestingContract.address);

    await expect(
      vestingContract
        .connect(beneficiarySigner)
        .createSeedSaleVesting(ownerAddress, vestingAmount)
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should revert when trying to release a createSeedSaleVesting non beneficiary and non owner can release vested tokens", async () => {
    const ownerAddress = await owner.getAddress();
    const secondAddress = await addrs[1];
    const vestingAmount = BigNumber.from(10000);

    await rowaToken.connect(owner).startVesting(vestingContract.address);

    await expect(
      vestingContract
        .connect(owner)
        .createSeedSaleVesting(ownerAddress, vestingAmount)
    ).to.be.emit(vestingContract, "SeedSaleVestingScheduleCreated");

    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        ownerAddress,
        0
      );

    await expect(
      vestingContract.connect(secondAddress).release(vestingScheduleId, 1000)
    ).to.be.revertedWith(
      "TokenVesting: only beneficiary and owner can release vested tokens"
    );
  });

  it("Should revert when trying to release a createSeedSaleVesting before freeze", async () => {
    const ownerAddress = await owner.getAddress();
    const secondAddress = await addrs[1];
    const vestingAmount = BigNumber.from(10000);

    await rowaToken.connect(owner).startVesting(vestingContract.address);

    await vestingContract
      .connect(owner)
      .createSeedSaleVesting(ownerAddress, vestingAmount);

    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        ownerAddress,
        0
      );

    await vestingContract.connect(owner).release(vestingScheduleId, 500);
  });

  it("Should revert when trying to release a createSeedSaleVesting with excess amount", async () => {
    const ownerAddress = await owner.getAddress();
    const secondAddress = await addrs[1];
    const vestingAmount = BigNumber.from(10000000000000);

    await rowaToken.connect(owner).startVesting(vestingContract.address);

    await expect(
      vestingContract
        .connect(owner)
        .createSeedSaleVesting(ownerAddress, vestingAmount)
    ).to.be.revertedWith("Seed sale vesting amount exceeds total amount");
  });

  it("Get last vesting schedule for holder", async () => {
    await rowaToken.startVesting(vestingContract.address);
    let addr1Address = await addrs[1].getAddress();
    const amount = BigNumber.from(1000);

    await vestingContract
      .connect(owner)
      .createPublicSaleVesting(addr1Address, amount);

    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        addr1Address,
        0
      );

    await vestingContract.getLastVestingScheduleForHolder(addr1Address);
  });

  it("Get vesting at index and check with vesting schedules of holder", async () => {
    await rowaToken.startVesting(vestingContract.address);
    let addr1Address = await addrs[1].getAddress();
    const amount = BigNumber.from(1000);

    await vestingContract
      .connect(owner)
      .createPublicSaleVesting(addr1Address, amount);

    const vestingScheduleId =
      await vestingContract.computeVestingScheduleIdForAddressAndIndex(
        addr1Address,
        0
      );

    await expect(vestingContract.getVestingIdAtIndex(100)).to.be.revertedWith(
      "TokenVesting: index out of bounds"
    );

    const lastVestingScheduleId = await vestingContract.getVestingIdAtIndex(0);

    expect(lastVestingScheduleId).to.equal(vestingScheduleId);

    const vestingScheduleCount =
      await vestingContract.getVestingSchedulesCountByBeneficiary(addr1Address);

    expect(vestingScheduleCount).to.equal(1);
    // Test that trying to get a vesting id at an index greater than the number of vesting schedules fails
    await expect(
      vestingContract.getVestingIdAtIndex(vestingScheduleCount + 1)
    ).to.be.revertedWith("TokenVesting: index out of bounds");
  });
});
