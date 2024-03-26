#!/bin/bash
set -euo pipefail

source config.sh

readonly ENTRYPOINT_ADDRESS="0x5ff137d4b0fdcd49dca30c7cf57e578a026d2789"

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
    echo $BLOCK
    if [ -z "$BLOCK" ]; then
      BLOCK="latest"
    fi
    cast call "$SENDER" "$CALL_DATA" -f "$ENTRYPOINT_ADDRESS" -r "$NODE_URL" --block "$BLOCK" --trace
    # echo cast call "$SENDER" "$CALL_DATA" -f "$ENTRYPOINT_ADDRESS" -r "$NODE_URL" -b "$BLOCK" --trace
}

extract_field_value_from_json() {
    echo "$USER_OP_JSON" | jq -r --arg FIELD "$1" '.[$FIELD]'
}

check_dependency jq
check_dependency cast

if [[ $# -lt 2 ]]; then
    printf >&2 "Usage: %s '<userOpJson>' <chainId> <block>\n" "$0"
    exit 1
fi

readonly USER_OP_JSON="$1"
readonly CHAIN_ID="$2"
BLOCK="${3:-"latest"}"

INIT_CODE=$(extract_field_value_from_json 'initCode')
SENDER=$(extract_field_value_from_json 'sender')
NONCE=$(extract_field_value_from_json 'nonce')
CALL_DATA=$(extract_field_value_from_json 'callData')
SIGNATURE=$(extract_field_value_from_json 'signature')
MAX_FEE_PER_GAS=$(extract_field_value_from_json 'maxFeePerGas')
MAX_PRIORITY_FEE_PER_GAS=$(extract_field_value_from_json 'maxPriorityFeePerGas')
PAYMASTER_AND_DATA=$(extract_field_value_from_json 'paymasterAndData')
CALL_GAS_LIMIT=$(extract_field_value_from_json 'callGasLimit')
VERIFICATION_GAS_LIMIT=$(extract_field_value_from_json 'verificationGasLimit')
PRE_VERIFICATION_GAS=$(extract_field_value_from_json 'preVerificationGas')

NODE_URL=$(get_node_url_for_chain_id "$CHAIN_ID")

execute_cast_call_with_sender_data_url "$SENDER" "$CALL_DATA" "$NODE_URL"

# CAST_CALL_DATA=$(cast calldata 'simulateHandleOp((address,uint256,bytes,bytes,uint256,uint256,uint256,uint256,uint256,bytes,bytes),address,bytes)' "($SENDER,$NONCE,$INIT_CODE,$CALL_DATA,$CALL_GAS_LIMIT,$VERIFICATION_GAS_LIMIT,$PRE_VERIFICATION_GAS,$MAX_FEE_PER_GAS,$MAX_PRIORITY_FEE_PER_GAS,$PAYMASTER_AND_DATA,$SIGNATURE)" "$SENDER" "$CALL_DATA")

CAST_CALL_DATA=$(cast calldata 'simulateValidation((address,uint256,bytes,bytes,uint256,uint256,uint256,uint256,uint256,bytes,bytes))' "($SENDER,$NONCE,$INIT_CODE,$CALL_DATA,$CALL_GAS_LIMIT,$VERIFICATION_GAS_LIMIT,$PRE_VERIFICATION_GAS,$MAX_FEE_PER_GAS,$MAX_PRIORITY_FEE_PER_GAS,$PAYMASTER_AND_DATA,$SIGNATURE)")

execute_cast_call_with_sender_data_url "$ENTRYPOINT_ADDRESS" "$CAST_CALL_DATA" "$NODE_URL"