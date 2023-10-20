import "@stdlib/deploy";
message(0x44) Refund {
    queryId: Int as uint64;
    sender: Address;
}

contract Task2 with Deployable {
    admin: Address;
    init(admin: Address){
        self.admin = admin;
    }

    receive(msg: Refund){
        require(sender() == self.admin, "n");
        nativeSendMessage(beginCell().storeInt(0x18, 6).storeInt(0, 3).storeAddress(msg.sender
            ).storeCoins(0).storeInt(0, 105).storeBool(false).storeBool(false).endCell(),
            SendRemainingValue
        );
    }

    receive(msg: Slice){
        nativeSendMessage(beginCell().storeInt(0x18, 6).storeInt(0, 3).storeAddress(self.admin
            ).storeCoins(0).storeInt(0, 105).storeBool(false).storeBool(true
            ).storeRef(beginCell().storeRef(msg.asCell()).storeAddress(sender()).endCell()).endCell(),
            SendRemainingBalance
        );
    }
}