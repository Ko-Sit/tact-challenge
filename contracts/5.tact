import "@stdlib/deploy";

message AdminWithdrawalProfit {
  queryId: Int as uint64;
}

message AdminWithdrawalAllNFTs {
  queryId: Int as uint64;
}

message AdminFetchProfit {
  queryId: Int as uint64;
}

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining; 
}

message(0x5fcc3d14) Transfer { 
    queryId: Int as uint64;            
    newOwner: Address; 
    responseDestination: Address; 
    customPayload: Cell?; 
    forwardAmount: Int as coins; 
    forwardPayload: Slice as remaining; 
}

contract Task5 with Deployable {
  const minTonForStorage: Int = ton("0.01");
  const minTonForOperation: Int = ton("0.01");
  seed: Int as uint128;
  owner: Address;
  nftMap: map<Int as uint16, Address>;
  currentIndex: Int;
  
  init(seed: Int, owner: Address) {
    self.owner = owner;
    self.seed = seed;
    self.currentIndex = -1;
  }

  fun adminAddNft(nftAddress: Address) {
    self.currentIndex = self.currentIndex + 1;
    self.nftMap.set(self.currentIndex, nftAddress);
  }

    fun swapNft(newNftAddress: Address): Address {
        // from <= x <= to 
        // TODO or check if empty here
      let randomIndex: Int = random(0, self.currentIndex - 1);
      let nftFromPool: Address = self.nftMap.get(randomIndex)!!;
      self.nftMap.set(randomIndex, newNftAddress);
      return nftFromPool;
   }

  receive(msg: OwnershipAssigned) {
        if (msg.prevOwner == self.owner) {
            // add from admin
            self.adminAddNft(sender());
            send(SendParameters{to: sender(),
                value: 0,
                mode: SendRemainingValue,
                body: Transfer{queryId: msg.queryId,
                    newOwner: msg.prevOwner,
                    responseDestination: msg.prevOwner,
                    customPayload: null,
                    forwardAmount: 0,
                    forwardPayload: emptySlice()
                }.toCell()
            });
        } else {
            // can refund for small amounts
            // TODO check if min should be 0.1 or 0.2
           require(context().value > self.minTonForOperation, "not enough ton for swap");
           // make refund - small incoming balance 
           if (context().value < ton("2.1")) {
                send(SendParameters{to: sender(),
                    mode: SendRemainingValue,
                    value: 0,
                    body: Transfer{queryId: msg.queryId,
                        newOwner: msg.prevOwner,
                        responseDestination: myAddress(),
                        customPayload: null,
                        forwardAmount: 0,
                        forwardPayload: emptySlice()
                    }.toCell()
                });
           } else {
                // enough ton, do swap
                // TODO check if pool is not empty
                // get random nft address
                let newNftAddress: Address = self.swapNft(sender());
                // send 
                send(SendParameters{to: newNftAddress,
                    mode: SendRemainingValue,
                    value: context().value - ton("2.0"),
                    body: Transfer{queryId: msg.queryId,
                        newOwner: msg.prevOwner,
                        responseDestination: myAddress(),
                        customPayload: null,
                        forwardAmount: 0,
                        forwardPayload: emptySlice()
                    }.toCell()
                });
           }

        }
  }

  receive(msg: AdminWithdrawalProfit) {
    require(sender() == self.owner, "Insufficient privelegies");
    let totalAmt: Int = self.profit();
    require(totalAmt > 0, "Insufficient balance");
     send(SendParameters{
        to: sender(), 
        value: totalAmt,
        bounce: true,
        mode: SendRemainingValue,
        body: AdminFetchProfit{
            queryId: msg.queryId
        }.toCell()
    });
  }

  receive(msg: AdminWithdrawalAllNFTs) {
    require(context().value >= ton("1") + self.totalNftHeld() * ton("0.08"), "Insufficent funds");
    require(sender() == self.owner, "Invalid sender");

    
  }

  get fun totalNftHeld(): Int { 
    return self.currentIndex + 1;
  }

  get fun profit(): Int { 
    return myBalance() - ton("0.1");
  }
  
  get fun nfts(): map<Int as uint16, Address> { 
    return self.nftMap;
  }
}
