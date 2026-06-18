import 'package:flutter/material.dart';

import '../services/bolao_controller.dart';

class RankingModeSelector extends StatelessWidget {
  final OrdenacaoRanking value;
  final ValueChanged<OrdenacaoRanking> onChanged;

  const RankingModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<OrdenacaoRanking>(
      segments: const [
        ButtonSegment(
          value: OrdenacaoRanking.consolidado,
          icon: Icon(Icons.verified_outlined),
          label: Text('Consolidados'),
        ),
        ButtonSegment(
          value: OrdenacaoRanking.projetado,
          icon: Icon(Icons.sensors),
          label: Text('Com ao vivo'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (values) => onChanged(values.first),
      showSelectedIcon: false,
    );
  }
}
