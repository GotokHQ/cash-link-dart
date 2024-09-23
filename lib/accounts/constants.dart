enum AccountKey {
  uninitialized,
  cash,
}

extension AccountKeyExtension on AccountKey {
  static AccountKey fromId(int id) {
    switch (id) {
      case 0:
        return AccountKey.uninitialized;
      case 1:
        return AccountKey.cash;
    }
    throw StateError('Invalid account key');
  }

  int get id {
    switch (this) {
      case AccountKey.uninitialized:
        return 0;
      case AccountKey.cash:
        return 1;
    }
  }
}

enum CashState {
  initialized,
  redeemed,
  redeeming,
  canceled,
}

extension CashStateExtension on CashState {
  static CashState fromId(int id) {
    switch (id) {
      case 0:
        return CashState.initialized;
      case 1:
        return CashState.redeemed;
      case 2:
        return CashState.redeeming;
      case 3:
        return CashState.canceled;
    }
    throw StateError('Invalid cash link state');
  }

  int get id {
    switch (this) {
      case CashState.initialized:
        return 0;
      case CashState.redeemed:
        return 1;
      case CashState.redeeming:
        return 2;
      case CashState.canceled:
        return 3;
    }
  }
}

enum CashLinkDistributionType { fixed, random, weighted }

extension CashLinkDistributionTypeExtension on CashLinkDistributionType {
  static CashLinkDistributionType fromId(int id) {
    switch (id) {
      case 0:
        return CashLinkDistributionType.fixed;
      case 1:
        return CashLinkDistributionType.random;
      case 2:
        return CashLinkDistributionType.weighted;
    }
    throw StateError('Invalid cash link distribution type');
  }

  int get id {
    switch (this) {
      case CashLinkDistributionType.fixed:
        return 0;
      case CashLinkDistributionType.random:
        return 1;
      case CashLinkDistributionType.weighted:
        return 2;
    }
  }
}
