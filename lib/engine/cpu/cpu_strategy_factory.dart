import 'cpu_difficulty.dart';
import 'cpu_strategy.dart';
import 'easy_cpu_strategy.dart';
import 'normal_cpu_strategy.dart';

class CpuStrategyFactory {
  static CpuStrategy create(CpuDifficulty difficulty) {
    return switch (difficulty) {
      CpuDifficulty.easy => EasyCpuStrategy(),
      CpuDifficulty.normal => NormalCpuStrategy(),
      CpuDifficulty.hard => NormalCpuStrategy(),
      CpuDifficulty.nightmare => NormalCpuStrategy(),
    };
  }
}
