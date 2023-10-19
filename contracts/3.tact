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
    jettonAddressA: Address;
    jettonAddressB: Address;
    decimal: Int;
    init(admin: Address, newJettonAddressA: Address, newJettonAddressB: Address){
        self.owner = admin;
        self.jettonAddressA = newJettonAddressA;
        self.jettonAddressB = newJettonAddressB;
        self.aAmount = 0;
        self.bAmount = 0;
        self.decimal = 1000000000;
    }

    receive(msg: TokenNotification){
        require(sender() == self.jettonAddressA || sender() == self.jettonAddressB, "suct");
        let leftAddr: Address = sender();
        let rightAddr: Address = self.jettonAddressA;
        let isLeft: Bool = leftAddr == self.jettonAddressA;
        if (isLeft) {
            rightAddr = self.jettonAddressB;
        }
        // top up for admins
        if (msg.from == self.owner) {
            if (isLeft) {
                self.aAmount = self.aAmount + msg.amount;
            } else {
                self.bAmount = self.bAmount + msg.amount;
            }
            send(SendParameters{to: leftAddr,
                    value: 0,
                    mode: SendRemainingValue,
                    bounce: true,
                    body: TokenTransfer{queryId: msg.queryId,
                        amount: 0,
                        destination: msg.from,
                        responseDestination: myAddress(),
                        customPayload: null,
                        forwardTonAmount: ton("0.01"),
                        forwardPayload: emptySlice()
                    }.toCell()
                }
            );
        } else {
            if (msg.amount > self.balance(leftAddr)) {
                send(SendParameters{to: leftAddr,
                        value: 0,
                        mode: SendRemainingValue,
                        bounce: true,
                        body: TokenTransfer{queryId: msg.queryId,
                            amount: msg.amount,
                            destination: msg.from,
                            responseDestination: myAddress(),
                            customPayload: null,
                            forwardTonAmount: ton("0.01"),
                            forwardPayload: emptySlice()
                        }.toCell()
                    }
                );
            } else {
                let swapped: Int = self.price(leftAddr) * msg.amount / self.decimal;
                // send swapped to second address
                if (isLeft) {
                    self.aAmount = self.aAmount + msg.amount;
                } else {
                    self.bAmount = self.bAmount + msg.amount;
                }
                // subtract
                if (isLeft) {
                    self.bAmount = self.bAmount - swapped;
                } else {
                    self.aAmount = self.aAmount - swapped;
                }
                send(SendParameters{to: rightAddr,
                        value: 0,
                        mode: SendRemainingValue,
                        bounce: true,
                        body: TokenTransfer{queryId: msg.queryId,
                            amount: swapped,
                            destination: msg.from,
                            responseDestination: myAddress(),
                            customPayload: null,
                            forwardTonAmount: ton("0.01"),
                            forwardPayload: emptySlice()
                        }.toCell()
                    }
                );
            }
        }
    }

     fun sendBack(tokenAddr: Address, amount: Int, msg: TokenNotification) {}

    get fun balance(jetton: Address): Int {
        if (jetton == self.jettonAddressA) {
            return self.aAmount;
        }
        return self.bAmount;
    }

    get fun price(jetton: Address): Int {
        if (jetton == self.jettonAddressA) {
            return self.bAmount * self.decimal / self.aAmount;
        }
        return self.aAmount * self.decimal / self.bAmount;
    }
}