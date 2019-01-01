pragma solidity ^0.4.23;

contract FSCorpBank {
    string public name = "FSCorpBank";

    // admins can add or remove admins and accountants
    struct Admin
    {
        address addr;
        bool approved;
        address adder;
        address remover;
    }

    // accountants can withdraw money
    struct Accountant
    {
        address addr;
        bool approved;
        address adder;
        uint256 withdrawLimit;

        uint256 lastWithdrawTime;
        uint256 usedWithdrawLimit;
    }

    // admins can add or remove admin and accountants
    // at least two of them must approve to add/remove admin and add accountant
    // any admin can remove accountant
    mapping(address => Admin) public admins_;
    address[] public listOfAdmins_;
    uint256 public approvedAdmins_;

    mapping(address => Accountant) public accountants_;
    address[] public listOfAccountants_;

    // EVENTS:
    event onNewAdmin
    (
        address indexed adminAddress,
        address adder,
        address approver
    );

    event onRemoveAdmin
    (
        address indexed adminAddress,
        address remover,
        address approver
    );

    event onNewAccountant
    (
        address indexed accountantAddress,
        address adder,
        address approver
    );

    event onRemoveAccountant
    (
        address indexed accountantAddress,
        address remover
    );

    event onAssignWithdrawLimit
    (
        address indexed accountantAddress,
        address assigner,
        uint256 withdrawLimit
    );

    event onDeposit
    (
        address indexed sender,
        uint256 amount
    );

    event onWithdraw
    (
        address indexed accountant,
        uint256 amount
    );

    // constructor
    constructor(uint256[] _admins)
        public
    {
        require(_admins.length >= 3, "Need at least three admins");

        uint _length = _admins.length;
        for (uint i = 0; i < _length; i++)
        {
            admins_[address(_admins[i])] = Admin(address(_admins[i]), true, 0x0, 0x0);
            listOfAdmins_.push(address(_admins[i]));
        }

        approvedAdmins_ = _length;
    }

    function addNewAdmin(address _newAdmin)
        public
    {
        require(admins_[msg.sender].approved == true, "Only approved admin can add new admin");
        require(admins_[_newAdmin].approved == false, "This admin was already approved");
        require(admins_[_newAdmin].adder != msg.sender, "Can't add the same admin twice");

        if (admins_[_newAdmin].addr == 0)
        {
            // not in the database, add to it
            admins_[_newAdmin] = Admin(_newAdmin, false, msg.sender, 0x0);
            listOfAdmins_.push(_newAdmin);
        }
        else if (admins_[admins_[_newAdmin].adder].approved == false)
        {
            // the original adder of the new admin is no longer approved
            // become the new adder
            admins_[_newAdmin].adder = msg.sender;
        }
        else if (admins_[_newAdmin].adder != 0x0)
        {
            // two different admins approved, elevate
            admins_[_newAdmin].approved = true;
            address _adder = admins_[_newAdmin].adder;
            admins_[_newAdmin].adder = 0x0;
            approvedAdmins_ ++;

            emit onNewAdmin(_newAdmin, _adder, msg.sender);
        }
    }

    function cancelAddNewAdmin(address _newAdmin)
        public
    {
        require(admins_[msg.sender].approved == true, "Only approved admin can add new admin");
        require(admins_[_newAdmin].approved == false, "This admin was already approved");
        require(admins_[_newAdmin].adder == msg.sender, "Only adder can cancel");

        admins_[_newAdmin].adder = 0x0;
    }

    function removeAdmin(address _adminToRemove)
        public
    {
        require(admins_[msg.sender].approved == true, "Only approved admin can remove admin");
        require(admins_[_adminToRemove].approved == true, "Can only remove approved admins");
        require(admins_[_adminToRemove].remover != msg.sender, "Can't remove the same admin twice");

        if (admins_[admins_[_adminToRemove].remover].approved == false)
        {
            admins_[_adminToRemove].remover = msg.sender;
        }
        else if (admins_[_adminToRemove].remover != 0x0)
        {
            require(approvedAdmins_ > 3, "Need to maintain more than 3 admins");
            
            // two different admins approved the removal
            admins_[_adminToRemove].approved = false;
            address _remover = admins_[_adminToRemove].remover;
            admins_[_adminToRemove].remover = 0x0;
            approvedAdmins_ --;

            emit onRemoveAdmin(_adminToRemove, _remover, msg.sender);
        }
    }

    function cancelRemoveAdmin(address _adminToRemove)
        public
    {
        require(admins_[msg.sender].approved == true, "Only approved admin can remove admin");
        require(admins_[_adminToRemove].approved == true, "Can only remove approved admins");
        require(admins_[_adminToRemove].remover == msg.sender, "Only remover can cancel");

        admins_[_adminToRemove].remover = 0x0;
    }

    function addNewAccountant(address _newAccountant)
        public
    {
        require(admins_[msg.sender].approved == true, "Only approved admin can add new accountant");
        require(accountants_[_newAccountant].approved == false, "This accountant was already approved");
        require(accountants_[_newAccountant].adder != msg.sender, "Can't add the same accountant twice");

        if (accountants_[_newAccountant].addr == 0)
        {
            // not in the database, add to it
            accountants_[_newAccountant] = Accountant(_newAccountant, false, msg.sender, 0, 0, 0);
            listOfAccountants_.push(_newAccountant);
        }
        else if (admins_[accountants_[_newAccountant].adder].approved == false)
        {
            // the original adder of the new admin is no longer approved
            // become the new adder
            accountants_[_newAccountant].adder = msg.sender;
        }
        else if (accountants_[_newAccountant].adder != 0x0)
        {
            // two different admins approved, elevate
            accountants_[_newAccountant].approved = true;
            address _adder = accountants_[_newAccountant].adder;
            accountants_[_newAccountant].adder = 0x0;

            emit onNewAccountant(_newAccountant, _adder, msg.sender);
        }
    }

    function cancelAddNewAccountant(address _newAccountant)
        public
    {
        require(admins_[msg.sender].approved == true, "Only approved admin can add new accountant");
        require(accountants_[_newAccountant].approved == false, "This accountant was already approved");
        require(accountants_[_newAccountant].adder == msg.sender, "Only adder can cancel");

        accountants_[_newAccountant].adder = 0x0;
    }

    function removeAccountant(address _accountantToRemove)
        public
    {
        require(admins_[msg.sender].approved == true, "Only approved admin can remove accountant");
        require(accountants_[_accountantToRemove].approved == true, "Can only remove approved accountants");

        accountants_[_accountantToRemove].approved = false;

        emit onRemoveAccountant(_accountantToRemove, msg.sender);
    }

    function assignWithdrawLimit(address _accountant, uint256 _withdrawLimit)
        public
    {
        require(admins_[msg.sender].approved == true, "Only approved admin can assign withdraw limit");

        accountants_[_accountant].withdrawLimit = _withdrawLimit;

        emit onAssignWithdrawLimit(_accountant, msg.sender, _withdrawLimit);
    }

    // withdraw
    function withdraw(uint256 _amount)
        public
    {
        require(accountants_[msg.sender].approved == true, "Only approved accountants can withdraw");

        // if lastWithdrawTime is more than 24 hours ago, reset used withdraw amount
        if (now >= accountants_[msg.sender].lastWithdrawTime + 24 hours)
        {
            accountants_[msg.sender].lastWithdrawTime = now;
            accountants_[msg.sender].usedWithdrawLimit = 0;
        }

        accountants_[msg.sender].usedWithdrawLimit = add(_amount, accountants_[msg.sender].usedWithdrawLimit);
        require(accountants_[msg.sender].usedWithdrawLimit <= accountants_[msg.sender].withdrawLimit, "Can't withdraw more than limit in 1 day");

        msg.sender.transfer(_amount);

        emit onWithdraw(msg.sender, _amount);
    }

    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

    // Deposit

    function deposit() 
        external
        payable
        returns (bool)
    {
        emit onDeposit(msg.sender, msg.value);

        return true;
    }
}
