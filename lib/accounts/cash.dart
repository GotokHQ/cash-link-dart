import 'dart:typed_data';

import 'package:cash/accounts/constants.dart';
import 'package:cash/cash_program.dart';
import 'package:cash/utils/endian.dart';
import 'package:cash/utils/struct_reader.dart';
import 'package:solana/base58.dart';
import 'package:solana/dto.dart' as dto;
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

class CashAccount {
  const CashAccount({
    required this.address,
    required this.cash,
  });
  final String address;
  final Cash cash;
}

class Cash {
  const Cash({
    required this.key,
    required this.state,
    required this.amount,
    required this.feeBps,
    required this.fixedFee,
    required this.baseFeeToRedeem,
    required this.rentFeeToRedeem,
    required this.remainingAmount,
    required this.distributionType,
    required this.owner,
    required this.authority,
    this.passKey,
    required this.mint,
    required this.totalRedemptions,
    required this.maxNumRedemptions,
    required this.minAmount,
    required this.fingerprintEnabled,
    required this.totalWeightPpm,
  });

  factory Cash.fromBinary(List<int> sourceBytes) {
    final bytes = Int8List.fromList(sourceBytes);
    final reader = StructReader(bytes.buffer)..skip(1);
    final authority = base58encode(reader.nextBytes(32));
    final state = CashStateExtension.fromId(reader.nextBytes(1).first);
    final amount = decodeBigInt(reader.nextBytes(8), Endian.little);
    final feeBps = decodeBigInt(reader.nextBytes(2), Endian.little);
    final fixedFee = decodeBigInt(reader.nextBytes(8), Endian.little);
    final baseFeeToRedeem = decodeBigInt(reader.nextBytes(8), Endian.little);
    final rentFeeToRedeem = decodeBigInt(reader.nextBytes(8), Endian.little);
    final remainingAmount = decodeBigInt(reader.nextBytes(8), Endian.little);
    final distributionType =
        CashLinkDistributionTypeExtension.fromId(reader.nextBytes(1).first);
    final owner = base58encode(reader.nextBytes(32));
    final mint = base58encode(reader.nextBytes(32));

    final totalRedemptions = decodeBigInt(reader.nextBytes(2), Endian.little);
    final maxNumRedemptions = decodeBigInt(reader.nextBytes(2), Endian.little);
    final minAmount = decodeBigInt(reader.nextBytes(8), Endian.little);
    final fingerprintEnabled = reader.nextBytes(1).first == 1;
    final passKey = reader.nextBytes(1).first == 1
        ? base58encode(reader.nextBytes(32))
        : null;
    final totalWeightPpm = decodeBigInt(reader.nextBytes(4), Endian.little);
    return Cash(
      key: AccountKey.cash,
      authority: authority,
      state: state,
      amount: amount,
      feeBps: feeBps,
      fixedFee: fixedFee,
      baseFeeToRedeem: baseFeeToRedeem,
      rentFeeToRedeem: rentFeeToRedeem,
      remainingAmount: remainingAmount,
      distributionType: distributionType,
      owner: owner,
      mint: mint,
      totalRedemptions: totalRedemptions,
      maxNumRedemptions: maxNumRedemptions,
      minAmount: minAmount,
      fingerprintEnabled: fingerprintEnabled,
      passKey: passKey,
      totalWeightPpm: totalWeightPpm,
    );
  }

  static const prefix = 'cash';

  final AccountKey key;
  final String authority;
  final String? passKey;
  final CashState state;
  final BigInt amount;
  final BigInt feeBps;
  final BigInt fixedFee;
  final BigInt baseFeeToRedeem;
  final BigInt rentFeeToRedeem;
  final BigInt remainingAmount;
  final CashLinkDistributionType distributionType;
  final String owner;
  final String mint;
  final BigInt totalRedemptions;
  final BigInt maxNumRedemptions;
  final BigInt minAmount;
  final BigInt totalWeightPpm;
  final bool fingerprintEnabled;
}

extension CashLinkExtension on RpcClient {
  Future<CashAccount?> cashAccount(
      {required String reference,
      Commitment commitment = Commitment.finalized}) async {
    final programAddress = await CashProgram.cashAccount(reference);
    return getCashAccount(
      address: programAddress,
      commitment: commitment,
    );
  }

  Future<CashAccount?> getCashAccount(
      {required Ed25519HDPublicKey address,
      Commitment commitment = Commitment.finalized}) async {
    final result = await getAccountInfo(
      address.toBase58(),
      encoding: dto.Encoding.base64,
      commitment: commitment,
    );
    if (result.value?.data == null) {
      return null;
    }

    final data = result.value!.data;

    if (data is dto.BinaryAccountData) {
      return CashAccount(
        address: address.toBase58(),
        cash: Cash.fromBinary(data.data),
      );
    } else {
      return null;
    }
  }

  Future<List<CashAccount>> findCashAccounts({
    CashState? state,
    String? authority,
    Commitment commitment = Commitment.finalized,
  }) async {
    final filters = [
      dto.ProgramDataFilter.memcmp(
          offset: 0, bytes: ByteArray.u8(AccountKey.cash.id).toList()),
      if (authority != null)
        dto.ProgramDataFilter.memcmpBase58(offset: 1, bytes: authority),
      if (state != null)
        dto.ProgramDataFilter.memcmp(
            offset: 33, bytes: ByteArray.u8(state.id).toList()),
    ];
    final accounts = await getProgramAccounts(
      CashProgram.programId,
      encoding: dto.Encoding.base64,
      filters: filters,
      commitment: commitment,
    );
    return accounts
        .map(
          (acc) => CashAccount(
            address: acc.pubkey,
            cash: Cash.fromBinary(
                (acc.account.data as dto.BinaryAccountData).data),
          ),
        )
        .toList();
  }

  Future<List<CashAccount>> findCashAccountByAuthority(String authority) async {
    return findCashAccounts(authority: authority);
  }
}
