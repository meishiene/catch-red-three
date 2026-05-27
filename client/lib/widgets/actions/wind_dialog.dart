import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class WindRequestDialog extends StatelessWidget {
  final Map<String, dynamic> windData;
  final VoidCallback onTakeWind;
  final VoidCallback onDecline;

  const WindRequestDialog({
    super.key,
    required this.windData,
    required this.onTakeWind,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final finisherName = windData['finisherName'] as String? ?? '某玩家';

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.air, color: AppColors.gold, size: 24),
          SizedBox(width: 8),
          Text('送风', style: TextStyle(color: Colors.white, fontSize: 20)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$finisherName 已出完牌',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 8),
          const Text(
            '要风：本轮可任意出牌，无需比桌面上的牌大\n但如果其余玩家反对，反对者需要管上桌面牌',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: onDecline,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white54,
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('正常出牌'),
        ),
        ElevatedButton(
          onPressed: onTakeWind,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('要风!', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class WindAgreeDialog extends StatelessWidget {
  final Map<String, dynamic> windData;
  final VoidCallback onAgree;
  final VoidCallback onOppose;

  const WindAgreeDialog({
    super.key,
    required this.windData,
    required this.onAgree,
    required this.onOppose,
  });

  @override
  Widget build(BuildContext context) {
    final requesterName = windData['requesterName'] as String? ?? '某玩家';

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.air, color: AppColors.gold, size: 24),
          SizedBox(width: 8),
          Text('送风投票', style: TextStyle(color: Colors.white, fontSize: 20)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$requesterName 申请要风',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            '同意则其可任意出牌，反对则你需管上桌面牌',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: onOppose,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.redTeam,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('反对'),
        ),
        ElevatedButton(
          onPressed: onAgree,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('同意'),
        ),
      ],
    );
  }
}
