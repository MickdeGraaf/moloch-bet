pragma solidity >=0.4.21 <0.6.0;
pragma experimental ABIEncoderV2;

import "./moloch/Moloch.sol";
import "./MarketToken.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

// TODO FIX BROKEN PROPOSAL RETRIEVAL FROM moloch

contract MolochBet {
    using SafeMath for uint256;

    mapping(uint256 => mapping(address => Market)) public proposalMarkets;

    struct Market {
        MarketToken yesToken;
        MarketToken noToken;
        uint256 totalYes;
        uint256 totalNo;
    }

    struct Proposal {
        uint256 startingPeriod; // the period in which voting can start for this proposal
        bool processed; // true only if the proposal has been processed
        bool didPass; // true only if the proposal passed
        bool aborted; // true only if applicant calls "abort" fn before end of voting period
    }

    Moloch public moloch;

    modifier onlyQueuedProposals(uint256 _proposal) {
        require(_proposal < moloch.getProposalQueueLength(), "PROPOSAL_DOES_NOT_EXIST");
        Proposal memory proposal = Moloch.Proposal(moloch.proposalQueue(_proposal));
        require(moloch.getCurrentPeriod() < proposal.startingPeriod, "PROPOSAL_ALREADY_STARTED");
        _;
    }

    // EVENTS
    // TODO market created event
    // TODO yes bought
    // TODO no bought
    // TODO settled


    constructor(address _moloch) public {
        moloch = Moloch(moloch);
    }

    function buyYes(uint256 _proposal, address _token, uint256 _amount) onlyQueuedProposals(_proposal) external {
        pullTokens(_token, msg.sender, _amount);
        Market storage market = createOrGetMarket(_proposal, _token);
        market.yesToken.mint(msg.sender, _amount);
        market.totalYes = market.totalYes.add(_amount);
    }

    function buyNo(uint256 _proposal, address _token, uint256 _amount) onlyQueuedProposals(_proposal) external {
        pullTokens(_token, msg.sender, _amount);
        Market storage market = createOrGetMarket(_proposal, _token);
        market.noToken.mint(msg.sender, _amount);
        market.totalNo = market.totalNo.add(_amount);
    }

    function settleYes(uint256 _proposal, address _market, uint256 _amount) external {
        Market storage market = createOrGetMarket(_proposal, _market);
        market.yesToken.burn(msg.sender, _amount);

        Moloch.Proposal memory proposal = moloch.proposalQueue(_proposal);
        require(proposal.didPass, "PROPOSAL_DID_NOT_PASS");

        uint256 payoutAmount = (market.totalYes + market.totalNo) * _amount / market.totalYes;
        IERC20(_market).transfer(msg.sender, payoutAmount);
    }
    
    function settleNo(uint256 _proposal, address _market, uint256 _amount) external {
        Market storage market = createOrGetMarket(_proposal, _market);
        market.noToken.burn(msg.sender, _amount);

        Moloch.Proposal memory proposal = moloch.proposalQueue(_proposal);
        require(proposal.processed && !proposal.didPass, "PROPOSAL_PASSED");

        uint256 payoutAmount = (market.totalYes + market.totalNo) * _amount / market.totalNo;
        IERC20(_market).transfer(msg.sender, payoutAmount);
    }

    function settleAborted(uint256 _proposal, address _market, uint256 _amount, bool _yes) external {
        Market storage market = createOrGetMarket(_proposal, _market);
        Moloch.Proposal memory proposal = moloch.proposalQueue(_proposal);
        require(proposal.aborted, "PROPOSAL_NOT_ABORTED");
        if(_yes) {
            market.yesToken.burn(msg.sender, _amount);
        } else {
            market.noToken.burn(msg.sender, _amount);
        }
        IERC20(_market).transfer(msg.sender, _amount);
    }

    function marketExists(uint256 _proposal, address _market) public view returns(bool) {
        return address(proposalMarkets[_proposal][_market].yesToken) != address(0);
    }

    function createMarket(uint256 _proposal, address _market) internal {
        // Only create market if it does not already exist
        // TODO should only be able to create market if a proposal exists in moloch and is not processed yet
        if(marketExists(_proposal, _market)) {
            return;
        }

        proposalMarkets[_proposal][_market] = Market({
            yesToken: new MarketToken("", "", new address[](0)),
            noToken: new MarketToken("", "", new address[](0)),
            totalYes: 0,
            totalNo: 0
        });
    }

    function createOrGetMarket(uint256 _proposal, address _market) internal returns(Market storage) {
        if(!marketExists(_proposal, _market)) {
            createMarket(_proposal, _market);
        }
        return proposalMarkets[_proposal][_market];
    }

    function pullTokens(address _token, address _from, uint256 _amount) internal {
        require(IERC20(_token).transferFrom(_from, address(this), _amount), "TOKEN_PULL_FAILED");
    }

}