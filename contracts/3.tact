import "@stdlib/deploy";
message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}
// To simplify the testing process and the specificity of the messages being sent, we decided to add clear default values in this transaction
message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64; // should be 0
    amount: Int as coins; // should be amount of jettons to send
    destination: Address; // should be user address / TokenNotification.from
    responseDestination: Address?; // should be myAddress()
    customPayload: Cell?; // should be null
    forwardTonAmount: Int as coins; // should be ton("0.01")
    forwardPayload: Slice as remaining; // should be emptySlice()
}

contract Task3 with Deployable {
    owner: Address;
    aAmount: Int;
    bAmount: Int;
    jA: Address;
    jB: Address;
    init(admin: Address, newjA: Address, newjB: Address){
        self.owner = admin;
        self.jA = newjA;
        self.jB = newjB;
        self.aAmount = 0;
        self.bAmount = 0;
    }

    receive(msg: TokenNotification){
        require(sender() == self.jA || sender() == self.jB, "s");
        let rightAddr: Address = self.jA;
        let isLeft: Bool = sender() == self.jA;
        if (isLeft) {
            rightAddr = self.jB;
        }
        // casual user 
        if (msg.from != self.owner) {
            if (msg.amount <= self.balance(sender())) {
                let swapped: Int = self.price(sender()) * msg.amount / 1000000000;
                if (isLeft) {
                    self.aAmount = self.aAmount + msg.amount;
                    self.bAmount = self.bAmount - swapped;
                } else {
                    self.bAmount = self.bAmount + msg.amount;
                    self.aAmount = self.aAmount - swapped;
                }
                nativeSendMessage(beginCell()
                    .storeInt(0x18, 6)
                    .storeAddress(rightAddr)
                    .storeCoins(0)
                    .storeUint(0, 105)
                    .storeBool(false).storeBool(true)
                    .storeRef(TokenTransfer{queryId: msg.queryId,
                        amount: swapped,
                        destination: msg.from,
                        responseDestination: myAddress(),
                        customPayload: null,
                        forwardTonAmount: ton("0.01"),
                        forwardPayload: emptySlice()
                    }.toCell()).endCell(), SendRemainingValue);
            } else {
                // cant swap, return
                nativeSendMessage(beginCell()
                    .storeInt(0x18, 6)
                    .storeAddress(sender())
                    .storeCoins(0)
                    .storeUint(0, 105)
                    .storeBool(false).storeBool(true)
                    .storeRef(TokenTransfer{queryId: msg.queryId,
                        amount: msg.amount,
                        destination: msg.from,
                        responseDestination: myAddress(),
                        customPayload: null,
                        forwardTonAmount: ton("0.01"),
                        forwardPayload: emptySlice()
                    }.toCell()).endCell(), SendRemainingValue);
            }
        } else {
            // top up for admins
            if (isLeft) {
                self.aAmount = self.aAmount + msg.amount;
            } else {
                self.bAmount = self.bAmount + msg.amount;
            }
            nativeSendMessage(beginCell()
                .storeInt(0x18, 6)
                .storeAddress(sender())
                .storeCoins(0)
                .storeUint(0, 105)
                .storeBool(false).storeBool(true)
                .storeRef(TokenTransfer{queryId: msg.queryId,
                    amount: 0,
                    destination: msg.from,
                    responseDestination: myAddress(),
                    customPayload: null,
                    forwardTonAmount: ton("0.01"),
                    forwardPayload: emptySlice()
                }.toCell()).endCell(), SendRemainingValue);
        }
    }

    get fun balance(jetton: Address): Int {
        if (jetton == self.jA) {
            return self.aAmount;
        }
        return self.bAmount;
    }

    get fun price(jetton: Address): Int {
        if (jetton == self.jA) {
            return self.bAmount * 1000000000 / self.aAmount;
        }
        return self.aAmount * 1000000000 / self.bAmount;
    }
}