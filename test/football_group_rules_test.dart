import 'package:flutter_test/flutter_test.dart';
import 'package:fwc2026_bolao/core/football_group_rules.dart';

void main() {
  group('FootballGroupRules', () {
    test('calcula pontos e estatisticas classicas de fase de grupos', () {
      const rules = FootballGroupRules.classicFootball();

      final tables = rules.calculateTables(
        teams: const [
          FootballGroupTeam(teamKey: 'a', name: 'A', group: 'A'),
          FootballGroupTeam(teamKey: 'b', name: 'B', group: 'A'),
          FootballGroupTeam(teamKey: 'c', name: 'C', group: 'A'),
          FootballGroupTeam(teamKey: 'd', name: 'D', group: 'A'),
        ],
        matches: const [
          FootballGroupMatch(
            matchId: '1',
            order: 1,
            group: 'A',
            homeKey: 'a',
            homeName: 'A',
            awayKey: 'b',
            awayName: 'B',
            homeGoals: 2,
            awayGoals: 0,
          ),
          FootballGroupMatch(
            matchId: '2',
            order: 2,
            group: 'A',
            homeKey: 'b',
            homeName: 'B',
            awayKey: 'c',
            awayName: 'C',
            homeGoals: 1,
            awayGoals: 1,
          ),
        ],
      );

      final table = tables.table('A')!;
      expect(table.standings.map((standing) => standing.teamKey), [
        'a',
        'c',
        'b',
        'd',
      ]);

      final leader = table.first!;
      expect(leader.points, 3);
      expect(leader.played, 1);
      expect(leader.wins, 1);
      expect(leader.goalDifference, 2);
      expect(leader.qualifiedDirectly, isTrue);

      final second = table.second!;
      expect(second.points, 1);
      expect(second.draws, 1);
      expect(second.goalsFor, 1);
    });

    test('fifaStyle usa confronto direto antes do saldo geral', () {
      const rules = FootballGroupRules.fifaStyle();

      final tables = rules.calculateTables(
        teams: const [
          FootballGroupTeam(teamKey: 'a', name: 'A', group: 'A'),
          FootballGroupTeam(teamKey: 'b', name: 'B', group: 'A'),
          FootballGroupTeam(teamKey: 'c', name: 'C', group: 'A'),
        ],
        matches: const [
          FootballGroupMatch(
            matchId: '1',
            order: 1,
            group: 'A',
            homeKey: 'a',
            homeName: 'A',
            awayKey: 'b',
            awayName: 'B',
            homeGoals: 1,
            awayGoals: 0,
          ),
          FootballGroupMatch(
            matchId: '2',
            order: 2,
            group: 'A',
            homeKey: 'b',
            homeName: 'B',
            awayKey: 'c',
            awayName: 'C',
            homeGoals: 5,
            awayGoals: 0,
          ),
          FootballGroupMatch(
            matchId: '3',
            order: 3,
            group: 'A',
            homeKey: 'a',
            homeName: 'A',
            awayKey: 'c',
            awayName: 'C',
            homeGoals: 0,
            awayGoals: 0,
          ),
          FootballGroupMatch(
            matchId: '4',
            order: 4,
            group: 'A',
            homeKey: 'd',
            homeName: 'D',
            awayKey: 'b',
            awayName: 'B',
            homeGoals: 0,
            awayGoals: 0,
          ),
        ],
      );

      expect(tables.table('A')!.standings.map((standing) => standing.teamKey), [
        'a',
        'b',
        'd',
        'c',
      ]);
    });

    test('marca melhores terceiros conforme limite configurado', () {
      const rules = FootballGroupRules.classicFootball(bestThirdQualifiers: 1);

      final tables = rules.calculateTables(
        teams: const [
          FootballGroupTeam(teamKey: 'a1', name: 'A1', group: 'A'),
          FootballGroupTeam(teamKey: 'a2', name: 'A2', group: 'A'),
          FootballGroupTeam(teamKey: 'a3', name: 'A3', group: 'A'),
          FootballGroupTeam(teamKey: 'b1', name: 'B1', group: 'B'),
          FootballGroupTeam(teamKey: 'b2', name: 'B2', group: 'B'),
          FootballGroupTeam(teamKey: 'b3', name: 'B3', group: 'B'),
        ],
        matches: const [
          FootballGroupMatch(
            matchId: '1',
            order: 1,
            group: 'A',
            homeKey: 'a1',
            homeName: 'A1',
            awayKey: 'a2',
            awayName: 'A2',
            homeGoals: 2,
            awayGoals: 0,
          ),
          FootballGroupMatch(
            matchId: '2',
            order: 2,
            group: 'A',
            homeKey: 'a3',
            homeName: 'A3',
            awayKey: 'a1',
            awayName: 'A1',
            homeGoals: 1,
            awayGoals: 0,
          ),
          FootballGroupMatch(
            matchId: '3',
            order: 3,
            group: 'B',
            homeKey: 'b1',
            homeName: 'B1',
            awayKey: 'b2',
            awayName: 'B2',
            homeGoals: 2,
            awayGoals: 0,
          ),
          FootballGroupMatch(
            matchId: '4',
            order: 4,
            group: 'B',
            homeKey: 'b2',
            homeName: 'B2',
            awayKey: 'b3',
            awayName: 'B3',
            homeGoals: 1,
            awayGoals: 1,
          ),
        ],
      );

      expect(tables.bestThirdPlaces, hasLength(1));
      expect(tables.bestThirdPlaces.single.teamKey, 'b2');
      expect(tables.table('B')!.third!.qualifiedAsBestThird, isTrue);
      expect(tables.table('A')!.third!.qualifiedAsBestThird, isFalse);
    });
  });
}
