var BLVToken = artifacts.require('BLVToken');
module.exports = function(deployer) {
  deployer.deploy(BLVToken,100000,'Blu Token',3,'BLV');
};
