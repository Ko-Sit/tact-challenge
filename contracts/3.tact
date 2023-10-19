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
        let leftAddr: Address = sender();
        require(leftAddr == self.jettonAddressA || leftAddr == self.jettonAddressB, "unknown jetton addr");
        if (sender() == self.owner) {
            self.addBalance(leftAddr, msg.amount);
            send(SendParameters{to: sender(), value: 0, mode: SendRemainingValue, bounce: true, body: emptyCell()});
            return ;
        }
        // top up for admins
        // check if incoming < jetton available
        if (self.balance(leftAddr) < msg.amount) {
            send(SendParameters{to: sender(),
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
            return ;
        }
        let rightAddr: Address = self.jettonAddressA;
        if (leftAddr == self.jettonAddressA) {
            rightAddr = self.jettonAddressB;
        }
        let swapped: Int = self.price(rightAddr) * msg.amount / self.decimal;
        self.addBalance(leftAddr, msg.amount);
        self.subtractBalance(rightAddr, swapped);
        send(SendParameters{to: rightAddr,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: TokenTransfer{queryId: msg.queryId,
                    amount: swapped,
                    destination: self.owner,
                    responseDestination: myAddress(),
                    customPayload: null,
                    forwardTonAmount: 0,
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
        } else {
            return self.bAmount;
        }
    }

    get fun price(jetton: Address): Int {
        if (self.aAmount == 0 || self.bAmount == 0) {
            return 0;
        }
        if (jetton == self.jettonAddressA) {
            return self.bAmount * self.decimal / self.aAmount;
        } else {
            return self.aAmount * self.decimal / self.bAmount;
        }
    }
}