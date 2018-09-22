pragma solidity ^0.4.24;


contract HelloWorld {
    uint public value;
    event ValueSet(uint val);

    event Greeted(string);

    event SimpleEvent(uint);

    function greet(uint) public returns(uint) {
        emit Greeted("test");
        return 2;
    }

    function nonOverloadedGreet(uint ignored) public returns(uint) {
        emit SimpleEvent(7);
        return 4;
    }

    function greet(string) public returns(uint) {
        emit Greeted("test");
        return 3;
    }

    function echo(uint val) public pure returns(uint) {
        return val;
    }

    function nonPureEcho(uint val) public returns(uint) {
        return val;
    }

    function withEvent(uint val) public returns(uint) {
        emit SimpleEvent(val);
        return 8;
    }

    function setValue(uint val) public returns(uint) {
        value = val;
        emit ValueSet(value);
        return 42;
    }

    function getValue() public view returns(uint) {
        return value;
    }
}
