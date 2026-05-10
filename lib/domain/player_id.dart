enum PlayerID { white, black }

extension PlayerIdExtension on PlayerID {
  PlayerID get opponent =>
      this == PlayerID.white ? PlayerID.black : PlayerID.white;
}
