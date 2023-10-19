import "@stdlib/deploy";

message(0x44) Refund {
    queryId: Int as uint64;
    sender: Address;
}

contract Task2 with Deployable {
    admin: Address;
    init(admin: Address){
        self.admin = admin;
    }

    receive(msg: Refund){
        require(sender() == self.admin, "n");
        send(SendParameters{to: msg.sender, value: 0, mode: SendRemainingValue});
    }

    receive(msg: Slice){
        let body: Cell = beginCell().storeRef(msg.asCell()).storeAddress(sender()).endCell();
        send(SendParameters{to: self.admin,
                value: 0,
                mode: SendRemainingBalance,
                body: body
            }
        );
    }
}