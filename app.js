// Scenario: user wants to sell his gnt tokens
//  Given user is logged in to the MetaMask
//  When user fills the form with the amount
//  Then the MetaMask window appears
//  When user submits
//  Then the transfer transaction is signed
//  And tokens are transferred from the user account to the exchange account
//  And the transaction is analysed by the backend app
//  When the transaction is ok
//  Then the backend app calls SetUserGntBalance() on the smart contract with data read from the transaction 