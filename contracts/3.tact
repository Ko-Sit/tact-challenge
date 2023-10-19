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
    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");
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
        let leftAddr: Address = sender();
        require(leftAddr == self.jettonAddressA || leftAddr == self.jettonAddressB, "suct");
        let rightAddr: Address = self.jettonAddressA;
        if (leftAddr == self.jettonAddressA) {
            rightAddr = self.jettonAddressB;
        }
        // top up for admins
        if (msg.from == self.owner) {
            self.addBalance(leftAddr, msg.amount);
            self.sendBack(msg.from, 0, msg);
        } else {
            if (msg.amount > self.balance(leftAddr)) {
                self.sendBack(sender(), msg.amount, msg);
            } else {
                let swapped: Int = self.price(rightAddr) * msg.amount / self.decimal;
                // send swapped to second address
                self.addBalance(leftAddr, msg.amount);
                self.subtractBalance(rightAddr, swapped);
                self.sendBack(rightAddr, swapped, msg);
            }
        }
    }

     fun sendBack(tokenAddr: Address, amount: Int, msg: TokenNotification) {
        send(SendParameters{to: tokenAddr,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: TokenTransfer{queryId: msg.queryId,
                    amount: amount,
                    destination: msg.from,
                    responseDestination: myAddress(),
                    customPayload: null,
                    forwardTonAmount: ton("0.01"),
                    forwardPayload: emptySlice()
                }.toCell()
            }
        );
    }

     fun addBalance(jetton: Address, amt: Int) {
        if (jetton == self.jettonAddressA) {
            self.aAmount = self.aAmount + amt;
        } else {
            self.bAmount = self.bAmount + amt;
        }
    }

     fun subtractBalance(jetton: Address, amt: Int) {
        if (jetton == self.jettonAddressA) {
            self.aAmount = self.aAmount - amt;
        } else {
            self.bAmount = self.bAmount - amt;
        }
    }

    get fun balance(jetton: Address): Int {
        if (jetton == self.jettonAddressA) {
            return self.aAmount;
        } else if (jetton == self.jettonAddressB) {
            return self.bAmount;
        }
        return 0;
    }

    get fun price(jetton: Address): Int {
        if (self.aAmount == 0 || self.bAmount == 0) {
            return 0;
        }
        if (jetton == self.jettonAddressA) {
            return self.bAmount * self.decimal / self.aAmount;
        } else if (jetton == self.jettonAddressA) {
            return self.aAmount * self.decimal / self.bAmount;
        }
        return 0;
    }
}