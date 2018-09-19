pragma solidity ^0.4.25;


contract HelloWorld {
  event Greeted(string);

  function greet() public {
    emit Greeted("anonymous");
  }

  function greet(string name) public {
    emit Greeted(name);
  }
}
