const Migrations = artifacts.require("Migrations");
const CentralHub = artifacts.require("CentralHub");
const ForeignHub = artifacts.require("ForeignHub");
const GLDToken = artifacts.require("GLDToken");
const wGLDToken = artifacts.require("ERC20Delivery.sol");

module.exports = function (deployer, network, accounts) {
    deployer.then(async () => {
        await deployer.deploy(Migrations);
        await deployer.deploy(CentralHub, 1, accounts[0], 32, 4, accounts);
        await deployer.deploy(ForeignHub, 1, 137, accounts[0], 32, 4, accounts);
        await deployer.deploy(GLDToken, 12345);
        await deployer.deploy(wGLDToken, accounts[0], "Wrapped Gold", "wGOLD", 12345);
    });
};