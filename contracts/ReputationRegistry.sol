pragma solidity ^0.5.0;

// import "./UserRegistry.sol";

contract ReputationRegistry {
    //UserRegistry public userRegistry;

    int __amountMax = 5;
    int __amountMin = 0;//__amountMax * -1;
    int __maxReputationGiven = __amountMax * 2;
    int __minReputationGiven = __amountMin * 2;

    struct UserProfile {
        address owner;
        bytes32 userName;

        int cumulativeScore;
        uint noTxSent;
        uint noTxRcvd;

        uint index;

        mapping(address => int) givenReputation;
    }

    address[] private profileIndex;
    mapping (address => UserProfile) public profiles;

    event ErrorEvent( string message );
    event UserProfileCreated(
        bytes32 name,
        address indexed owner
    );
    event TransactionScoreChanged(
        address indexed sender,
        address indexed recipient,
        int newScore
    );
    event TransactionCountChanged(
        address indexed recipient,
        uint newScore);
    event TransactionAdded(
        address indexed sender,
        address indexed recipient,
        int grade,
        int recipientNewScore
    );
    event GenericTransactionAdded(
        address indexed sender,
        address indexed recipient,
        uint indexed timestamp,
        string transactionType,
        string message,
        string txHash,
        uint weiAmount
    );

    constructor(address userRegistryAddress) public {
        //userRegistry = UserRegistry(userRegistryAddress);
    }

    /**
     * =================================
     *
     *      SECTION:      MODIFIERS
     *
     * =================================
     */

    modifier userIsOwner(address claimedOwner, bytes32 userName) {
       // require(userRegistry.isOwner(claimedOwner, userName), "Sender does not own user account" );
        _;
    }
    modifier onlyOwnProfile() {
        //require(profiles[msg.sender].owner == msg.sender, "Sender does not own profile.");
        if(profiles[msg.sender].owner != msg.sender)
        {
            emit ErrorEvent("Sender does not own profile.");
            require(profiles[msg.sender].owner == msg.sender, "Sender does not own profile.");
        }
        _;
    }
    modifier onlyUnknownProfile(address profileID) {
        UserProfile storage maybeEmpty = profiles[profileID];
        //require(maybeEmpty.owner == address(0), "Profile cannot exist.");
        if(maybeEmpty.owner != address(0))
        {
            emit ErrorEvent("Profile cannot exist.");
            require(maybeEmpty.owner == address(0), "Profile cannot exist.");
        }
        _;
    }
    modifier onlyKnownProfile(address profileID) {
        UserProfile storage maybeEmpty = profiles[profileID];
        //require(maybeEmpty.owner != address(0), "Profile not found.");
        if(maybeEmpty.owner == address(0))
        {
            emit ErrorEvent("Profile not found.");
            require(maybeEmpty.owner != address(0), "Profile not found.");
        }
        _;
    }
    modifier onlyKnownSender() {
        UserProfile storage maybeEmpty = profiles[msg.sender];
        //require(maybeEmpty.owner != address(0), "Sender profile not found.");
        if(maybeEmpty.owner == address(0))
        {
            emit ErrorEvent("Sender profile not found.");
            require(maybeEmpty.owner != address(0), "Sender profile not found.");
        }
        _;
    }
    modifier onlyBy(address profileID) {
        //require(msg.sender == profileID, "Restricted access: only owner is allowed");
        if(msg.sender != profileID)
        {
            emit ErrorEvent("Restricted access: only owner is allowed");
            require(msg.sender == profileID, "Restricted access: only owner is allowed");
        }
        _;
    }

    /**
     * =================================
     *
     *      SECTION:      VIEWS
     *
     * =================================
     */

    function getNoTransactionsSent( address profileID ) public view
        returns(uint)
    {
        if (!hasProfile(profileID)) revert("profile not found");
        UserProfile storage userProfile = profiles[profileID];
        return userProfile.noTxSent;
    }

    function getNoTransactionsReceived( address profileID ) public view
        returns(uint)
    {
        if (!hasProfile(profileID)) revert("profile not found");
        UserProfile storage userProfile = profiles[profileID];
        return userProfile.noTxRcvd;
    }

    function getCumulativeScore( address profileID ) public view
        returns(int)
    {
        if (!hasProfile(profileID)) revert("profile not found");
        UserProfile storage userProfile = profiles[profileID];
        return userProfile.cumulativeScore;
    }

    // https://bitbucket.org/rhitchens2/soliditycrud
    function hasProfile(address userAddress) public view returns(bool)
    {
        if(profileIndex.length == 0) return false;
        return (profileIndex[profiles[userAddress].index] == userAddress);
    }

    // https://bitbucket.org/rhitchens2/soliditycrud
    function _getProfile(address userAddress)
        public
        view
        returns(
            address owner,
            bytes32 userName,
            int cumulativeScore,
            uint noTransactionsSent,
            uint noTransactionsReceived,
            uint index)
    {
        if (!hasProfile(userAddress)) revert("profile not found");
        return(
            profiles[userAddress].owner,
            profiles[userAddress].userName,
            profiles[userAddress].cumulativeScore,
            profiles[userAddress].noTxSent,
            profiles[userAddress].noTxRcvd,
            profiles[userAddress].index
        );
    }

    // https://bitbucket.org/rhitchens2/soliditycrud
    function _getUserAtIndex(uint index)
        public
        view
        returns (address)
    {
        return profileIndex[index];
    }

    // https://bitbucket.org/rhitchens2/soliditycrud
    function _getUserCount()
        public
        view
        returns (uint)
    {
        return profileIndex.length;
    }

    function _updateUserCumulativeScore(address senderAddress, address recipientAddress, int newScore)
        private
        returns (bool)
    {
        if ( !hasProfile(recipientAddress) ) _revert("recipient not found");
        if ( !hasProfile(senderAddress) ) _revert("sender not found");
        profiles[recipientAddress].cumulativeScore = newScore;
        profiles[senderAddress].givenReputation[recipientAddress] = newScore;
        emit TransactionScoreChanged(senderAddress, recipientAddress, newScore);
        return true;
    }

    function _updateUserNoTransactionsSent(address userAddress)
        private
        returns (bool)
    {
        if ( !hasProfile(userAddress) ) _revert("profile not found");
        //profiles[userAddress].noTransactions += 1;
        uint noT = profiles[userAddress].noTxSent + 1;
        profiles[userAddress].noTxSent = noT;
        emit TransactionCountChanged(userAddress, noT);
        return true;
    }

    function _updateUserNoTransactionsReceived(address userAddress)
        private
        returns (bool)
    {
        if ( !hasProfile(userAddress) ) _revert("profile not found");
        //profiles[userAddress].noTransactions += 1;
        uint noT = profiles[userAddress].noTxRcvd + 1;
        profiles[userAddress].noTxRcvd = noT;
        emit TransactionCountChanged(userAddress, noT);
        return true;
    }

    /**
     * =================================
     *
     *      SECTION:      FUNCTIONS
     *
     * =================================
     */

    function abs(int x) private pure returns(int)
    {
        if ( x > 0 ) return x;
        if ( x < 0 ) return x * -1;
        return 0;
    }

    // https://bitbucket.org/rhitchens2/soliditycrud
    function _insertProfile(
        address _userAddress,
        bytes32 _userName,
        int _cumulativeScore,
        uint _noTransactionsSent,
        uint _noTransactionsRcvd
    ) private returns(uint index)
    {
        if ( hasProfile(_userAddress) ) _revert("profile already exists");

        profiles[_userAddress] = UserProfile({
            owner: _userAddress,
            userName: _userName,
            cumulativeScore: _cumulativeScore,
            noTxSent: _noTransactionsSent,
            noTxRcvd: _noTransactionsRcvd,
            index: profileIndex.push(_userAddress)-1
        });

        _createProfile(_userName, _userAddress);
        return profileIndex.length-1;
    }

    function createProfile( bytes32 userName ) public
    {
        _insertProfile(msg.sender, userName, 0, 0, 0);
    }

    function applyRatingFormula(address sender, address contrahent, int amount)
        private view
        returns (int givenReputation, int recipientNewScore)
    {
        int _recipientNewScore = profiles[contrahent].cumulativeScore + amount;
        int _givenReputation = profiles[sender].givenReputation[contrahent] + amount;
        if ( _givenReputation > ( __maxReputationGiven ) )
        {
            _givenReputation = __maxReputationGiven;
        }
        if ( _givenReputation < __minReputationGiven )
        {
            _givenReputation = __minReputationGiven;
        }
        return (_givenReputation, _recipientNewScore);
    }

    function addTransaction(address contrahent, int amount) public
        //onlyKnownProfile(msg.sender)
        //onlyKnownProfile(contrahent)
    {
        if ( !hasProfile(msg.sender)) {
            _revert("sender profile unknown");
        }
        if ( !hasProfile(contrahent)) {
            _revert("contrahent profile unknown");
        }

        if ( amount > __amountMax && amount < __amountMin ) {
            _revert("Rating must be an int between __amountMin and __amountMax");
        }

        if ( msg.sender == contrahent ) {
            _revert("Cannot rate yourself");
        }

        // sanity check
        //require(amount <= __amountMax && amount >= __amountMin, "Rating must be an int between __amountMin and __amountMax");
        //require(msg.sender != contrahent, "Cannot rate yourself");

        // TODO: apply rating formula magic
        (int givenReputation, int recipientNewScore) = applyRatingFormula(msg.sender, contrahent, amount);

        _updateUserCumulativeScore(msg.sender, contrahent, recipientNewScore);

        _updateUserNoTransactionsSent(msg.sender);
        _updateUserNoTransactionsReceived(contrahent);
        //uint newNoTransactions = profiles[msg.sender].noTransactions + 1;
        //uint recipientNewNoTransactions = profiles[contrahent].noTransactions + 1;

        profiles[contrahent].cumulativeScore = recipientNewScore;
        //profiles[contrahent].noTransactions = recipientNewNoTransactions;
        //profiles[msg.sender].noTransactions = newNoTransactions;
        profiles[msg.sender].givenReputation[contrahent] = givenReputation;
        _sendTransaction(msg.sender, contrahent, amount, recipientNewScore);
    }

    function addGenericTransaction(
        address contrahent,
        uint weiAmount,
        uint timestamp,
        string memory txHash,
        string memory message,
        string memory transactionType
    ) public
    {
        _sendGenericTransaction(msg.sender, contrahent, weiAmount, timestamp, txHash, message, transactionType);
    }

    /**
     * =================================
     *
     *      SECTION:    EVENT EMITTERS
     *
     * =================================
     */

    function _createProfile (bytes32 userName, address owner) private
    {
        emit UserProfileCreated(userName, owner);
    }

    function _sendTransaction (address sender, address recipient, int grading, int recipientNewScore) private
    {
        emit TransactionAdded(sender, recipient, grading, recipientNewScore);
    }

    function _sendGenericTransaction(
        address sender,
        address recipient,
        uint amountInWei,
        uint timestamp,
        string memory txHash,
        string memory message,
        string memory transactionType) private
    {
        emit GenericTransactionAdded(sender, recipient, timestamp, transactionType, message, txHash, amountInWei);
    }

    function _revert(string memory message) public
    {
        emit ErrorEvent(message);
        revert(message);
    }
}