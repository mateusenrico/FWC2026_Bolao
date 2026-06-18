import 'package:flutter/material.dart';

class JogoTabelaItem {
  final int ordem;
  final String dia;
  final String horario;
  final String local;
  final String timeCasa;
  final String placarCasa;
  final String timeVisitante;
  final String placarVisitante;
  final String status;

  const JogoTabelaItem({
    required this.ordem,
    required this.dia,
    required this.horario,
    required this.local,
    required this.timeCasa,
    required this.placarCasa,
    required this.timeVisitante,
    required this.placarVisitante,
    required this.status,
  });
}

class JogosTable extends StatelessWidget {
  final List<JogoTabelaItem> itens;

  const JogosTable({super.key, required this.itens});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Dia')),
            DataColumn(label: Text('Horário')),
            DataColumn(label: Text('Local')),
            DataColumn(label: Text('Casa')),
            DataColumn(label: Text('Placar')),
            DataColumn(label: Text('Visitante')),
            DataColumn(label: Text('Placar')),
            DataColumn(label: Text('Status')),
          ],
          rows: itens
              .map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item.dia)),
                    DataCell(Text(item.horario)),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Text(
                          item.local,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(item.timeCasa)),
                    DataCell(Text(item.placarCasa)),
                    DataCell(Text(item.timeVisitante)),
                    DataCell(Text(item.placarVisitante)),
                    DataCell(Text(item.status)),
                  ],
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}
