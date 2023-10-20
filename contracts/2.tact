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
        self.mySend(SendParameters{to: msg.sender, value: 0, mode: SendRemainingValue});
    }

    receive(msg: Slice){
        let body: Cell = beginCell().storeRef(msg.asCell()).storeAddress(sender()).endCell();
        self.mySend(SendParameters{to: self.admin,
                value: 0,
                mode: SendRemainingBalance,
                body: body
            }
        );
    }

    fun mySend(params: SendParameters) {
        let b: Builder = beginCell()
            .storeInt(1, 2)
            .storeBool(params.bounce)
            .storeInt(0, 3)
            .storeAddress(params.to)
            .storeCoins(params.value)
            .storeInt(0, 1 + 4 + 4 + 64 + 32); 

        let body: Cell? = params.body;
        if (body != null) {
            b.storeBool(true);
            b.storeRef(body!!);
        } else {
            b.storeBool(false); 
        }
        
        let c: Cell = b.endCell();
        nativeSendMessage(c, params.mode);
    }
}