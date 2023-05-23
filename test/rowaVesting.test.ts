// Import the necessary libraries
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber, Contract, Signer } from "ethers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

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
      await vestingContract
        .connect(owner)
        .createPublicSaleVesting(beneficiaryAddress, amount);

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

  it("Should revert when trying to release before the cliff period", async function () {
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

    // advance time by one hour and mine a new block
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
    await vestingContract.connect(owner).release(vestingScheduleId, vested);

    // 5. Check that all vested tokens have been withdrawn and balance is now zero
    vested = await vestingContract.computeReleasableAmount(vestingScheduleId);
    expect(vested).to.equal(0);
  });
});
