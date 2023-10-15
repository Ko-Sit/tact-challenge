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
    addKeys: map<Int, Int>;
    addIndex: Int as uint8 = 0; 
    subtractRequestMap: map<Int, Int>;
    subtractKeys: map<Int, Int>;
    subtractIndex: Int as uint8 = 0; 

    init() {
      self.counter = 0;
    }

    receive(msg: Add) {
        if (self.addRequestMap.get(msg.queryId) == null) {
            self.addRequestMap.set(msg.queryId, 0);
            self.addKeys.set(self.addIndex, msg.number);
            self.addIndex = self.addIndex + 1;
        }
    }
    
    receive(msg: Subtract) {
       if (self.subtractRequestMap.get(msg.queryId) == null) {
            self.subtractRequestMap.set(msg.queryId, 0);
            self.subtractKeys.set(self.subtractIndex, msg.number);
            self.subtractIndex = self.subtractIndex + 1;
        }
    }

    get fun counter(): Int {
        let sum: Int = 0;
        let i: Int = 0;
        while (i < self.addIndex) {
            sum = sum + self.addKeys.get(i)!!;
            i = i + 1;
        }
        i = 0;
        while (i < self.subtractIndex) {
            sum = sum + self.subtractKeys.get(i)!!;
            i = i + 1;
        }
        return sum;
    }
}
