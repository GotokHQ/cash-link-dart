import 'package:cash/accounts/cash.dart';
import 'package:solana/solana.dart';

class CashProgram {
  static const programId = 'cashXAE5UP18RyU7ByFWfxu93kGg69KzoktacNQDukW';
  static const rewardPrefix = 'reward';
  static const walletPrefix = 'wallet';
  static const referralPrefix = 'referral';
  static const ticketPrefix = 'ticket';

  static Future<Ed25519HDPublicKey> cashAccount(String reference) {
    final programID = Ed25519HDPublicKey.fromBase58(CashProgram.programId);
    return Ed25519HDPublicKey.findProgramAddress(seeds: [
      Cash.prefix.codeUnits,
      reference.codeUnits,
    ], programId: programID);
  }

  static Future<Ed25519HDPublicKey> accountForPrefix(
      String prefix, Ed25519HDPublicKey wallet) {
    final programID = Ed25519HDPublicKey.fromBase58(CashProgram.programId);
    return Ed25519HDPublicKey.findProgramAddress(
      seeds: [
        prefix.codeUnits,
        wallet.bytes,
      ],
      programId: programID,
    );
  }

  static Future<Ed25519HDPublicKey> ticketAccount(
      Ed25519HDPublicKey cash, Ed25519HDPublicKey wallet) {
    final programID = Ed25519HDPublicKey.fromBase58(CashProgram.programId);
    return Ed25519HDPublicKey.findProgramAddress(
      seeds: [
        ticketPrefix.codeUnits,
        cash.bytes,
        wallet.bytes,
      ],
      programId: programID,
    );
  }
}
