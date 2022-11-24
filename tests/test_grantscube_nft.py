import ape

def test_init(grantscubenft, owner):
    # print('grantscubenft', grantscubenft)
    # print('owner', owner)
    assert grantscubenft.balanceOf(owner) == 0
    with ape.reverts():
        assert grantscubenft.ownerOf(0)
    
def test_total_supply(grantscubenft, owner):
    assert grantscubenft.totalSupply() == 0
    grantscubenft.mint(owner, 'chuckz', sender=owner)
    uri = grantscubenft.tokenURI(1)
    print('uri', uri)
    assert grantscubenft.totalSupply() == 1
    # assert 77 == 779
    
def test_transfer(grantscubenft, owner, receiver):
    assert grantscubenft.balanceOf(owner) == 0
    assert grantscubenft.balanceOf(receiver) == 0
    grantscubenft.mint(owner, 'chuckz', sender=owner)
    assert grantscubenft.balanceOf(owner) == 1
    assert grantscubenft.ownerOf(1) == owner.address
    grantscubenft.transferFrom(owner, receiver, 1, sender=owner)
    assert grantscubenft.balanceOf(owner) == 0
    assert grantscubenft.balanceOf(receiver) == 1
    assert grantscubenft.ownerOf(1) == receiver.address
    grantscubenft.transferFrom(receiver, owner, 1, sender=receiver)
    assert grantscubenft.balanceOf(receiver) == 0
    assert grantscubenft.balanceOf(owner) == 1
    assert grantscubenft.ownerOf(1) == owner.address