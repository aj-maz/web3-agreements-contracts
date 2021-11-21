
## Problem:

Alice wants to hire Bob.
Bob doesn’t trust Alice and Asks Alice to pay him forward.
Even though Alice trust Bob’s skills, she doesn’t trust his work ethic. So he doesn’t want to pay him forward.
Bob suggests that Alice put the money into a contract that is an ERC792 arbitrable and a Kleros court will resolve their dispute in case of having one.
Alice really likes this idea, but the contract will take 3 months, and Alice doesn’t like to make her money idle for 3 months, because she thinks she can use it to make more.


## Solution:

Instead of locking money into the arbitrable contract, We could lock it in Aave, and when the contract is releasing the funds, it will give the employer the profit of the money that was deposited to Aave.

## How it works:

There is 2 implementation available, one using Aave interfaces and one without it for testing purposes. The general implementation is: There is a contract for managing agreements, and a contract that is called AaveAgreement.
This contract is an ERC792 arbitrable contract that uses the kleros court. After creating an agreement employer will deposit the money into Aave with the respected asset and on behalf of the contract. Then employer changes the status of the contract to Started by calling the start function.
after the due date comes gelato will call the function dued for a single time and contract status will be changed to Dued.
They're gonna be a period of reclamation and if no dispute arises employee can finalize the contract and get paid. Also, the employer can finalize the contract in that period. This way the amount of prize for work will be paid to the employee and the profit will be given out to the employer.
The other functions are the standard functions of an arbitrable contract which can be found in here:
https://developer.kleros.io/en/latest/implementing-an-arbitrable.html

In case of reclaiming payment to the employer, all the money with its profit will be given to the employer.

## Client: https://github.com/Ajand/web3-agreements-client
