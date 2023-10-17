import "@stdlib/deploy";
/*
  TASK 3 - DEX
  Create a simple jetton dex contract that trades one pair of jettons: A and B.
  The price of jettons depends on the amount of jettons that smart contract has.
  Therefore, the smart contract needs to keep track of how much jettons it has.
  
  Price for the jetton A in swap B->A should be calculated by formula "amountOfJettonAOnContract * decimal / amountOfJettonBOnContract".
  Token prices must be decimalized for accuracy, so it is the prices that must be adjusted to decimal 1e9.
  Decimals are only needed for price accuracy. It should be set as 1e9.
  So, if smart contract has 10 of jetton A and 2 of jetton B, then after sending 1 jetton B you should receive 5 of jettons A.

  Example formula for amountOfAJettonToSend in B->A swap will be
  (amountOfJettonAOnContract * decimal / amountOfJettonBOnContract) * amountOfTokenBToSwap / decimal

  If smart contract pool doesn't have enough jettons to trade,
  then it should send incoming jettons back to the user. For a clearer explanation,
  let's look at the example we described above (smart contract has 10 of jetton A and 2 of jetton B).
  If user will send 3 jettons B, smart contract should reject the message (because contract does not have 3 * 5 = 15 jettons A)
  and send 3 jettons B back to the user.

  If smart contract receives a different jetton (neither A nor B) then throw an error.

  Implement a getter that returns the number of jettons in the pool and
  one more to get the price of jetton A or jetton B.
  Getters' behavior with incorrect parameter (address other than that of jetton A or B)
  is undefined (there are no such tests).
  
  Note:
  Admin can add jettons A and B just by sending them to the smart contract (we need to add initial supply to the pool for it to be functional).
  To be exact: any jettons (A or B) received from the admin are "added". Admin can't swap.
*/

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
message Pair {
    left: Pool;
    right: Pool;
}
// todo move pool to contract
message Pool {
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
        let tokenAddr: Address = msg.from;
        // check if jetton a or b
        let pr: Pair = self.getPair(tokenAddr);
        // top up for admins
        if (sender() == self.owner) {
            if (tokenAddr == self.jettonAddressA) {
                self.aAmount = pr.left.amt + msg.amount;
            } else {
                self.bAmount = pr.left.amt + msg.amount;
            }
        } else {
            // check if incoming < jetton available
            if (pr.left.amt < msg.amount) {
                send(SendParameters{to: sender(),
                        value: 0,
                        mode: SendRemainingValue,
                        bounce: false,
                        body: TokenTransfer{queryId: msg.queryId,
                            amount: msg.amount,
                            destination: sender(),
                            responseDestination: myAddress(),
                            customPayload: null,
                            forwardTonAmount: ton("0.01"),
                            forwardPayload: emptySlice()
                        }.toCell()
                    }
                );
            } else {
                // return swapped bal(2,10) - inc(+1, -5) - res(3, 5);
                // A-B (amtB * decimal / amtA) * tokenA / decimal
                let swapped: Int = pr.right.amt * self.decimal / pr.left.amt * msg.amount / self.decimal;
                self.addBalance(pr.left.addr, msg.amount);
                self.subtractBalance(pr.right.addr, swapped);
                send(SendParameters{to: sender(),
                        value: 0,
                        mode: SendRemainingValue,
                        bounce: true,
                        body: TokenTransfer{queryId: msg.queryId,
                            amount: swapped,
                            destination: sender(),
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

     fun getPair(from: Address): Pair {
        let poolA: Pool = self.getPool(self.jettonAddressA);
        let poolB: Pool = self.getPool(self.jettonAddressB);
        let pr: Pair = Pair{left: poolA, right: poolB};
        if (from == self.jettonAddressA) {
            // do nothing
        } else if (from == self.jettonAddressB) {
            pr = Pair{left: poolB, right: poolA};
        } else {
            throw(8554);
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
            throw(1337);
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
        let amt: Int = self.getPool(jetton).amt;
        return amt;
    }

    get fun price(jetton: Address): Int {
        let pr: Pair = self.getPair(jetton);
        if (pr.left.amt == 0 || pr.right.amt == 0) {
            throw(1483);
        }
        return pr.right.amt * self.decimal / pr.left.amt;
    }
}