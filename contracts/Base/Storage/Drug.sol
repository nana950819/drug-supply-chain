pragma solidity ^0.5.0;


/// @author Khalid F.Sh
/// @title Drug Chain Contract
contract Drug {

    /// Variable for tracking Product Kepping Unit (PKU)
    uint pku;

    /// Variable for tracking Stock Louding Uint (SLU)
    uint slu;

    /// Public mapping from PKU to a Drug Item
    mapping (uint => DrugItem) dItems;

    /// Public mapping from SLU to a array of PKU
    mapping (uint => uint[]) stockLouds;

    // Enumaration for defining variety of Drug State
    enum DrugState {
        Manufactured,
        Packed,
        ForSale,
        Sold,
        Shipped,
        ShippmentEnvUpdated,
        Received,
        StockEnvUpdated,
        Purchased
    }

    // Structure for Envirument update unit
    struct EnvUpdateOpj {
        uint timeStamp;
        uint humidity;
        uint temprture;
        address updaterAddress;
    }

    /// Structure for keeping Drug Design fields structured
    struct DrugItem {
        uint udpc;
        uint pku;
        uint slu;
        DrugState state;
        address payable currentOwnerId;
        address manufacturerId;
        address deistributorId;
        address retailerId;
        uint price;
        uint packingTimeStamp;
        mapping(uint => EnvUpdateOpj) envHistory;
        uint envUpdateCounter;
    }

    /// Event to emit them for users in functions, accept `slu` as input as stock expected
    event Manufactured(uint slu);
    event Packed(uint slu);
    event ForSale(uint slu);
    event Sold(uint slu);
    event Shipped(uint slu);
    event EnvUpdated(uint slu);
    event Received(uint slu);
    /// Event to emit them for users in functions, accept `pku` as input as one product unit expected
    event Purchased(uint pku);

    /// Modifier that checks if an DrugDesignItem.state of a udpc is Owned
    modifier isManufactured(uint _slu) {
        uint firstPKU = stockLouds[_slu][0];
        require(dItems[firstPKU].state == DrugState.Manufactured);
        _;
    }

    /// Modifier that checks if an DrugDesignItem.state of a udpc is Owned
    modifier isPacked(uint _slu) {
        uint firstPKU = stockLouds[_slu][0];
        require(dItems[firstPKU].state == DrugState.Packed);
        _;
    }

    /// Modifier that checks if an DrugDesignItem.state of a udpc is Owned
    modifier drugLoudforSale(uint _slu) {
        uint firstPKU = stockLouds[_slu][0];
        require(dItems[firstPKU].state == DrugState.ForSale);
        _;
    }

    /// Modifier that checks if an DrugDesignItem.state of a udpc is Owned
    modifier isSold(uint _slu) {
        uint firstPKU = stockLouds[_slu][0];
        require(dItems[firstPKU].state == DrugState.Sold);
        _;
    }

    /// Modifier that checks if an DrugDesignItem.state of a udpc is Owned
    modifier isShipped(uint _slu) {
        uint firstPKU = stockLouds[_slu][0];
        require(dItems[firstPKU].state == DrugState.Shipped);
        _;
    }

    /// Modifier that checks if an DrugDesignItem.state of a udpc is Owned
    modifier isEnvTracked(uint _slu) {
        uint firstPKU = stockLouds[_slu][0];
        require(dItems[firstPKU].envUpdateCounter != 0);
        _;
    }

    modifier isReceived(uint _slu) {
        uint firstPKU = stockLouds[_slu][0];
        require(dItems[firstPKU].state == DrugState.Received);
        _;
    }

    /// Modifier that checks if an DrugDesignItem.state of a udpc is Owned
    modifier onlyManufacturerOf(uint _slu) {
        uint firstPKU = stockLouds[_slu][0];
        bool isManuf = dItems[firstPKU].manufacturerId == msg.sender;
        require(isManuf);
        _;
    }


    /// Modifier that checks if an DrugDesignItem.state of a udpc is Owned
    modifier onlyManufacturerOrDistributorOf(uint _slu) {
        uint firstPKU = stockLouds[_slu][0];
        bool isManuf = dItems[firstPKU].manufacturerId == msg.sender;
        bool isDistr = dItems[firstPKU].deistributorId == msg.sender;
        require(isManuf || isDistr);
        _;
    }

    /// Modifier that checks if an DrugDesignItem.state of a udpc is Owned
    modifier onlyRetailerOf(uint _slu) {
        uint firstPKU = stockLouds[_slu][0];
        bool isReta = dItems[firstPKU].retailerId == msg.sender;
        require(isReta);
        _;
    }

    /// Modifier that checks if an DrugDesignItem.state of a udpc is Owned
    modifier isDrugReceived(uint _pku) {
        require(dItems[_pku].state == DrugState.Received);
        _;
    }

    /// Modifier that checks if an DrugDesignItem.state of a udpc is Owned
    modifier isDrugEnvTracked(uint _pku) {
        require(dItems[_pku].envUpdateCounter != 0);
        _;
    }

    /// Constructor Function sets up SLU and PKU to 0
    constructor() public {
        slu = 0;
        pku = 0;
    }

    /// Function helps manufacturer to manufactur a new Drug Loud
    function manufacturDrugsLoud(uint _udpc, uint quantity) public {
        uint _slu = slu++;
        for (uint i = 0; i < quantity; i++) {
            uint _pku = pku++;
            DrugItem memory newDrugItem;
            newDrugItem.udpc = _udpc;
            newDrugItem.pku = _pku;
            newDrugItem.slu = _slu;
            newDrugItem.state = DrugState.Manufactured;
            newDrugItem.currentOwnerId = msg.sender;
            newDrugItem.manufacturerId = msg.sender;
            newDrugItem.envUpdateCounter = 0;

            dItems[_pku] = newDrugItem;
            stockLouds[_slu].push(_pku);
        }
        emit Manufactured(_slu);
    }

    /// Function helps manufacturer to Pack a isManufactured Drug Loud
    function packDrugsLoud(uint _slu)
        public
        isManufactured(_slu)
        onlyManufacturerOf(_slu)
    {
        uint quantity = stockLouds[_slu].length;
        for (uint i = 0; i < quantity; i++) {
            uint _pku = stockLouds[_slu][i];
            dItems[_pku].state = DrugState.Packed;
            dItems[_pku].packingTimeStamp = now;
        }
        emit Packed(_slu);
    }

    /// Function helps manufacturer to add Drug Loud for sale
    function addDrugsLoud(uint _slu, uint _unitPrice)
        public
        isPacked(_slu)
        onlyManufacturerOf(_slu)
    {
        uint quantity = stockLouds[_slu].length;
        for (uint i = 0; i < quantity; i++) {
            uint _pku = stockLouds[_slu][i];
            dItems[_pku].state = DrugState.ForSale;
            dItems[_pku].price = _unitPrice;
        }
        emit Packed(_slu);
    }

    /// Function helps distributor to buy a Drug Loud
    /// it can be quantity only order but i think its not important for now
    function buyDrugsLoud(uint _slu, address _receiver)
        public
        payable
        drugLoudforSale(_slu)
    {
        uint quantity = stockLouds[_slu].length;
        for (uint i = 0; i < quantity; i++) {
            uint _pku = stockLouds[_slu][i];
            dItems[_pku].state = DrugState.Sold;
            dItems[_pku].currentOwnerId = msg.sender;
            dItems[_pku].deistributorId = msg.sender;
            dItems[_pku].retailerId = _receiver;

        }
        emit Sold(_slu);
    }

    /// Function helps manufacturer to ship a Drug Loud
    function shipDrugsLoud(uint _slu)
        public
        isSold(_slu)
        onlyManufacturerOf(_slu)
    {
        uint quantity = stockLouds[_slu].length;
        for (uint i = 0; i < quantity; i++) {
            uint _pku = stockLouds[_slu][i];
            dItems[_pku].state = DrugState.Shipped;
        }
        emit Shipped(_slu);
    }

    /// Function helps manufacturer and distributor to update Drug Loud envuirment
    function updateDrugsLoudShippmentEnv (
        uint _slu,
        uint _humidity,
        uint _temprture
    )
        public
        isShipped(_slu)
        onlyManufacturerOrDistributorOf(_slu)
    {
        uint quantity = stockLouds[_slu].length;
        EnvUpdateOpj memory _envUpdate = EnvUpdateOpj(
            now,
            _humidity,
            _temprture,
            msg.sender
        );
        for (uint i = 0; i < quantity; i++) {
            uint _pku = stockLouds[_slu][i];

            dItems[_pku].envHistory[dItems[_pku].envUpdateCounter] = _envUpdate;
            dItems[_pku].envUpdateCounter ++;
        }
        emit EnvUpdated(_slu);
    }

    /// Function helps manufacturer to Pack a isManufactured Drug Loud
    function receiveDrugsLoud (
        uint _slu
    )
        public
        isShipped(_slu)
        isEnvTracked(_slu)
        onlyRetailerOf(_slu)
    {
        uint quantity = stockLouds[_slu].length;
        for (uint i = 0; i < quantity; i++) {
            uint _pku = stockLouds[_slu][i];

            dItems[_pku].state = DrugState.Received;
            dItems[_pku].currentOwnerId = msg.sender;
        }
        emit Received(_slu);
    }

    /// Function helps manufacturer to Pack a isManufactured Drug Loud
    function updateDrugsLoudStockEnv (
        uint _slu,
        uint _humidity,
        uint _temprture
    )
        public
        isReceived(_slu)
        onlyRetailerOf(_slu)
    {
        uint quantity = stockLouds[_slu].length;
        EnvUpdateOpj memory _envUpdate = EnvUpdateOpj(
            now,
            _humidity,
            _temprture,
            msg.sender
        );

        for (uint i = 0; i < quantity; i++) {
            uint _pku = stockLouds[_slu][i];

            if (dItems[_pku].state != DrugState.Purchased) {
                dItems[_pku].envHistory[dItems[_pku].envUpdateCounter] = _envUpdate;
                dItems[_pku].envUpdateCounter ++;
            }
        }
        emit EnvUpdated(_slu);
    }

    /// Function helps manufacturer to Pack a isManufactured Drug Loud
    function purchaseDrug (uint _pku)
        public
        payable
        isDrugReceived(_pku)
        isDrugEnvTracked(_pku)
    {
        dItems[_pku].state = DrugState.Purchased;
        dItems[_pku].currentOwnerId = msg.sender;

        emit Purchased(_pku);
    }

}
