import 'dart:typed_data';

import 'package:cash_link/accounts/constants.dart';
import 'package:cash_link/cash_link_program.dart';
import 'package:cash_link/utils/endian.dart';
import 'package:cash_link/utils/struct_reader.dart';
import 'package:solana/base58.dart';
import 'package:solana/solana.dart';
import 'package:solana/dto.dart' as dto;
import 'package:solana/encoder.dart';

class RedemptionAccount {
  const RedemptionAccount({
    required this.address,
    required this.redemption,
  });
  final String address;
  final Redemption redemption;
}

class Redemption {
  const Redemption({
    required this.key,
    required this.cashLink,
    required this.wallet,
    required this.redeemedAt,
    required this.amount,
  });

  static const prefix = 'redeem';

  factory Redemption.fromBinary(List<int> sourceBytes) {
    final bytes = Int8List.fromList(sourceBytes);
    final reader = StructReader(bytes.buffer)..skip(1);
    final cashLink = base58encode(reader.nextBytes(32));
    final wallet = base58encode(reader.nextBytes(32));
    final redeemedAt = DateTime.fromMillisecondsSinceEpoch(
        (decodeBigInt(reader.nextBytes(8), Endian.little) * BigInt.from(1000))
            .toInt());
    final amount = decodeBigInt(reader.nextBytes(8), Endian.little);
    return Redemption(
      key: AccountKey.redemption,
      cashLink: cashLink,
      wallet: wallet,
      redeemedAt: redeemedAt,
      amount: amount,
    );
  }

  final AccountKey key;
  final String cashLink;
  final String wallet;
  final DateTime redeemedAt;
  final BigInt amount;

  static Future<Ed25519HDPublicKey> pda(
      Ed25519HDPublicKey cashLink, String reference) {
    final programID = Ed25519HDPublicKey.fromBase58(CashLinkProgram.programId);
    return Ed25519HDPublicKey.findProgramAddress(
      seeds: [
        Redemption.prefix.codeUnits,
        cashLink.bytes,
        base58decode(reference),
      ],
      programId: programID,
    );
  }
}

extension RedemptionExtension on RpcClient {
  Future<RedemptionAccount?> getRedemptionAccountByCashLink(
      {required Ed25519HDPublicKey cashLinkPda,
      required String reference,
      Commitment commitment = Commitment.finalized}) async {
    final programAddress = await Redemption.pda(cashLinkPda, reference);
    return getRedemptionAccount(
        address: programAddress, commitment: commitment);
  }

  Future<RedemptionAccount?> getRedemptionAccount(
      {required Ed25519HDPublicKey address,
      Commitment commitment = Commitment.finalized}) async {
    final result = await getAccountInfo(address.toBase58(),
        encoding: dto.Encoding.base64, commitment: commitment);
    if (result.value?.data == null) {
      return null;
    }

    final data = result.value!.data;

    if (data is dto.BinaryAccountData) {
      return RedemptionAccount(
        address: address.toBase58(),
        redemption: Redemption.fromBinary(data.data),
      );
    } else {
      return null;
    }
  }

  Future<List<RedemptionAccount>> findRedemptions(
      {String? cashLink,
      String? wallet,
      Commitment commitment = Commitment.finalized}) async {
    final filters = [
      dto.ProgramDataFilter.memcmp(
          offset: 0, bytes: ByteArray.u8(AccountKey.redemption.id).toList()),
      if (cashLink != null)
        dto.ProgramDataFilter.memcmpBase58(offset: 1, bytes: cashLink),
      if (wallet != null)
        dto.ProgramDataFilter.memcmpBase58(offset: 33, bytes: wallet),
    ];
    final accounts = await getProgramAccounts(
      CashLinkProgram.programId,
      encoding: dto.Encoding.base64,
      filters: filters,
      commitment: commitment,
    );
    return accounts
        .map(
          (acc) => RedemptionAccount(
            address: acc.pubkey,
            redemption: Redemption.fromBinary(
                (acc.account.data as dto.BinaryAccountData).data),
          ),
        )
        .toList();
  }

  Future<List<RedemptionAccount>> findRedemptionsForCashLink(String cashLink,
      {String? wallet, Commitment commitment = Commitment.finalized}) async {
    return findRedemptions(
        cashLink: cashLink, wallet: wallet, commitment: commitment);
  }
}
