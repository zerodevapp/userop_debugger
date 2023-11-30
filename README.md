
# README.md

  

## User Operation Debugger

  

This shell script is a utility for debugging User Operations from ERC-4337. It is a wrapper around the `cast` command from Foundry and `jq` for parsing JSON.

  

### Dependencies

  

-  `jq`: A lightweight and flexible command-line JSON processor.

-  `cast`: A command-line tool from [Foundry](https://book.getfoundry.sh/getting-started/installation) for Ethereum smart contract interaction.

  

## Setup Instructions

  

Before running the script, you need to set up a `config.sh` file in the same directory as `userop_debug.sh`. This file should define the `INFURA_API_KEY` environment variable, which is used to interact with EVM chain nodes via the Infura service. You can also use other RPC services of your choosing.

  

Here is a sample `config.sh`:

  

```bash

#!/bin/bash

export  INFURA_API_KEY="your_infura_api_key"

```

  

Replace `"your_infura_api_key"` with your actual Infura API key.

  

After creating `config.sh`, you can run the script as described in the Usage section. Make sure to give execute permissions to `userop_debug.sh` by running `chmod +x userop_debug.sh`.

  

## Configuration

  

The script uses two arrays, `CHAIN_IDS` and `NODE_URLS`, to map chain IDs to Infura node URLs. By default, it supports Mainnet (chain ID 1) and Goerli (chain ID 5). If you need to interact with other Ethereum chains, you can add their chain IDs and RPC URLs to these arrays.

  

For example, to add support for Polygon (chain ID 137), you could modify the arrays like this:

  

```bash

local  -a  CHAIN_IDS=(1  5 137)

local  -a  NODE_URLS://mainnet.infura.io/v3/${INFURA_API_KEY}"

"https://goerli.infura.io/v3/${INFURA_API_KEY}"

"https://rpc-mainnet.matic.quiknode.pro"

)

```
  

### Usage

  

```bash

./userop_debug.sh  '<userOpJson>' <chainId>

```

  

-  `<userOpJson>`: A JSON string representing the user operation.

-  `<chainId>`: The ID of the EVM chain to interact with.

  

### Functionality

  

The script performs the following steps:

  

1. Checks if `jq` and `cast` are installed.

2. Extracts fields from the provided JSON string.

3. Determines the node URL based on the provided chain ID.

4. Executes a `cast` call from the EntryPoint to the extracted sender and call data to verify the UserOp callData.

5. Constructs `cast` call data for the `handleOps` function.

6. Executes a `cast` call with the constructed call data to the EntryPoint contract.

  

### Note

  

This script is intended for debugging purposes. Always ensure you are interacting with the correct EVM chain and smart contracts.
