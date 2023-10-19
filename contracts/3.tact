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
        let rightAddr: Address = self.jettonAddressB;
        if (leftAddr == self.jettonAddressB) {
            rightAddr = self.jettonAddressA;
        }
        // top up for admins
        if (msg.from == self.owner) {
            self.addBalance(leftAddr, msg.amount);
            self.sendBack(msg.from, 0, msg);
        } else {
            if (msg.amount > self.balance(leftAddr)) {
                self.sendBack(sender(), msg.amount, msg);
            } else {
                let swapped: Int = self.price(leftAddr) * msg.amount / self.decimal;
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
        if (jetton == self.jettonAddressB) {
            self.bAmount = self.bAmount + amt;
        } else {
            self.aAmount = self.aAmount + amt;
        }
    }

     fun subtractBalance(jetton: Address, amt: Int) {
        if (jetton == self.jettonAddressB) {
            self.bAmount = self.bAmount - amt;
        } else {
            self.aAmount = self.aAmount - amt;
        }
    }

    get fun balance(jetton: Address): Int {
        if (jetton == self.jettonAddressB) {
            return self.bAmount;
        } 
        return self.aAmount;
    }

    get fun price(jetton: Address): Int {
        if (jetton == self.jettonAddressB) {
            return self.aAmount * self.decimal / self.bAmount;
        } 
        return self.bAmount * self.decimal / self.aAmount;
    }
}