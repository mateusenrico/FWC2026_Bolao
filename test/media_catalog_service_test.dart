import 'package:flutter_test/flutter_test.dart';
import 'package:fwc2026_bolao/models/bolao_data.dart';
import 'package:fwc2026_bolao/models/time_sportsdb.dart';
import 'package:fwc2026_bolao/services/media_catalog_service.dart';

void main() {
  group('MediaCatalogService', () {
    test('resolve badge por nome em portugues mesmo com timeKey em ingles', () {
      const badgeUrl = 'https://example.com/south-korea.png';
      final catalog = MediaCatalogService.build(
        data: const BolaoData(
          jogos: [],
          historicoPartidas: [],
          participantes: [],
          palpites: [],
          timesParticipantes: [],
          timesSportsDb: [
            TimeSportsDb(
              timeKey: 'south korea',
              nomeBolao: 'COREIA DO SUL',
              grupo: 'A',
              idTeam: '134517',
              nomeApi: 'South Korea',
              siglaApi: 'KOR',
              pais: 'South Korea',
              badgeUrl: badgeUrl,
              logoUrl: null,
              bannerUrl: null,
              fanartUrl: null,
              equipamentoUrl: null,
              corPrimaria: null,
              corSecundaria: null,
              estadio: null,
              idVenue: null,
              descricao: null,
              fonte: 'test',
              raw: {},
            ),
          ],
        ),
      );

      expect(catalog.badgeForTeam('COREIA DO SUL'), badgeUrl);
      expect(catalog.badgeForTeam('south korea'), badgeUrl);
      expect(catalog.badgeForTeam('KOR'), badgeUrl);
    });
  });
}
