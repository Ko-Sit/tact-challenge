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
struct Pair {
    left: Pool;
    right: Pool;
}
// todo move pool to contract
struct Pool {
    amt: Int;
    addr: Address;
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
        let tokenAddr: Address = sender();
        require(tokenAddr == self.jettonAddressA || tokenAddr == self.jettonAddressB, "unknown jetton addr");
        // top up for admins
        if (msg.from == self.owner) {
            self.addBalance(tokenAddr, msg.amount);
            send(SendParameters{to: tokenAddr,
                    value: 0,
                    mode: SendRemainingValue,
                    bounce: true,
                    body: TokenTransfer{queryId: msg.queryId,
                        amount: 0,
                        destination: msg.from,
                        responseDestination: msg.from,
                        customPayload: null,
                        forwardTonAmount: 0,
                        forwardPayload: emptySlice()
                    }.toCell()
                }
            );
        } else {
            // check if incoming < jetton available
            if (self.balance(tokenAddr) < msg.amount || self.aAmount == 0 || self.bAmount == 0) {
                send(SendParameters{to: tokenAddr,
                        value: 0,
                        mode: SendRemainingValue,
                        bounce: true,
                        body: TokenTransfer{queryId: msg.queryId,
                            amount: msg.amount,
                            destination: msg.from,
                            responseDestination: msg.from,
                            customPayload: null,
                            forwardTonAmount: 0,
                            forwardPayload: emptySlice()
                        }.toCell()
                    }
                );
            } else {
                let pr: Pair = self.getPair(tokenAddr);
                // return swapped bal(2,10) - inc(+1, -5) - res(3, 5);
                // A-B (amtB * decimal / amtA) * tokenA / decimal
                // 2A+1A->3B => 1x1 price, return 1B
                // TODO top up balance before swap
                let swapped: Int = (pr.right.amt * self.decimal) / (pr.left.amt * msg.amount) / self.decimal;
                self.addBalance(pr.left.addr, msg.amount);
                self.subtractBalance(pr.right.addr, swapped);
                send(SendParameters{to: sender(),
                        value: 0,
                        mode: SendRemainingValue,
                        bounce: true,
                        body: TokenTransfer{queryId: msg.queryId,
                            amount: swapped,
                            destination: msg.from,
                            responseDestination: msg.from,
                            customPayload: null,
                            forwardTonAmount: 0,
                            forwardPayload: emptySlice()
                        }.toCell()
                    }
                );
            }
        }
    }

     fun getPair(from: Address): Pair {
        let poolA: Pool = self.getPool(self.jettonAddressA);
        let poolB: Pool = self.getPool(self.jettonAddressB);
        let pr: Pair = Pair{left: poolA, right: poolB};
        if (from == self.jettonAddressA) {
            // do nothing
        } else if (from == self.jettonAddressB) {
            pr = Pair{left: poolB, right: poolA};
        } else {
            // do nothing(8554);
        }

        return pr;
    }

     fun getPool(jetton: Address): Pool {
        let pl: Pool = Pool{amt: self.aAmount, addr: self.jettonAddressA};
        if (jetton == self.jettonAddressA) {
            pl = Pool{amt: self.aAmount, addr: self.jettonAddressA};
        } else if (jetton == self.jettonAddressB) {
            pl = Pool{amt: self.bAmount, addr: self.jettonAddressB};
        } else {
            // do nothing(1337);
        }
        return pl;
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
        if (jetton == self.jettonAddressA) {
            return self.bAmount * self.decimal / self.aAmount;
        } else {
            return self.aAmount * self.decimal / self.bAmount;
        }
    }
}