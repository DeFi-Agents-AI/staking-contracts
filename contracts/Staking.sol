// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StakingContract {
    using SafeERC20 for IERC20;

    struct Pool {
        string name;
        uint256 minimumAmount;
        uint256 duration;
        uint8 multiplier;
        bool exists;
    }

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 duration;
        uint8 multiplier;
        uint256 withdrawnTime;
    }

    address public owner;
    IERC20 public immutable stakingToken;
    mapping(address => Stake[]) public stakes;
    mapping(uint256 => Pool) public pools;
    uint256[] public poolDurations;

    event PoolCreated(string name, uint256 duration, uint8 multiplier);
    event PoolUpdated(string name, uint256 duration, uint8 multiplier);
    event PoolDeleted(uint256 duration);
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 duration,
        uint8 multiplier,
        uint256 startTime,
        uint256 index
    );
    event Withdrawn(
        address indexed user,
        uint256 amount,
        uint256 withdrawnTime,
        uint256 index
    );
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    constructor(address _stakingToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
    }

    receive() external payable {}

    fallback() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "Invalid address");
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = stakingToken.balanceOf(address(this));
        stakingToken.safeTransfer(owner, balance);
    }

    function createPool(
        string memory _name,
        uint256 _minimumAmount,
        uint256 _duration,
        uint8 _multiplier
    ) external onlyOwner {
        require(!pools[_duration].exists, "Pool already exists");
        require(_multiplier > 0, "Multiplier must be greater than zero");

        pools[_duration] = Pool({
            name: _name,
            minimumAmount: _minimumAmount,
            duration: _duration,
            multiplier: _multiplier,
            exists: true
        });

        poolDurations.push(_duration);

        emit PoolCreated(_name, _duration, _multiplier);
    }

    function updatePool(
        uint256 _duration,
        string memory _name,
        uint256 _minimumAmount,
        uint8 _newMultiplier
    ) external onlyOwner {
        require(pools[_duration].exists, "Pool does not exist");
        require(_newMultiplier > 0, "Multiplier must be greater than zero");

        pools[_duration].name = _name;
        pools[_duration].minimumAmount = _minimumAmount;
        pools[_duration].multiplier = _newMultiplier;

        emit PoolUpdated(pools[_duration].name, _duration, _newMultiplier);
    }

    function deletePool(uint256 _duration) external onlyOwner {
        require(pools[_duration].exists, "Pool does not exist");

        delete pools[_duration];

        for (uint256 i = 0; i < poolDurations.length; i++) {
            if (poolDurations[i] == _duration) {
                poolDurations[i] = poolDurations[poolDurations.length - 1];
                poolDurations.pop();
                break;
            }
        }

        emit PoolDeleted(_duration);
    }

    function stake(uint256 _amount, uint256 _duration) external {
        require(pools[_duration].exists, "Invalid duration");
        require(
            _amount >= pools[_duration].minimumAmount,
            "Amount is less than minimum required"
        );

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        stakes[msg.sender].push(
            Stake({
                amount: _amount,
                startTime: block.timestamp,
                duration: _duration,
                multiplier: pools[_duration].multiplier,
                withdrawnTime: 0
            })
        );

        emit Staked(
            msg.sender,
            _amount,
            _duration,
            pools[_duration].multiplier,
            block.timestamp,
            stakes[msg.sender].length - 1
        );
    }

    function withdraw(uint256 _index) external {
        require(_index < stakes[msg.sender].length, "Invalid stake index");

        Stake storage userStake = stakes[msg.sender][_index];
        require(userStake.withdrawnTime == 0, "Already withdrawn");

        uint256 endTime = userStake.startTime + userStake.duration * 1 days;
        uint256 currentTime = block.timestamp;
        require(currentTime >= endTime, "Stake period not yet completed");

        stakingToken.safeTransfer(msg.sender, userStake.amount);

        userStake.withdrawnTime = currentTime;

        emit Withdrawn(msg.sender, userStake.amount, currentTime, _index);
    }

    function getStakeLength(address _user) external view returns (uint256) {
        return stakes[_user].length;
    }

    function getStake(address _user) external view returns (Stake[] memory) {
        return stakes[_user];
    }

    function getDurationLength() external view returns (uint256) {
        return poolDurations.length;
    }

    function getDurations() external view returns (uint256[] memory) {
        return poolDurations;
    }

    function getPool(uint256 _duration) external view returns (Pool memory) {
        require(pools[_duration].exists, "Invalid duration");
        return pools[_duration];
    }

    function getAllPools() external view returns (Pool[] memory) {
        Pool[] memory allPools = new Pool[](poolDurations.length);
        for (uint256 i = 0; i < poolDurations.length; i++) {
            allPools[i] = pools[poolDurations[i]];
        }
        return allPools;
    }
}
