import { predictAddress, deploy, TDeployParams } from '../utils/deploy';
import { IMultisigWallet } from '../wrappers/multisig';
import pkgRandomizerDebot from '../ton-packages/RandomizerDebot.package';

import type { KeyPair, TonClient } from '@tonclient/core';
import type { TAddress } from '../types';


export
const deployRandomizerDebot = async (
  client: TonClient,
  wallet: IMultisigWallet,
  keys: KeyPair,
  addrRandomizer: TAddress,
) => {
  const deployParams: TDeployParams = {
    keys,
    tonPackage: pkgRandomizerDebot,
    input: { addrRandomizer },
  };

  const address: TAddress = await predictAddress(client, deployParams);

  await wallet.sendTransaction({
    dest: address,
    value: 1_000_000_000,
    bounce: false,
  })

  await deploy(client, deployParams);
  const strAbi = JSON.stringify(pkgRandomizerDebot.abi);
  const dabi = Buffer.from(strAbi, 'utf-8').toString('hex');
  await client.processing.process_message({
    message_encode_params: {
      abi: { type: "Contract", value: pkgRandomizerDebot.abi },
      address,
      signer: { type: 'Keys', keys },
      call_set: { function_name: 'setABI', input: { dabi }},
    },
    send_events: true,
  });

  return address;
}
