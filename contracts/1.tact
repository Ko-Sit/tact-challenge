import "@stdlib/deploy";

/*
  TASK 1 - Counter 
  Implement a counter contract that will have 2 opcodes ('Add' / 'Subtract'),
  which adds or subtracts the received number (int32) from the number that is stored in the state (and stores the result back in the state).
  You also need to implement one getter with the name "counter" to get the current number from the state.
*/

message Add {
  queryId: Int as uint64;
  number: Int as uint32;
}

message Subtract {
  queryId: Int as uint64;
  number: Int as uint32;
}

contract Task1 with Deployable {
    counter: Int as int32;
    addRequestMap: map<Int, Int>;
    subtractRequestMap: map<Int, Int>;

    init() {
      self.counter = 0;
    }

    receive(msg: Add) {
        if (self.addRequestMap.get(msg.queryId) == null) {
            self.addRequestMap.set(msg.queryId, msg.number);
            self.counter = self.counter + msg.number;
        }
    }
    
    receive(msg: Subtract) {
       if (self.subtractRequestMap.get(msg.queryId) == null) {
            self.addRequestMap.set(msg.queryId, msg.number);
            self.counter = self.counter - msg.number;
        }
    }

    get fun counter(): Int {
        return self.counter;
    }
}
