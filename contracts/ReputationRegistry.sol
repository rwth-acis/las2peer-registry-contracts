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
        uint noTransactions;

        mapping(address => int) givenReputation;
    }

    mapping (address => UserProfile) public profiles;

    event UserProfileCreated( bytes32 name, address owner);
    event TransactionAdded( address sender, address subject, int grade, int subjectNewScore );

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

    modifier userIsOwner(address claimedOwner, bytes32 username) {
       // require(userRegistry.isOwner(claimedOwner, username), "Sender does not own user account" );
        _;
    }
    modifier onlyOwnProfile() {
        require(profiles[msg.sender].owner == msg.sender, "Sender does not own profile.");
        _;
    }
    modifier onlyUnknownProfile(address profileID) {
        UserProfile storage maybeEmpty = profiles[profileID];
        require(maybeEmpty.owner == address(0), "Profile cannot exist.");
        _;
    }
    modifier onlyKnownProfile(address profileID) {
        UserProfile storage maybeEmpty = profiles[profileID];
        require(maybeEmpty.owner != address(0), "Profile not found.");
        _;
    }
    modifier onlyKnownSender() {
        UserProfile storage maybeEmpty = profiles[msg.sender];
        require(maybeEmpty.owner != address(0), "Sender profile not found.");
        _;
    }
    modifier onlyBy(address profileID) {
        require(msg.sender == profileID, "Restricted access: only owner is allowed");
        _;
    }

    /**
     * =================================
     *
     *      SECTION:      VIEWS
     *
     * =================================
     */

    function getNoTransactions( address profileID ) public view
        onlyKnownProfile(profileID)
        returns(uint)
    {
        UserProfile storage userProfile = profiles[profileID];
        return userProfile.noTransactions;
    }

    function getCumulativeScore( address profileID ) public view
        onlyKnownProfile(profileID)
        returns(int)
    {
        UserProfile storage userProfile = profiles[profileID];
        return userProfile.cumulativeScore;
    }

    /**
     * =================================
     *
     *      SECTION:      FUNCTIONS
     *
     * =================================
     */

    function createProfile( bytes32 username ) public
        //userIsOwner( msg.sender, username )
        onlyUnknownProfile(msg.sender)
        //returns (int)
    {
        profiles[msg.sender] = UserProfile(
            msg.sender,
            username,
            0,
            0
        );
        //profiles[msg.sender].ownerAgentID = userRegistry.users[username].agentId;
        _createProfile(username, msg.sender);
        //return username;
        //return 1;
    }

    function abs(int x) private pure returns(int)
    {
        if ( x > 0 ) return x;
        if ( x < 0 ) return x * -1;
        return 0;
    }


    function addTransaction(address contrahent, int amount) public
        onlyKnownProfile(msg.sender)
        onlyKnownProfile(contrahent)
    {
        // sanity check
        require(amount <= __amountMax && amount >= __amountMin, "Rating must be an int between __amountMin and __amountMax");

        // cannot rate self
        require(msg.sender != contrahent, "Cannot rate yourself");

        // TODO: apply rating formula magic
        int subjectNewScore = profiles[contrahent].cumulativeScore + amount;
        int givenReputation = profiles[msg.sender].givenReputation[contrahent] + amount;
        if ( givenReputation > ( __maxReputationGiven ) )
        {
            givenReputation = __maxReputationGiven;
        }
        if ( givenReputation < __minReputationGiven )
        {
            givenReputation = __minReputationGiven;
        }
        uint newNoTransactions = profiles[msg.sender].noTransactions + 1;
        uint subjectNewNoTransactions = profiles[contrahent].noTransactions + 1;

        profiles[contrahent].cumulativeScore = subjectNewScore;
        profiles[contrahent].noTransactions = subjectNewNoTransactions;
        profiles[msg.sender].noTransactions = newNoTransactions;
        profiles[msg.sender].givenReputation[contrahent] = givenReputation;
        _sendTransaction(msg.sender, contrahent, amount, subjectNewScore);
    }

    /**
     * =================================
     *
     *      SECTION:    EVENT EMITTERS
     *
     * =================================
     */

    function _createProfile (bytes32 username, address owner) private
    {
        emit UserProfileCreated(username, owner);
    }

    function _sendTransaction (address sender, address subject, int grading, int subjectNewScore) private
    {
        emit TransactionAdded(sender, subject, grading, subjectNewScore);
    }
}