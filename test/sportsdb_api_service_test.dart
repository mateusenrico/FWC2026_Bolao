import 'package:flutter_test/flutter_test.dart';
import 'package:fwc2026_bolao/services/sportsdb_api_service.dart';

void main() {
  group('SportsDbApiService', () {
    test('buildRefreshRequests inclui lookupevent deduplicado', () {
      const service = SportsDbApiService();

      final requests = service.buildRefreshRequests(
        nowUtc: DateTime.utc(2026, 6, 18),
        eventIds: const ['2391728', '2391728', '', '2461103'],
      );

      final lookupRequests = requests
          .where((request) => request.name.startsWith('lookupevent:'))
          .toList(growable: false);

      expect(lookupRequests, hasLength(2));
      expect(lookupRequests.map((request) => request.name), [
        'lookupevent:2391728',
        'lookupevent:2461103',
      ]);
      expect(
        lookupRequests.map((request) => request.uri.toString()),
        contains(
          'https://www.thesportsdb.com/api/v1/json/123/lookupevent.php?id=2391728',
        ),
      );
    });

    test(
      'buildRefreshRequests mantém janela de eventsday ao redor da data',
      () {
        const service = SportsDbApiService();

        final requests = service.buildRefreshRequests(
          nowUtc: DateTime.utc(2026, 6, 18),
        );

        expect(
          requests.map((request) => request.name),
          containsAll([
            'eventsday:2026-06-15',
            'eventsday:2026-06-16',
            'eventsday:2026-06-17',
            'eventsday:2026-06-18',
            'eventsday:2026-06-19',
          ]),
        );
      },
    );
  });
}
