pragma solidity ^0.4.14;

import './SafeMath.sol';
import './Ownable.sol';

contract Payroll is Ownable {

    using SafeMath for uint;

    struct Employee {
        address id;
        uint salary;
        uint lastPayday;
    }

    uint constant payDuration = 30 days;
    uint public totalSalary = 0;
    mapping(address => Employee) public employees;
	
    modifier employeeExist(address employeeId) {
        var employee = employees[employeeId];
        assert(employee.id != 0x0);
        _;
    }
    
    // set function _partialPaid as a modifier
    modifier _partialPaid(address employeeId){
        var employee = employees[employeeId];
	uint payment = employee.salary.mul((now - employee.lastPayday).div(payDuration));
        employee.id.transfer(payment);
	_;
    }
	
    function addEmployee(address employeeId, uint salary) onlyOwner public {
        var employee = employees[employeeId];
        assert(employee.id == 0x0);
        
        salary = salary.mul(1 ether);
        employees[employeeId] = Employee(employeeId, salary, now);
        totalSalary = totalSalary.add(salary);
    }

    function removeEmployee(address employeeId) onlyOwner employeeExist(employeeId) _partialPaid(employeeId) public {       
        totalSalary = totalSalary.sub(employees[employeeId].salary);
        delete employees[employeeId];
    }

    // pay to the old address, generate a new address, then delete the old address
    function changePaymentAddress(address oldAddress, address newAddress) onlyOwner employeeExist(oldAddress) _partialPaid(oldAddress) public {		
        employees[newAddress] = Employee(newAddress, employees[oldAddress].salary, now);
        delete employees[oldAddress];
    }

    function updateEmployee(address employeeId, uint salary) onlyOwner employeeExist(employeeId) _partialPaid(employeeId) public { 
        totalSalary = totalSalary.sub(employees[employeeId].salary);
        employees[employeeId].salary = salary.mul(1 ether);
	totalSalary = totalSalary.add(employees[employeeId].salary);
        employees[employeeId].lastPayday = now;
    }

    function addFund() payable public returns (uint) {
        return address(this).balance;
    }

    function calculateRunway() public view returns (uint) {
        return this.balance.div(totalSalary); 
    }

    function hasEnoughFund() public view returns (bool) {
        return calculateRunway() > 0;
    }

    function getPaid() employeeExist(msg.sender) public{
        var employee = employees[msg.sender];
        require(this.balance >= employee.salary);
        
        uint nextPayday = employee.lastPayday.add(payDuration);
        assert(nextPayday < now);
        
        employees[msg.sender].lastPayday = nextPayday;
        employee.id.transfer(employee.salary);
    }
}
