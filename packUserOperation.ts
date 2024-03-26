import { pad, toHex, Hex, concat } from "viem"

export function toPackedUserOperation(
    unpackedUserOperation: any
) {
    return {
        sender: unpackedUserOperation.sender,
        nonce: unpackedUserOperation.nonce,
        initCode: getInitCode(unpackedUserOperation),
        callData: unpackedUserOperation.callData,
        accountGasLimits: getAccountGasLimits(unpackedUserOperation),
        preVerificationGas: unpackedUserOperation.preVerificationGas,
        gasFees: getGasLimits(unpackedUserOperation),
        paymasterAndData: getPaymasterAndData(unpackedUserOperation),
        signature: unpackedUserOperation.signature
    }
}

export function getInitCode(unpackedUserOperation: any) {
    return unpackedUserOperation.factory
        ? concat([
              unpackedUserOperation.factory,
              unpackedUserOperation.factoryData || ("0x" as Hex)
          ])
        : "0x"
}

export function getAccountGasLimits(
    unpackedUserOperation: any
) {
    return concat([
        pad(toHex(unpackedUserOperation.verificationGasLimit), {
            size: 16
        }),
        pad(toHex(unpackedUserOperation.callGasLimit), { size: 16 })
    ])
}

export function getGasLimits(unpackedUserOperation: any) {
    return concat([
        pad(toHex(unpackedUserOperation.maxPriorityFeePerGas), {
            size: 16
        }),
        pad(toHex(unpackedUserOperation.maxFeePerGas), { size: 16 })
    ])
}

export function getPaymasterAndData(
    unpackedUserOperation: any
) {
    return unpackedUserOperation.paymaster
        ? concat([
              unpackedUserOperation.paymaster,
              pad(
                  toHex(
                      unpackedUserOperation.paymasterVerificationGasLimit || 0n
                  ),
                  {
                      size: 16
                  }
              ),
              pad(toHex(unpackedUserOperation.paymasterPostOpGasLimit || 0n), {
                  size: 16
              }),
              unpackedUserOperation.paymasterData || ("0x" as Hex)
          ])
        : "0x"
}
