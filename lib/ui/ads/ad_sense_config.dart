class AdSenseConfig {
  static const publisherId = 'ca-pub-0000000000000000';
  static const gameTopBannerSlot = '0000000000';
  static const gameTopBannerFormat = 'auto';

  static bool get isConfigured {
    return publisherId != 'ca-pub-0000000000000000' &&
        gameTopBannerSlot != '0000000000';
  }
}
