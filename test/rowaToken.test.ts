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
  });
});
