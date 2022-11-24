import ape

def test_init(grantscubenft, owner):
    # print('grantscubenft', grantscubenft)
    # print('owner', owner)
    assert grantscubenft.balanceOf(owner) == 0
    with ape.reverts():
        assert grantscubenft.ownerOf(0)
    
def test_total_supply(grantscubenft, owner):
    assert grantscubenft.totalSupply() == 0
    # grantscubenft.mint(owner, sender=owner)
    # assert grantscubenft.totalSupply() == 1
