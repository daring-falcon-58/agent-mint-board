// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title Agent Mint Board
/// @notice A board of verified free mints, gated on Binance Agent ID.
/// @dev Only addresses holding an Agent ID (SPACE ID Agent ID, ERC-721,
///      0x60b9262456de011f7d15a54cdd8c48baaa8b022f on BNB Chain) can claim a
///      slot or propose a mint. The curator (deployer) lists mints only after
///      verifying them off-chain: contract source verified, mint price 0,
///      no token approval required. No funds ever move through this contract.
///      Owner permissions (disclosed): curator can register / deactivate
///      mints and transfer curatorship. Nothing else is privileged.
interface IAgentID {
    function balanceOf(address owner) external view returns (uint256);
}

contract AgentMintBoard {
    IAgentID public immutable agentId;
    address public curator;

    struct Mint {
        address mintContract;
        string name;
        string infoURI;
        uint256 maxClaims;
        uint256 claims;
        bool active;
    }

    Mint[] public mints;
    mapping(uint256 => mapping(address => bool)) public hasClaimed;

    event MintRegistered(uint256 indexed mintId, address indexed mintContract, string name);
    event MintProposed(address indexed proposer, address indexed mintContract, string name);
    event Claimed(uint256 indexed mintId, address indexed claimer);
    event MintDeactivated(uint256 indexed mintId);
    event CuratorTransferred(address indexed oldCurator, address indexed newCurator);

    modifier onlyAgent() {
        require(agentId.balanceOf(msg.sender) > 0, "Agent ID required");
        _;
    }

    modifier onlyCurator() {
        require(msg.sender == curator, "curator only");
        _;
    }

    constructor(address _agentId, address _curator) {
        require(_agentId != address(0), "zero agent id");
        require(_curator != address(0), "zero curator");
        agentId = IAgentID(_agentId);
        curator = _curator;
    }

    /// @notice Curator lists a mint AFTER off-chain verification (free, verified source).
    function registerMint(
        address mintContract,
        string calldata name,
        string calldata infoURI,
        uint256 maxClaims
    ) external onlyCurator returns (uint256 mintId) {
        require(mintContract != address(0), "zero mint contract");
        require(bytes(name).length > 0, "empty name");
        require(maxClaims > 0, "zero maxClaims");
        mintId = mints.length;
        mints.push(
            Mint({
                mintContract: mintContract,
                name: name,
                infoURI: infoURI,
                maxClaims: maxClaims,
                claims: 0,
                active: true
            })
        );
        emit MintRegistered(mintId, mintContract, name);
    }

    /// @notice Any Agent ID holder can propose a mint for the curator to verify.
    function proposeMint(address mintContract, string calldata name) external onlyAgent {
        require(mintContract != address(0), "zero mint contract");
        require(bytes(name).length > 0, "empty name");
        emit MintProposed(msg.sender, mintContract, name);
    }

    /// @notice Agent ID holders claim one slot per mint. No funds move; the
    ///  claim is an on-chain record that the holder verified the mint.
    function claim(uint256 mintId) external onlyAgent {
        require(mintId < mints.length, "no such mint");
        Mint storage m = mints[mintId];
        require(m.active, "mint inactive");
        require(!hasClaimed[mintId][msg.sender], "already claimed");
        require(m.claims < m.maxClaims, "claims full");
        hasClaimed[mintId][msg.sender] = true;
        m.claims += 1;
        emit Claimed(mintId, msg.sender);
    }

    function deactivate(uint256 mintId) external onlyCurator {
        require(mintId < mints.length, "no such mint");
        mints[mintId].active = false;
        emit MintDeactivated(mintId);
    }

    function transferCurator(address newCurator) external onlyCurator {
        require(newCurator != address(0), "zero curator");
        emit CuratorTransferred(curator, newCurator);
        curator = newCurator;
    }

    function mintCount() external view returns (uint256) {
        return mints.length;
    }

    function getMint(uint256 mintId) external view returns (Mint memory) {
        require(mintId < mints.length, "no such mint");
        return mints[mintId];
    }
}
