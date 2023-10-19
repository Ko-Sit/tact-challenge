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
        let ctx: Context = context();
        require(ctx.sender == self.jettonAddressA || ctx.sender == self.jettonAddressB, "suct");
        if (ctx.sender == self.jettonAddressA) {
            self.pathA(msg);
        } else {
            self.pathB(msg);
        }
    }

     fun pathA(msg: TokenNotification) {
        // top up for admins
        if (msg.from == self.owner) {
            self.aAmount = self.aAmount + msg.amount;
            send(SendParameters{to: self.jettonAddressA,
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
            if (msg.amount > self.balance(self.jettonAddressA)) {
                send(SendParameters{to: self.jettonAddressA,
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
                let swapped: Int = self.price(self.jettonAddressA) * msg.amount / self.decimal;
                // send swapped to second address
                self.aAmount = self.aAmount + msg.amount;
                // subtract
                self.bAmount = self.bAmount - swapped;
                send(SendParameters{to: self.jettonAddressB,
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

     fun pathB(msg: TokenNotification) {
        // top up for admins
        if (msg.from == self.owner) {
            self.bAmount = self.bAmount + msg.amount;
            send(SendParameters{to: self.jettonAddressB,
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
            if (msg.amount > self.balance(self.jettonAddressB)) {
                send(SendParameters{to: self.jettonAddressB,
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
                let swapped: Int = self.price(self.jettonAddressB) * msg.amount / self.decimal;
                // send swapped to second address
                self.bAmount = self.bAmount + msg.amount;
                // subtract
                self.bAmount = self.bAmount - swapped;
                send(SendParameters{to: self.jettonAddressA,
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