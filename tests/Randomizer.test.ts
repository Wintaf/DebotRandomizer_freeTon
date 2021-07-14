import { expect } from 'chai';

import { configs, networks } from '../configs';
import { createClient } from '../utils/create-client';
import { waitForTransaction } from '../utils/wait-for-transaction';
import { runMethod, buildCall } from '../utils/contract';
import { IMultisigWallet, MultisigWalletWrapper } from '../wrappers/multisig';

import { deployRandomizer } from './Randomizer.deploy';
import { deployRandomizerDebot } from './RandomizerDebot.deploy';
import pkgRandomizer from '../ton-packages/Randomizer.package';

import type { KeyPair, TonClient } from '@tonclient/core';
import type { TAddress } from '../types';


describe("Randomizer tests", () => {
  let client: TonClient;
  let wallet: IMultisigWallet;
  let addrRandomizer: TAddress;
  let keys: KeyPair;

  before(async () => {
    const config = configs[networks.LOCAL];
    client = createClient(config.url);
    wallet = new MultisigWalletWrapper(client, config.multisig);
    // Temporary KeyPair for testing
    keys = await client.crypto.generate_random_sign_keys();
  });

  it("deploy Randomizer", async () => {
    addrRandomizer = await deployRandomizer(client, wallet, keys);
    console.log('Randomizer address:', addrRandomizer);

    const addrRandomizerDebot: TAddress
      = await deployRandomizerDebot(client, wallet, keys, addrRandomizer);

    console.log('RandomizerDebot address:', addrRandomizerDebot);
    console.log('Выполните в консоле команду ниже, чтобы запустить дебота');
    console.log('tonos-cli --url http://127.0.0.1 debot fetch', addrRandomizerDebot);
  });

  const { abi } = pkgRandomizer;

  const callRandomizer = async (nameFunction, input) => {
    const payload = await buildCall(client, abi, nameFunction, input);

    const { transaction } = await wallet.sendTransaction({
      dest: addrRandomizer,
      value: 1_000_000_000,
      bounce: false,
      payload,
    })

    const filter = {
      account_addr: { eq: addrRandomizer },
      now: { ge: transaction.now },
      aborted: { eq: false },
    };
    await waitForTransaction(client, filter, 'now aborted');
  }

  const runGetLastRandom = async (who: TAddress) =>
    runMethod(client, abi, addrRandomizer, 'getLastRandom', { who });

/*
  describe("addition", () => {

    const callAddition = async (x, y) =>
      callCalculator2('addition', { x, y });

    it("should calculate 2 + 3 as 5", async () => {
      await callAddition(2, 3);
      const res = await runGetLastOperation(wallet.getAddress());
      const { name, x, y, result } = res?.value?.value0;
      const nameOperation = Buffer.from(name, 'hex').toString('utf-8');

      expect(+x).to.equal(2);
      expect(+y).to.equal(3);
      expect(+result).to.equal(5);
      expect(nameOperation).to.equal('addition');
    });

    it("should not calculate a + b", async () => {
      try {
        await callAddition('a', 'b');
      } catch (ex) {
        expect(ex).to
        .be.an.instanceOf(Error).and
        .have.property('code', 306);
      }
    });
  });

  describe("subtraction", () => {

    const callSubtraction = async (x, y) =>
      callCalculator2('subtraction', { x, y });

    it("should calculate 5 - 3 as 2", async () => {
      await callSubtraction(5, 3);
      const res = await runGetLastOperation(wallet.getAddress());
      const { name, x, y, result } = res?.value?.value0;
      const nameOperation = Buffer.from(name, 'hex').toString('utf-8');

      expect(+x).to.equal(5);
      expect(+y).to.equal(3);
      expect(+result).to.equal(2);
      expect(nameOperation).to.equal('subtraction');

    });

    it("should not calculate a - 5", async () => {
      try {
        await callSubtraction('a', 3);
      } catch (ex) {
        expect(ex).to
        .be.an.instanceOf(Error).and
        .have.property('code', 306);
      }
    });

  });

  // it("yet another test", async () => {
  // });
*/
});
