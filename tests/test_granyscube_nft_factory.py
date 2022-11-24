import ape


def test_grantscube_nft_factory_has_owner(grantscubenft_factory, owner):
    assert grantscubenft_factory.owner() == owner.address


def test_grantscube_nft_factory_has_right_admins(grantscubenft_factory, owner, receiver, factory_manager):
    print(
        {
            'grantscubenft_factory': grantscubenft_factory,
            'owner': owner,
            'receiver': receiver,
            'factory_manager': factory_manager,
        }
    )
    assert grantscubenft_factory.hasRole(factory_manager, owner.address)
    assert grantscubenft_factory.hasRole(factory_manager, receiver.address)


def test_granscube_nft_factory_can_create_nft(grantscubenft_factory, owner):
    grantscubenft_factory.createGrantsCubeNFTContract(
        'TEST2', 'TST2', 'GrantsCube', False, True, owner.address, sender=owner
    )
    grantscubenft_factory.createGrantsCubeNFTContract(
        'TEST3', 'TST3', 'GrantsCube', False, True, owner.address, sender=owner
    )
    print(
        {
            'symbol_by_index': grantscubenft_factory.getGrantsCubeNFTSymbolByIndex(0),
            'length': grantscubenft_factory.getGrantsCubeNFTSymbolsArrayLength,
            'add_by_symbol': grantscubenft_factory.getGrantsCubeNFTAddressBySymbol('TST2'),
            'deployes': grantscubenft_factory.getDeployedGrantsCubeContracts,
        }
    )
    assert grantscubenft_factory.getGrantsCubeNFTSymbolByIndex(0) == 'TST2'
    assert grantscubenft_factory.getGrantsCubeNFTAddressBySymbol('TST2') == 'TST2'