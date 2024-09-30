import 'package:cash/accounts/cash.dart';
import 'package:solana/solana.dart';

class CashProgram {
  static const programId = 'cashXAE5UP18RyU7ByFWfxu93kGg69KzoktacNQDukW';
  static const rewardPrefix = 'reward';
  static const walletPrefix = 'wallet';
  static const referralPrefix = 'referral';
  static const ticketPrefix = 'ticket';
  static const redemptionPrefix = 'redemption';

  static Future<Ed25519HDPublicKey> cashAccount(String reference) {
    final programID = Ed25519HDPublicKey.fromBase58(CashProgram.programId);
    return Ed25519HDPublicKey.findProgramAddress(seeds: [
      Cash.prefix.codeUnits,
      reference.codeUnits,
    ], programId: programID);
  }

  static Future<Ed25519HDPublicKey> rewardAccount(Ed25519HDPublicKey wallet) {
    final programID = Ed25519HDPublicKey.fromBase58(CashProgram.programId);
    return Ed25519HDPublicKey.findProgramAddress(
      seeds: [
        rewardPrefix.codeUnits,
        wallet.bytes,
      ],
      programId: programID,
    );
  }

  static Future<Ed25519HDPublicKey> walletAccount(Ed25519HDPublicKey wallet) {
    final programID = Ed25519HDPublicKey.fromBase58(CashProgram.programId);
    return Ed25519HDPublicKey.findProgramAddress(
      seeds: [
        walletPrefix.codeUnits,
        wallet.bytes,
      ],
      programId: programID,
    );
  }

  static Future<Ed25519HDPublicKey> referralAccount(Ed25519HDPublicKey wallet) {
    final programID = Ed25519HDPublicKey.fromBase58(CashProgram.programId);
    return Ed25519HDPublicKey.findProgramAddress(
      seeds: [
        referralPrefix.codeUnits,
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

  static Future<Ed25519HDPublicKey> redemptionAccount(
      Ed25519HDPublicKey cash, Ed25519HDPublicKey wallet) {
    final programID = Ed25519HDPublicKey.fromBase58(CashProgram.programId);
    return Ed25519HDPublicKey.findProgramAddress(
      seeds: [
        redemptionPrefix.codeUnits,
        cash.bytes,
        wallet.bytes,
      ],
      programId: programID,
    );
  }
}
