import 'dart:async';

import 'package:flutter/material.dart';

import '../services/bolao_controller.dart';

class RefreshCountdownIndicator extends StatefulWidget {
  final BolaoController controller;
  final bool compact;

  const RefreshCountdownIndicator({
    super.key,
    required this.controller,
    this.compact = false,
  });

  @override
  State<RefreshCountdownIndicator> createState() =>
      _RefreshCountdownIndicatorState();
}

class _RefreshCountdownIndicatorState extends State<RefreshCountdownIndicator> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final next = widget.controller.proximaAtualizacao;
    final colors = Theme.of(context).colorScheme;

    if (widget.controller.atualizandoApi) {
      return _Shell(
        compact: widget.compact,
        label: 'Atualizando agora',
        child: const LinearProgressIndicator(minHeight: 4),
      );
    }

    if (next == null) {
      return _Shell(
        compact: widget.compact,
        label: 'Atualização automática fica ativa durante jogos ao vivo',
        child: LinearProgressIndicator(
          minHeight: 4,
          value: 0,
          backgroundColor: colors.surfaceContainerHighest,
        ),
      );
    }

    final intervalSeconds = BolaoController.autoRefreshInterval.inSeconds;
    final remaining = next.difference(_now);
    final remainingSeconds = remaining.inSeconds.clamp(0, intervalSeconds);
    final value = 1 - (remainingSeconds / intervalSeconds);

    return _Shell(
      compact: widget.compact,
      label: 'Próxima atualização em ${remainingSeconds}s',
      child: LinearProgressIndicator(
        minHeight: 4,
        value: value,
        backgroundColor: colors.surfaceContainerHighest,
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  final bool compact;
  final String label;
  final Widget child;

  const _Shell({
    required this.compact,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Tooltip(
        message: label,
        child: SizedBox(width: 92, child: child),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
