import fs from "fs";
import { env } from "./constants";
import { getDefaultFactoryAddress } from "./factoryStateUtils";
export interface DeployArgs {
    [key: string]: any
}

export async function readDeploymentArgs() {
    //this output object allows dynamic addition of fields 
    let output: DeployArgs = {};
    let rawData = fs.readFileSync(`./deployments/${env}/deploymentArgs.json`);
    output = await JSON.parse(rawData.toString("utf8"));
    return output;
}

export async function getDeploymentConstructorArgs(fullName:string){
    let output:Array<string> = [];
    //get the deployment args
    let deploymentArgs:DeployArgs = await readDeploymentArgs();
    let args = deploymentArgs.constructorArgs[fullName]
    for(let arg of args){
        let name:string = Object.keys(arg)[0];
        switch(name){
            case "factory_":
                let address = await getDefaultFactoryAddress();
                output.push(address);
                break;
            case "_factory":
                address = await getDefaultFactoryAddress();
                output.push(address);
                break;
            case "factory":
                address = await getDefaultFactoryAddress();
                output.push(address);
                break;
            default:
                output.push(arg[name]);
                break;
        }
    }
    return output;
} 

export async function getDeploymentInitializerArgs(fullName:string){
    let output:Array<string> = [];
    //get the deployment args
    let deploymentArgs:DeployArgs = await readDeploymentArgs();
    let args = deploymentArgs.initializerArgs[fullName]
    if(args !== undefined){
        for(let arg of args){
            let name:string = Object.keys(arg)[0];
            switch(name){
                case "factory_":
                    let address = await getDefaultFactoryAddress();
                    output.push(address);
                    break;
                case "_factory":
                    address = await getDefaultFactoryAddress();
                    output.push(address);
                    break;
                case "factory":
                    address = await getDefaultFactoryAddress();
                    output.push(address);
                    break;
                default:
                    output.push(arg[name]);
                    break;
            }
        }
    } else {
        output = [];
    }
    return output;
}



