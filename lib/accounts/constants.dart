enum AccountKey {
  uninitialized,
  cashLink,
  redemption,
}

extension AccountKeyExtension on AccountKey {
  static AccountKey fromId(int id) {
    switch (id) {
      case 0:
        return AccountKey.uninitialized;
      case 1:
        return AccountKey.cashLink;
      case 2:
        return AccountKey.redemption;
    }
    throw StateError('Invalid account key');
  }

  int get id {
    switch (this) {
      case AccountKey.uninitialized:
        return 0;
      case AccountKey.cashLink:
        return 1;
      case AccountKey.redemption:
        return 2;
    }
  }
}

enum CashLinkState {
  uninitialized,
  initialized,
  redeemed,
  redeeming,
  canceled,
}

extension CashLinkStateExtension on CashLinkState {
  static CashLinkState fromId(int id) {
    switch (id) {
      case 0:
        return CashLinkState.uninitialized;
      case 1:
        return CashLinkState.initialized;
      case 2:
        return CashLinkState.redeemed;
      case 3:
        return CashLinkState.redeeming;
      case 4:
        return CashLinkState.canceled;
    }
    throw StateError('Invalid cash link state');
  }

  int get id {
    switch (this) {
      case CashLinkState.uninitialized:
        return 0;
      case CashLinkState.initialized:
        return 1;
      case CashLinkState.redeemed:
        return 2;
      case CashLinkState.redeeming:
        return 3;
      case CashLinkState.canceled:
        return 4;
    }
  }
}

enum CashLinkDistributionType {
  fixed,
  random,
}

extension CashLinkDistributionTypeExtension on CashLinkDistributionType {
  static CashLinkDistributionType fromId(int id) {
    switch (id) {
      case 0:
        return CashLinkDistributionType.fixed;
      case 1:
        return CashLinkDistributionType.random;
    }
    throw StateError('Invalid cash link distribution type');
  }

  int get id {
    switch (this) {
      case CashLinkDistributionType.fixed:
        return 0;
      case CashLinkDistributionType.random:
        return 1;
    }
  }
}
