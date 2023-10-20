import "@stdlib/deploy";

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
message NftWithdrawal {
    queryId: Int as uint64;
    nftAddress: Address;
}

struct Vault {
    nftAddress: Address?;
    releaseTime: Int? as int32;
    owner: Address?;
}

contract Task4 with Deployable {
    seed: Int as uint128;
    vault: Vault;
    init(seed: Int){
        self.seed = seed;
        self.vault = Vault{nftAddress: null, releaseTime: null, owner: null};
    }

    receive(msg: OwnershipAssigned){
        if (self.vault.nftAddress != null) {
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
                }
            );
        } else {
            self.vault = Vault{
                owner: msg.prevOwner,
                nftAddress: sender(),
                releaseTime: now() + msg.forwardPayload.loadUint(32)
            };
        }
    }

    receive(msg: NftWithdrawal){
        require(sender() == self.owner(), "Invalid sender");
        if (self.vault.releaseTime!! > now()) {
            self.reply("NFT is still locked".asComment());
        } else {
            self.vault = Vault{nftAddress: null, releaseTime: null, owner: null};
            send(SendParameters{to: msg.nftAddress,
                    mode: SendRemainingValue,
                    value: 0,
                    body: Transfer{queryId: msg.queryId,
                        newOwner: sender(),
                        responseDestination: sender(),
                        customPayload: null,
                        forwardAmount: 0,
                        forwardPayload: emptySlice()
                    }.toCell()
                }
            );
        }
    }

    get fun time(): Int {
        return self.vault.releaseTime!! - now();
    }

    get fun nft(): Address? {
        return self.vault.nftAddress;
    }

    get fun owner(): Address? {
        return self.vault.owner;
    }
}