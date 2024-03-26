#!/bin/bash
set -euo pipefail

source config.sh

readonly ENTRYPOINT_ADDRESS="0x0000000071727De22E5E9d8BAf0edAc6f37da032"
readonly SIMULATION_CONTRACT_ADDRESS="0x5465089caC0f710BA895E2711491F1D8AfB7D245"

check_dependency() {
    local DEPENDENCY="$1"
    if ! command -v "$DEPENDENCY" &>/dev/null; then
        printf >&2 "%s could not be found. Please install it and try again.\n" "$DEPENDENCY"
        exit 1
    fi
}

get_node_url_for_chain_id() {
    local LOCAL_CHAIN_ID="$1"
    local -a CHAIN_IDS=(1 5 80001 11155111 137 11155420 10)
    local -a NODE_URLS=(
    "https://mainnet.infura.io/v3/${INFURA_API_KEY}"
    "https://goerli.infura.io/v3/${INFURA_API_KEY}"
    "https://polygon-mumbai.infura.io/v3/${INFURA_API_KEY}"
    "https://sepolia.infura.io/v3/${INFURA_API_KEY}"
    "https://polygon-mainnet.infura.io/v3/${INFURA_API_KEY}"
    "https://optimism-sepolia.infura.io/v3/${INFURA_API_KEY}"
    "https://optimism-mainnet.infura.io/v3/${INFURA_API_KEY}"
)

    for ((i=0; i<${#CHAIN_IDS[@]}; i++)); do
        if [[ "${CHAIN_IDS[$i]}" == "$LOCAL_CHAIN_ID" ]]; then
            printf "%s\n" "${NODE_URLS[$i]}"
            return
        fi
    done

    printf >&2 "Unsupported chainId: %s\n" "$LOCAL_CHAIN_ID"
    exit 1
}

execute_cast_call_with_sender_data_url() {
    local SENDER="$1" CALL_DATA="$2" NODE_URL="$3"
    cast call "$SENDER" "$CALL_DATA" -f "$ENTRYPOINT_ADDRESS" -r "$NODE_URL" --trace
    # echo cast call "$SENDER" "$CALL_DATA" -f "$ENTRYPOINT_ADDRESS" -r "$NODE_URL" --trace
}

extract_field_value_from_json() {
    echo "$USER_OP_JSON" | jq -r --arg FIELD "$1" '.[$FIELD]'
}

check_dependency jq
check_dependency cast

if [[ $# -lt 2 ]]; then
    printf >&2 "Usage: %s '<userOpJson>' <chainId>\n" "$0"
    exit 1
fi

# readonly UNPACKED_USER_OP_JSON="$1"
readonly USER_OP_JSON=$(npx ts-node cli.ts --operation $1)
readonly CHAIN_ID="$2"

SENDER=$(extract_field_value_from_json 'sender')
NONCE=$(extract_field_value_from_json 'nonce')
INIT_CODE=$(extract_field_value_from_json 'initCode')
CALL_DATA=$(extract_field_value_from_json 'callData')
ACCOUNT_GAS_LIMITS=$(extract_field_value_from_json 'accountGasLimits')
PRE_VERIFICATION_GAS=$(extract_field_value_from_json 'preVerificationGas')
GAS_FEES=$(extract_field_value_from_json 'gasFees')
PAYMASTER_AND_DATA=$(extract_field_value_from_json 'paymasterAndData')
SIGNATURE=$(extract_field_value_from_json 'signature')

NODE_URL=$(get_node_url_for_chain_id "$CHAIN_ID")

# execute_cast_call_with_sender_data_url "$SENDER" "$CALL_DATA" "$NODE_URL"

SIMULATE_VALIDATION_CALL_DATA=$(cast calldata 'simulateValidation((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes))' "($SENDER,$NONCE,$INIT_CODE,$CALL_DATA,$ACCOUNT_GAS_LIMITS,$PRE_VERIFICATION_GAS,$GAS_FEES,$PAYMASTER_AND_DATA,$SIGNATURE)")

SIMULATE_ENTRYPOINT_CALL_DATA=$(cast calldata 'simulateEntryPoint(address,bytes[])' "$ENTRYPOINT_ADDRESS" [$SIMULATE_VALIDATION_CALL_DATA])
echo $SIMULATE_ENTRYPOINT_CALL_DATA

execute_cast_call_with_sender_data_url "$SIMULATION_CONTRACT_ADDRESS" "$SIMULATE_ENTRYPOINT_CALL_DATA" "$NODE_URL"
