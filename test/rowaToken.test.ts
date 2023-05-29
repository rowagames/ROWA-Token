import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber, Contract, Signer } from "ethers";

describe("RowaToken", () => {
  let RowaToken: any,
    rowaToken: Contract,
    VestingContract: any,
    vestingContract: Contract,
    owner: Signer,
    addr1: Signer,
    addr2: Signer;

  const NAME = "ROWA Token";
  const SYMBOL = "ROWA";
  const DECIMALS = 5;
  const INITIAL_SUPPLY = BigNumber.from("1000000000").mul(
    BigNumber.from(10).pow(DECIMALS)
  );

  beforeEach(async () => {
    // Get the ContractFactory and Signers here
    RowaToken = await ethers.getContractFactory("RowaToken");
    [owner, addr1, addr2] = await ethers.getSigners();

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

  describe("Deployment", () => {
    it("Should set the right owner", async () => {
      expect(await rowaToken.owner()).to.equal(await owner.getAddress());
    });

    it("Should set the right token name and symbol", async () => {
      expect(await rowaToken.name()).to.equal(NAME);
      expect(await rowaToken.symbol()).to.equal(SYMBOL);
    });

    it("Should set the right token decimals", async () => {
      expect(await rowaToken.decimals()).to.equal(DECIMALS);
    });

    it("Should not mint the initial supply to the owner on deploy", async () => {
      expect(await rowaToken.totalSupply()).to.equal(0);
      expect(await rowaToken.balanceOf(await owner.getAddress())).to.equal(0);
    });

    it("Should not start in paused state", async () => {
      expect(await rowaToken.paused()).to.equal(false);
    });

    it("Should not allow non-owner to pause the contract", async () => {
      await expect(rowaToken.connect(addr1).pause()).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });

    it("Should not allow non-owner to unpause the contract", async () => {
      await rowaToken.pause();
      await expect(rowaToken.connect(addr1).unpause()).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });

    it("Should not allow non-owner to snapshot the contract", async () => {
      await expect(rowaToken.connect(addr1).snapshot()).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });

    it("Should emit ContractPaused event when paused", async () => {
      await expect(rowaToken.pause()).to.emit(rowaToken, "ContractPaused");
    });

    it("Should emit ContractUnpaused event when unpaused", async () => {
      await rowaToken.pause();
      await expect(rowaToken.unpause()).to.emit(rowaToken, "ContractUnpaused");
    });

    it("Owner should have 0 balance after vesting started", async () => {
      await rowaToken.startVesting(vestingContract.address);
      let addr1Address = await addr1.getAddress();
      expect(await rowaToken.balanceOf(addr1Address)).to.equal(0);
      expect(await rowaToken.vestingContract.call()).to.equal(
        vestingContract.address
      );
    });

    it("Should not allow transfer when contract is paused", async () => {
      await rowaToken.startVesting(vestingContract.address);
      let addr1Address = await addr1.getAddress();
      await rowaToken.pause();
      await expect(
        rowaToken.connect(addr1).transfer(addr1Address, 10)
      ).to.be.revertedWith("ERC20Pausable: token transfer while paused");
    });
  });

  describe("Snapshot functionality", () => {
    it("Should create a snapshot", async () => {
      await rowaToken.startVesting(vestingContract.address);
      await rowaToken.snapshot();
      expect(await rowaToken.balanceOfAt(vestingContract.address, 1)).to.equal(
        INITIAL_SUPPLY
      );
    });

    it("Should be the supply of the snapshot equal to the initial supply", async () => {
      await rowaToken.startVesting(vestingContract.address);
      await rowaToken.snapshot();
      expect(await rowaToken.totalSupplyAt(1)).to.equal(INITIAL_SUPPLY);
    });

    it("Should emit SnapshotCreated event when snapshot created", async () => {
      await expect(rowaToken.snapshot()).to.emit(rowaToken, "SnapshotCreated");
    });
  });

  describe("ERC20 Transfer functionality", () => {
    it("Should allow owner to transfer tokens after vesting started with release", async () => {
      await rowaToken.startVesting(vestingContract.address);
      let addr1Address = await addr1.getAddress();
      await rowaToken.pause();
      const amount = BigNumber.from(1000);

      await vestingContract
        .connect(owner)
        .createPublicSaleVesting(addr1Address, amount);

      const vestingScheduleId =
        await vestingContract.computeVestingScheduleIdForAddressAndIndex(
          addr1Address,
          0
        );

      vestingContract.release(vestingScheduleId, amount.div(4));
    });

    it("Should not allow transfer when contract is paused", async () => {
      await rowaToken.startVesting(vestingContract.address);
      let addr1Address = await addr1.getAddress();
      await rowaToken.pause();
      const amount = BigNumber.from(1000);

      await vestingContract
        .connect(owner)
        .createPublicSaleVesting(addr1Address, amount);

      const vestingScheduleId =
        await vestingContract.computeVestingScheduleIdForAddressAndIndex(
          addr1Address,
          0
        );

      await expect(
        vestingContract.release(vestingScheduleId, amount.div(4))
      ).to.be.revertedWith("ERC20Pausable: token transfer while paused");
    });

    it("Shoud decimals be 5", async () => {
      expect(await rowaToken.decimals()).to.equal(5);
    });

    it("Should be approve and transferFrom", async () => {
      await rowaToken.startVesting(vestingContract.address);
      let addr1Address = await addr1.getAddress();
      const amount = BigNumber.from(1000);

      await vestingContract
        .connect(owner)
        .createPublicSaleVesting(addr1Address, amount);

      const vestingScheduleId =
        await vestingContract.computeVestingScheduleIdForAddressAndIndex(
          addr1Address,
          0
        );

      await rowaToken
        .connect(addr1)
        .approve(vestingContract.address, amount.div(4));
      await vestingContract.release(vestingScheduleId, amount.div(4));
    });
  });

  describe("Vesting", () => {
    it("Should start vesting and transfer initial supply to vesting contract", async () => {
      await rowaToken.startVesting(vestingContract.address);

      expect(await rowaToken.vestingContract()).to.equal(
        vestingContract.address
      );
      expect(await rowaToken.balanceOf(vestingContract.address)).to.equal(
        INITIAL_SUPPLY
      );
      expect(await rowaToken.paused()).to.equal(false);
    });

    it("Should not start vesting if it has already started", async () => {
      await rowaToken.startVesting(vestingContract.address);

      await expect(
        rowaToken.startVesting(vestingContract.address)
      ).to.be.revertedWith("ROWAToken: vesting already started");
    });

    it("Should not start vesting if vesting contract address is zero", async () => {
      await expect(
        rowaToken.startVesting(ethers.constants.AddressZero)
      ).to.be.revertedWith("ROWAToken: vesting contract is the zero address");
    });

    it("Should emit VestingStarted event when vesting started", async () => {
      await expect(rowaToken.startVesting(vestingContract.address)).to.emit(
        rowaToken,
        "VestingStarted"
      );
    });

    it("Should not allow non-owner to start vesting", async () => {
      await expect(
        rowaToken.connect(addr1).startVesting(vestingContract.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should not allow non-owner to start vesting", async () => {
      await expect(
        rowaToken.connect(addr1).startVesting(vestingContract.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});
