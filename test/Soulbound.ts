import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('SoulBoundFactory', function () {
  async function deploySoulBoundFactoryContract() {
    // Contracts are deployed using the first signer/account by default

    // const owner = '0xB3910a37055df85E8EB04E12367e4DA8E24d1599';
    // let admins = ['0xEb6CD8AB0E374f3D84a4A8006dbd90b9966A4563'];

    const FACTORY_MANAGER = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes('FACTORY_MANAGER')
    );

    const [owner, otherAccount] = await ethers.getSigners();
    let admins = [otherAccount.address, owner.address];

    const SoulBoundFactoryContract = await ethers.getContractFactory(
      'SoulBoundFactory'
    );

    const soulBoundFactory = await SoulBoundFactoryContract.deploy(
      owner.address,
      admins
    );

    await soulBoundFactory.deployed();

    return {
      soulBoundFactory,
      owner,
      otherAccount,
      FACTORY_MANAGER,
    };
  }

  describe('SoulBoundFactory', function () {
    it('soulBoundFactory should be the right owner', async function () {
      const { soulBoundFactory, owner, otherAccount } = await loadFixture(
        deploySoulBoundFactoryContract
      );
      expect(await soulBoundFactory.owner()).to.equal(owner.address);
    });

    it('soulBoundFactory should be the right admins', async function () {
      const { soulBoundFactory, owner, otherAccount, FACTORY_MANAGER } =
        await loadFixture(deploySoulBoundFactoryContract);

      expect(
        await soulBoundFactory.hasRole(
          soulBoundFactory.DEFAULT_ADMIN_ROLE(),
          owner.address
        )
      ).to.equal(true);

      expect(
        await soulBoundFactory.hasRole(FACTORY_MANAGER, otherAccount.address)
      ).to.equal(true);
    });

    it('soulBoundFactory should deploy soulboundNft', async function () {
      const { soulBoundFactory, owner, otherAccount, FACTORY_MANAGER } =
        await loadFixture(deploySoulBoundFactoryContract);

      console.log({
        // soulBoundFactory: soulBoundFactory,
        owner: owner,
        otherAccount: otherAccount,
        FACTORY_MANAGER: FACTORY_MANAGER,
      });

      const txn = await soulBoundFactory.createSoulBoundContract('TEST', 'TST');
      console.log({ txn: txn });

      const soulboundNft = await txn.wait();
      console.log({ soulboundNft: soulboundNft });

      const event = soulboundNft.events?.find(
        (event) => event.event === 'SoulBoundContractCreated'
      );
      console.log({ event: event });

      const soulnft = event?.args;
      console.log({ soulnft: soulnft });

      await expect(soulBoundFactory.createSoulBoundContract('TEST1', 'TST1'))
        .to.emit(soulBoundFactory, 'SoulBoundContractCreated')
        .withArgs(owner.address);
    });
  });
});
