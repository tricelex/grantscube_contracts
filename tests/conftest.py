import pytest
import web3


@pytest.fixture(scope="session")
def owner(accounts):
    return accounts[0]


@pytest.fixture(scope="session")
def receiver(accounts):
    return accounts[1]


@pytest.fixture(scope="session")
def nft(owner, project):
    return owner.deploy(project.NFT)


@pytest.fixture(scope="session")
def hello(owner, project):
    return owner.deploy(project.hello)


@pytest.fixture(scope="session")
def grantscubenft(owner, project):
    return owner.deploy(project.GrantsCubeNFT, 'TEST1', 'TST1', 'GrantsCube', False, True, owner)


@pytest.fixture(scope="session")
def grantscubenft_factory(owner, project, receiver):
    return owner.deploy(project.GrantsCubeNFTFactory, owner, [owner, receiver])


@pytest.fixture(scope="session")
def factory_manager():
    factory_text = 'FACTORY_MANAGER'
    factory_text = factory_text.encode('utf-8')
    return web3.Web3.keccak(factory_text)


# string memory name_,
# string memory symbol_,
# string memory organization_,
# bool transferable_,
# bool mintable_,
# address ownerOfToken
# const FACTORY_MANAGER = ethers.utils.keccak256(
#       ethers.utils.toUtf8Bytes('FACTORY_MANAGER')
#     );
