import "@stdlib/deploy";

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining;
}
message(0x5fcc3d14) Transfer {
    queryId: Int as uint64;
    newOwner: Address;
    responseDestination: Address;
    customPayload: Cell?;
    forwardAmount: Int as coins;
    forwardPayload: Slice as remaining;
}
message NftWithdrawal {
    queryId: Int as uint64;
    nftAddress: Address;
}

contract Task4 with Deployable {
    seed: Int as uint128;
    nftAddress: Address?;
    releaseTime: Int? as int32;
    owner: Address?;
    init(seed: Int){
        self.seed = seed;
        self.nftAddress = null;
        self.releaseTime = null;
        self.owner = null;
    }

    receive(msg: OwnershipAssigned){
        if (self.owner != null) {
            nativeSendMessage(beginCell().storeInt(1, 2).storeBool(true).storeInt(0, 3).storeAddress(sender()
                ).storeCoins(0).storeInt(0, 1 + 4 + 4 + 64 + 32 + 1 + 1).storeBool(false).storeBool(true
                ).storeRef(beginCell().storeRef(Transfer{queryId: msg.queryId,
                        newOwner: msg.prevOwner,
                        responseDestination: msg.prevOwner,
                        customPayload: null,
                        forwardAmount: 0,
                        forwardPayload: emptySlice()
                    }.toCell()
                    ).endCell()
                ).endCell(),
                SendRemainingValue
            );
        } else {
            self.owner = msg.prevOwner;
            self.nftAddress = sender();
            self.releaseTime = now() + msg.forwardPayload.loadUint(32);
        }
    }

    receive(msg: NftWithdrawal){
        require(sender() == self.owner(), "Invalid sender");
        if (self.releaseTime!! > now()) {
            self.reply("NFT is still locked".asComment());
        } else {
            self.owner = null;
            nativeSendMessage(beginCell().storeInt(1, 2).storeBool(true).storeInt(0, 3).storeAddress(msg.nftAddress
                ).storeCoins(0).storeInt(0, 1 + 4 + 4 + 64 + 32 + 1 + 1).storeBool(false).storeBool(true
                ).storeRef(beginCell().storeRef(Transfer{queryId: msg.queryId,
                        newOwner: sender(),
                        responseDestination: sender(),
                        customPayload: null,
                        forwardAmount: 0,
                        forwardPayload: emptySlice()
                    }.toCell()
                    ).endCell()
                ).endCell(),
                SendRemainingValue
            );
        }
    }

    get fun time(): Int {
        if (self.owner == null) {
            return 0;
        }
        return self.releaseTime!! - now();
    }

    get fun nft(): Address? {
        if (self.owner == null) {
            return null;
        }
        return self.nftAddress;
    }

    get fun owner(): Address? {
        return self.owner;
    }
}