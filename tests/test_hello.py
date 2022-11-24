import ape


def test_erc165(hello):
    # ERC165 interface ID of ERC165
    assert hello.greet() == "Hello World"
