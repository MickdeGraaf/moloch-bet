pragma solidity >=0.4.21 <0.6.0;

import "openzeppelin-solidity/contracts/token/ERC777/ERC777.sol";

contract MarketToken is ERC777 {

    address public molochBet;

    modifier onlyMolochBet() {
        require(msg.sender == molochBet, "MSG_SENDER_NOT_MOLOCH_BET");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators
    ) public ERC777(name, symbol, defaultOperators) {
        molochBet = msg.sender;
    }

    function mint(address _receiver, uint256 _amount) external onlyMolochBet {
        super._mint(address(this), _receiver, _amount, bytes(""), bytes(""));
    }
    function burn(address _from, uint256 _amount) external onlyMolochBet {
        super._burn(address(this), _from, _amount, bytes(""), bytes(""));
    }
}