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
        nativeSendMessage(beginCell().storeInt(0x18, 6).storeAddress(self.admin).storeCoins(0).storeInt(0, 1 + 4 + 4 + 64 + 32).endCell(),
            SendRemainingValue
        );
    }

    receive(msg: Slice){
        nativeSendMessage(beginCell().storeInt(0x18, 6).storeAddress(self.admin).storeCoins(0).storeInt(0, 1 + 4 + 4 + 64 + 32  + 1 + 1).storeRef(msg.asCell()).storeAddress(sender()).endCell(),
            SendRemainingBalance
        );

    }
}