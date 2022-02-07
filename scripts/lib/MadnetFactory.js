//separate deploy of template from deploy of deterministic address 

//import { string } from "hardhat/internal/core/params/argumentTypes";

//assume you have to divide the transaction 
//estimate gas, observe gas limit, 

//return all addresses 

//return the logs
const {artifacts, ethers} = require("hardhat");
const defaultFactoryName = "MadnetFactory";
const DeployedRawEvent = "DeployedRaw";
const contractAddrVar = "contractAddr";
const DeployedProxyEvent = "DeployedProxy";
const logicAddrKey = "LogicAddress";
const ProxyAddrKey = "ProxyAddress"
const deployedStaticEvent = "DeployedStatic";
const deployedTemplateEvent ="DeployedTemplate";
const MetaAddrKey = "MetaAddress"
const templateAddrKey = "TemplateAddress"


async function deployUpgradeable(contractName, factoryAddress, constructorArgs, txParam){
    let MadnetFactory = await artifacts.require(defaultFactoryName);
    let factory = await MadnetFactory.at(factoryAddress); 
    
    let deployCreateArgs = await getDeployCreateArgs(contractName, constructorArgs, txParam);
    
    //deploy the bytecode using the factory
    let receipt = await factory.deployCreate(...deployCreateArgs);
    let res = {
        logicAddress: await getEventVar(receipt, DeployedRawEvent, contractAddrVar),
        proxyAddress: null,
        proxySalt: await getSalt(contractName)
    };
    //multicall deployProxy. upgradeProxy
    let multiCallArgs = await getDeployUpgradeableMultiCallArgs(defaultFactoryName, res.proxySalt, res.logicAddress, txParam)    
    receipt = await factory.multiCall(...multiCallArgs);
    res.proxyAddress = await getEventVar(receipt, DeployedProxyEvent, contractAddrVar);
    return res
}

async function upgradeProxy(contractName, factoryAddress){
    //let logicContract = await artifacts.readArtifact(logicContractPath + ":" + logicContractName);
    let MadnetFactory = await artifacts.require(defaultFactoryName);
    let factory = await MadnetFactory.at(factoryAddress); 
    let logicContractInterface = await ethers.getContractFactory(contractName);
    let deployBCode = await logicContractInterface.getDeployTransaction(factoryAddress);
    //deploy the new logic contract from the factory
    let receipt = await factory.deployCreate(deployBCode.data);
    //instantiate the return object 
    let res = {
        logicAddress: await getEventVar(receipt, DeployedRawEvent, contractAddrVar),
        proxySalt: await getSalt(contractName)
    };
    //upgrade the proxy 
    receipt = await factory.upgradeProxy(res.proxySalt, res.logicAddress);
    return res;
}

async function deployStatic(contractName, factoryAddress){
    let MadnetFactory = await artifacts.require(defaultFactoryName);
    let logicContract = await artifacts.require(contractName);
    let factory = await MadnetFactory.at(factoryAddress); 
    let deployBCode = logicContract.bytecode
    let receipt = await factory.deployTemplate(deployBCode);
    let res = {
        templateAddress: await getEventVar(receipt, deployedTemplateEvent, contractAddrVar),
        metaAddress: null,
        metaSalt: await getSalt(contractName)
    };
    receipt = await factory.deployStatic(res.metaSalt, "0x");
    res.metaAddress = await getEventVar(receipt, deployedStaticEvent, contractAddrVar);
    return res;
}

async function getFullyQaulifiedName(contractName) {
    let artifactPaths = await artifacts.getAllFullyQualifiedNames();
    for (let i = 0; i < artifactPaths.length; i++){
        if (artifactPaths[i].split(":")[1] === contractName){
            return String(artifactPaths[i]);
        } 
    }
    return undefined;
}

function extractPath(qualifiedName) {
    return qualifiedName.split(":")[0];
}

async function getDeployCreateArgs(contractName, constructorArgs, txParam){
    //get an instance of the logic contract interface
    let contractInterface = await ethers.getContractFactory(contractName);
    //get the deployment bytecode from the interface 
    let deployBCode = await contractInterface.getDeployTransaction(constructorArgs);
    let deployCreateArgs;
    if(txParam === undefined){
        deployCreateArgs = [deployBCode.data];
    } else{
        deployCreateArgs = [deployBCode.data, txParam];
    }
    return deployCreateArgs;
}

async function getDeployUpgradeableMultiCallArgs(factoryName, Salt, logicAddress, txParam){
    let MNFactory = await ethers.getContractFactory(factoryName);
    let deployProxy = await MNFactory.interface.encodeFunctionData("deployProxy", [Salt]);    
    let upgradeProxy = await MNFactory.interface.encodeFunctionData("upgradeProxy", [Salt, logicAddress]);
    let res;
    if(txParam === undefined){
        res = [[deployProxy, upgradeProxy]];
    } else{
        res = [[deployProxy, upgradeProxy], txParam];
    }
    return res;
}

async function getSalt(contractName){
    let qualifiedName = await getFullyQaulifiedName(contractName);
    let buildInfo = await artifacts.getBuildInfo(qualifiedName);
    let filePath = await extractPath(qualifiedName);
    //buildInfo.resolve()
    let contractPath = qualifiedName.split(":")[0]
    //wrap this in a try catch block
    let salt = buildInfo.output.contracts[filePath][contractName].devdoc["custom:salt"];
    return ethers.utils.formatBytes32String(salt.toString());
}

async function getDeployType(contractName){
    let qualifiedName = await getFullyQaulifiedName(contractName);
    let buildInfo = await artifacts.getBuildInfo(qualifiedName);
    let filePath = await extractPath(qualifiedName);
    //buildInfo.resolve()
    let contractPath = qualifiedName.split(":")[0]
    //wrap this in a try catch block
    return buildInfo.output.contracts[filePath][contractName].devdoc["custom:deployType"];
}

function getEventVar(receipt, eventName, varName){
    let result 
    for (let i = 0; i < receipt["logs"].length; i++) {
        //look for the event
        if(receipt["logs"][i]["event"] == eventName){
            //extract the deployed mock logic contract address from the event
            result = receipt["logs"][i]["args"][varName];
            //exit the loop
            break;
        }
    }
    return result;
}

module.exports = {deployUpgradeable, upgradeProxy, deployStatic};