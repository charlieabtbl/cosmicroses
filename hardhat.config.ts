import { HardhatUserConfig } from "hardhat/config"
import "@shardlabs/starknet-hardhat-plugin"

const config: HardhatUserConfig = {
    solidity: "0.8.9",
    starknet: {
        //dockerizedVersion: "0.10.0",
        venv: "active",
        //network: "devnet",
        network: "integrated-devnet",
        wallets: {
            OpenZeppelin: {
                accountName: "OpenZeppelin",
                modulePath: "starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount",
                accountPath: "~/.starknet_accounts",
            },
        },
    },
    networks: {
        devnet: {
            url: "http://127.0.0.1:5050",
        },
        integratedDevnet: {
            url: "http://127.0.0.1:5050",
            //venv: "active",
            // dockerizedVersion: "<DEVNET_VERSION>",
        },
    },
    // paths: {
    //     cairoPaths: ["env/lib/python3.9/site-packages"]
    // }
}

export default config