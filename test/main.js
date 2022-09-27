const CentralHub = artifacts.require("CentralHub");
const ForeignHub = artifacts.require("ForeignHub");
const GLDToken = artifacts.require("GLDToken");
const wGLDToken = artifacts.require("ERC20Delivery.sol");
/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("main", async accounts => {
    it("should assert true", async function () {
        const centralHub = await CentralHub.deployed();
        const foreignHub = await ForeignHub.deployed();

        // Token on home chain
        const gldToken = await GLDToken.deployed();

        // Token on (mock) foreign chain
        const wGldToken = await wGLDToken.deployed();

        // Connect
        await centralHub.configForeignTokenAddress(gldToken.address, 137, wGldToken.address);
        await foreignHub.configHomeTokenAddress(wGldToken.address, gldToken.address);

        // Eth => 
        await gldToken.approve(centralHub.address, 12345);
        await centralHub.exportToken(accounts[0], gldToken.address, 12345, 137);

        // => Polygon
        let msgHash = web3.utils.soliditySha3("<transaction_hash>", 1, 137, wGldToken.address, gldToken.address, accounts[0], 12345);
        // let signature = await accounts[1].sign(msgHash, '0x' + privateKeyUser);

        // TODO
        // let validatorSignatures = await foreignHub.importToken("<transaction_hash>", accounts[0], wGldToken.address, 12345, [1, 2, 3, 4], validatorSignatures);
        return assert.isTrue(true);
    });
});
