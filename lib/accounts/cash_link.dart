import 'dart:typed_data';

import 'package:cash_link/accounts/constants.dart';
import 'package:cash_link/cash_link_program.dart';
import 'package:cash_link/utils/endian.dart';
import 'package:cash_link/utils/struct_reader.dart';
import 'package:solana/base58.dart';
import 'package:solana/dto.dart' as dto;
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

class CashLinkAccount {
  const CashLinkAccount({
    required this.address,
    required this.cashLink,
  });
  final String address;
  final CashLink cashLink;
}

class CashLink {
  const CashLink({
    required this.key,
    required this.state,
    required this.amount,
    required this.feeBps,
    required this.fixedFee,
    required this.baseFeeToRedeem,
    required this.rentFeeToRedeem,
    required this.remainingAmount,
    required this.distributionType,
    required this.sender,
    required this.authority,
    required this.passKey,
    required this.mint,
    this.expiresAt,
    required this.totalRedemptions,
    required this.maxNumRedemptions,
    required this.minAmount,
    required this.fingerprintEnabled,
  });

  factory CashLink.fromBinary(List<int> sourceBytes) {
    final bytes = Int8List.fromList(sourceBytes);
    final reader = StructReader(bytes.buffer)..skip(1);
    final authority = base58encode(reader.nextBytes(32));
    final state = CashLinkStateExtension.fromId(reader.nextBytes(1).first);
    final amount = decodeBigInt(reader.nextBytes(8), Endian.little);
    final feeBps = decodeBigInt(reader.nextBytes(2), Endian.little);
    final fixedFee = decodeBigInt(reader.nextBytes(8), Endian.little);
    final baseFeeToRedeem = decodeBigInt(reader.nextBytes(8), Endian.little);
    final rentFeeToRedeem = decodeBigInt(reader.nextBytes(8), Endian.little);
    final remainingAmount = decodeBigInt(reader.nextBytes(8), Endian.little);
    final distributionType =
        CashLinkDistributionTypeExtension.fromId(reader.nextBytes(1).first);
    final sender = base58encode(reader.nextBytes(32));
    final expiresAt = reader.nextBytes(1).first == 1
        ? decodeBigInt(reader.nextBytes(8), Endian.little)
        : null;
    final mint = base58encode(reader.nextBytes(32));

    final totalRedemptions = decodeBigInt(reader.nextBytes(2), Endian.little);
    final maxNumRedemptions = decodeBigInt(reader.nextBytes(2), Endian.little);
    return CashLink(
      key: AccountKey.cashLink,
      authority: authority,
      state: state,
      amount: amount,
      feeBps: feeBps,
      fixedFee: fixedFee,
      baseFeeToRedeem: baseFeeToRedeem,
      rentFeeToRedeem: rentFeeToRedeem,
      remainingAmount: remainingAmount,
      distributionType: distributionType,
      sender: sender,
      expiresAt: expiresAt != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (expiresAt * BigInt.from(1000)).toInt())
          : null,
      mint: mint,
      totalRedemptions: totalRedemptions,
      maxNumRedemptions: maxNumRedemptions,
      minAmount: decodeBigInt(reader.nextBytes(8), Endian.little),
      fingerprintEnabled: reader.nextBytes(1).first == 1,
      passKey: base58encode(reader.nextBytes(32)),
    );
  }

  static const prefix = 'cash';

  final AccountKey key;
  final String authority;
  final String passKey;
  final CashLinkState state;
  final BigInt amount;
  final BigInt feeBps;
  final BigInt fixedFee;
  final BigInt baseFeeToRedeem;
  final BigInt rentFeeToRedeem;
  final BigInt remainingAmount;
  final CashLinkDistributionType distributionType;
  final String sender;
  final DateTime? expiresAt;
  final String mint;
  final BigInt totalRedemptions;
  final BigInt maxNumRedemptions;
  final BigInt minAmount;
  final bool fingerprintEnabled;

  static Future<Ed25519HDPublicKey> pda(Ed25519HDPublicKey passKey) {
    final programID = Ed25519HDPublicKey.fromBase58(CashLinkProgram.programId);
    return Ed25519HDPublicKey.findProgramAddress(seeds: [
      CashLink.prefix.codeUnits,
      passKey.bytes,
    ], programId: programID);
  }
}

extension CashLinkExtension on RpcClient {
  Future<CashLinkAccount?> getCashLinkAccountByReference(
      {required Ed25519HDPublicKey passKey,
      Commitment commitment = Commitment.finalized}) async {
    final programAddress = await CashLink.pda(passKey);
    return getCashLinkAccount(
      address: programAddress,
      commitment: commitment,
    );
  }

  Future<CashLinkAccount?> getCashLinkAccount(
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
      return CashLinkAccount(
        address: address.toBase58(),
        cashLink: CashLink.fromBinary(data.data),
      );
    } else {
      return null;
    }
  }

  Future<List<CashLinkAccount>> findCashLinks(
      {CashLinkState? state,
      String? authority,
      Commitment commitment = Commitment.finalized}) async {
    final filters = [
      dto.ProgramDataFilter.memcmp(
          offset: 0, bytes: ByteArray.u8(AccountKey.cashLink.id).toList()),
      if (authority != null)
        dto.ProgramDataFilter.memcmpBase58(offset: 1, bytes: authority),
      if (state != null)
        dto.ProgramDataFilter.memcmp(
            offset: 33, bytes: ByteArray.u8(state.id).toList()),
    ];
    final accounts = await getProgramAccounts(
      CashLinkProgram.programId,
      encoding: dto.Encoding.base64,
      filters: filters,
      commitment: commitment,
    );
    return accounts
        .map(
          (acc) => CashLinkAccount(
            address: acc.pubkey,
            cashLink: CashLink.fromBinary(
                (acc.account.data as dto.BinaryAccountData).data),
          ),
        )
        .toList();
  }

  Future<List<CashLinkAccount>> findCashLinkByAuthority(
      String authority) async {
    return findCashLinks(authority: authority);
  }
}
