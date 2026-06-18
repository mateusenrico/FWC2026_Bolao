enum FootballTeamMatchResult { win, loss, draw }

enum FootballGroupTiebreaker {
  points,
  goalDifference,
  goalsFor,
  headToHeadPoints,
  headToHeadGoalDifference,
  headToHeadGoalsFor,
  fairPlay,
  name,
}

class FootballPointsSystem {
  final int win;
  final int draw;
  final int loss;

  const FootballPointsSystem({this.win = 3, this.draw = 1, this.loss = 0});

  FootballTeamMatchResult result({
    required int goalsFor,
    required int goalsAgainst,
  }) {
    if (goalsFor > goalsAgainst) {
      return FootballTeamMatchResult.win;
    }

    if (goalsAgainst > goalsFor) {
      return FootballTeamMatchResult.loss;
    }

    return FootballTeamMatchResult.draw;
  }

  int pointsFor({required int goalsFor, required int goalsAgainst}) {
    if (goalsFor > goalsAgainst) {
      return win;
    }

    if (goalsFor == goalsAgainst) {
      return draw;
    }

    return loss;
  }
}

class FootballGroupTeam {
  final String teamKey;
  final String name;
  final String group;
  final int fairPlayPoints;

  const FootballGroupTeam({
    required this.teamKey,
    required this.name,
    required this.group,
    this.fairPlayPoints = 0,
  });
}

class FootballGroupMatch {
  final String matchId;
  final int order;
  final String group;
  final String homeKey;
  final String homeName;
  final String awayKey;
  final String awayName;
  final int homeGoals;
  final int awayGoals;

  const FootballGroupMatch({
    required this.matchId,
    required this.order,
    required this.group,
    required this.homeKey,
    required this.homeName,
    required this.awayKey,
    required this.awayName,
    required this.homeGoals,
    required this.awayGoals,
  });

  bool involves(String teamKey) {
    return homeKey == teamKey || awayKey == teamKey;
  }

  int goalsFor(String teamKey) {
    if (homeKey == teamKey) {
      return homeGoals;
    }

    if (awayKey == teamKey) {
      return awayGoals;
    }

    return 0;
  }

  int goalsAgainst(String teamKey) {
    if (homeKey == teamKey) {
      return awayGoals;
    }

    if (awayKey == teamKey) {
      return homeGoals;
    }

    return 0;
  }

  int pointsFor(String teamKey, FootballPointsSystem pointsSystem) {
    if (!involves(teamKey)) {
      return 0;
    }

    return pointsSystem.pointsFor(
      goalsFor: goalsFor(teamKey),
      goalsAgainst: goalsAgainst(teamKey),
    );
  }
}

class FootballStanding {
  final String teamKey;
  final String name;
  final String group;
  final int position;
  final int points;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int fairPlayPoints;
  final bool qualifiedDirectly;
  final bool qualifiedAsBestThird;

  const FootballStanding({
    required this.teamKey,
    required this.name,
    required this.group,
    required this.position,
    required this.points,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.fairPlayPoints,
    required this.qualifiedDirectly,
    required this.qualifiedAsBestThird,
  });

  int get goalDifference => goalsFor - goalsAgainst;

  FootballStanding copyWith({
    int? position,
    bool? qualifiedDirectly,
    bool? qualifiedAsBestThird,
  }) {
    return FootballStanding(
      teamKey: teamKey,
      name: name,
      group: group,
      position: position ?? this.position,
      points: points,
      played: played,
      wins: wins,
      draws: draws,
      losses: losses,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      fairPlayPoints: fairPlayPoints,
      qualifiedDirectly: qualifiedDirectly ?? this.qualifiedDirectly,
      qualifiedAsBestThird: qualifiedAsBestThird ?? this.qualifiedAsBestThird,
    );
  }
}

class FootballGroupTable {
  final String group;
  final List<FootballStanding> standings;
  final List<FootballGroupMatch> computedMatches;

  const FootballGroupTable({
    required this.group,
    required this.standings,
    required this.computedMatches,
  });

  FootballStanding? position(int position) {
    if (position < 1 || position > standings.length) {
      return null;
    }

    return standings[position - 1];
  }

  FootballStanding? get first => position(1);

  FootballStanding? get second => position(2);

  FootballStanding? get third => position(3);
}

class FootballGroupTableSet {
  final Map<String, FootballGroupTable> tablesByGroup;
  final List<FootballStanding> orderedThirdPlaces;
  final List<FootballStanding> bestThirdPlaces;

  const FootballGroupTableSet({
    required this.tablesByGroup,
    required this.orderedThirdPlaces,
    required this.bestThirdPlaces,
  });

  FootballGroupTable? table(String group) {
    return tablesByGroup[group.toUpperCase()];
  }
}

class FootballGroupRules {
  final FootballPointsSystem pointsSystem;
  final List<FootballGroupTiebreaker> tiebreakers;
  final List<FootballGroupTiebreaker> thirdPlaceTiebreakers;
  final int directQualifiers;
  final int bestThirdQualifiers;

  const FootballGroupRules({
    this.pointsSystem = const FootballPointsSystem(),
    required this.tiebreakers,
    required this.thirdPlaceTiebreakers,
    this.directQualifiers = 2,
    this.bestThirdQualifiers = 0,
  });

  const FootballGroupRules.classicFootball({
    this.pointsSystem = const FootballPointsSystem(),
    this.directQualifiers = 2,
    this.bestThirdQualifiers = 0,
  }) : tiebreakers = const [
         FootballGroupTiebreaker.points,
         FootballGroupTiebreaker.goalDifference,
         FootballGroupTiebreaker.goalsFor,
         FootballGroupTiebreaker.fairPlay,
         FootballGroupTiebreaker.name,
       ],
       thirdPlaceTiebreakers = const [
         FootballGroupTiebreaker.points,
         FootballGroupTiebreaker.goalDifference,
         FootballGroupTiebreaker.goalsFor,
         FootballGroupTiebreaker.fairPlay,
         FootballGroupTiebreaker.name,
       ];

  const FootballGroupRules.fifaStyle({
    this.pointsSystem = const FootballPointsSystem(),
    this.directQualifiers = 2,
    this.bestThirdQualifiers = 0,
  }) : tiebreakers = const [
         FootballGroupTiebreaker.points,
         FootballGroupTiebreaker.headToHeadPoints,
         FootballGroupTiebreaker.headToHeadGoalDifference,
         FootballGroupTiebreaker.headToHeadGoalsFor,
         FootballGroupTiebreaker.goalDifference,
         FootballGroupTiebreaker.goalsFor,
         FootballGroupTiebreaker.fairPlay,
         FootballGroupTiebreaker.name,
       ],
       thirdPlaceTiebreakers = const [
         FootballGroupTiebreaker.points,
         FootballGroupTiebreaker.goalDifference,
         FootballGroupTiebreaker.goalsFor,
         FootballGroupTiebreaker.fairPlay,
         FootballGroupTiebreaker.name,
       ];

  FootballGroupTableSet calculateTables({
    required Iterable<FootballGroupTeam> teams,
    required Iterable<FootballGroupMatch> matches,
  }) {
    final accumulatorsByGroup = <String, Map<String, _FootballAccumulator>>{};
    final matchesByGroup = <String, List<FootballGroupMatch>>{};

    for (final team in teams) {
      final group = team.group.toUpperCase();
      final accumulators = accumulatorsByGroup.putIfAbsent(group, () => {});
      _ensureTeam(
        accumulators: accumulators,
        teamKey: team.teamKey,
        name: team.name,
        group: group,
        fairPlayPoints: team.fairPlayPoints,
      );
    }

    for (final match in matches) {
      final group = match.group.toUpperCase();
      final accumulators = accumulatorsByGroup.putIfAbsent(group, () => {});

      final home = _ensureTeam(
        accumulators: accumulators,
        teamKey: match.homeKey,
        name: match.homeName,
        group: group,
      );
      final away = _ensureTeam(
        accumulators: accumulators,
        teamKey: match.awayKey,
        name: match.awayName,
        group: group,
      );

      _applyResult(home: home, away: away, match: match);
      matchesByGroup.putIfAbsent(group, () => []).add(match);
    }

    final tables = <String, FootballGroupTable>{};

    for (final entry in accumulatorsByGroup.entries) {
      final group = entry.key;
      final accumulators = entry.value.values.toList();
      final groupMatches = matchesByGroup[group] ?? const [];

      accumulators.sort((a, b) {
        return _compareAccumulators(
          a: a,
          b: b,
          groupMatches: groupMatches,
          tiebreakerOrder: tiebreakers,
        );
      });

      final standings = <FootballStanding>[];
      for (var index = 0; index < accumulators.length; index++) {
        standings.add(
          accumulators[index].toStanding(
            position: index + 1,
            qualifiedDirectly: index < directQualifiers,
          ),
        );
      }

      tables[group] = FootballGroupTable(
        group: group,
        standings: standings,
        computedMatches: groupMatches,
      );
    }

    final thirdPlaces = tables.values
        .map((table) => table.third)
        .whereType<FootballStanding>()
        .toList();

    thirdPlaces.sort((a, b) {
      return _compareStandings(
        a: a,
        b: b,
        groupMatches: const [],
        tiebreakerOrder: thirdPlaceTiebreakers,
      );
    });

    final bestThirdPlaces = thirdPlaces
        .take(bestThirdQualifiers)
        .map((standing) => standing.copyWith(qualifiedAsBestThird: true))
        .toList(growable: false);
    final bestThirdGroups = bestThirdPlaces
        .map((standing) => standing.group.toUpperCase())
        .toSet();

    final classifiedTables = <String, FootballGroupTable>{};
    for (final entry in tables.entries) {
      final standings = entry.value.standings
          .map((standing) {
            final qualifiedAsBestThird =
                standing.position == 3 &&
                bestThirdGroups.contains(standing.group);

            return standing.copyWith(
              qualifiedDirectly: standing.position <= directQualifiers,
              qualifiedAsBestThird: qualifiedAsBestThird,
            );
          })
          .toList(growable: false);

      classifiedTables[entry.key] = FootballGroupTable(
        group: entry.value.group,
        standings: standings,
        computedMatches: entry.value.computedMatches,
      );
    }

    return FootballGroupTableSet(
      tablesByGroup: classifiedTables,
      orderedThirdPlaces: thirdPlaces,
      bestThirdPlaces: bestThirdPlaces,
    );
  }

  _FootballAccumulator _ensureTeam({
    required Map<String, _FootballAccumulator> accumulators,
    required String teamKey,
    required String name,
    required String group,
    int fairPlayPoints = 0,
  }) {
    return accumulators.putIfAbsent(
      teamKey,
      () => _FootballAccumulator(
        teamKey: teamKey,
        name: name,
        group: group,
        fairPlayPoints: fairPlayPoints,
      ),
    );
  }

  void _applyResult({
    required _FootballAccumulator home,
    required _FootballAccumulator away,
    required FootballGroupMatch match,
  }) {
    home.played++;
    away.played++;

    home.goalsFor += match.homeGoals;
    home.goalsAgainst += match.awayGoals;

    away.goalsFor += match.awayGoals;
    away.goalsAgainst += match.homeGoals;

    if (match.homeGoals > match.awayGoals) {
      home.wins++;
      away.losses++;
      home.points += pointsSystem.win;
    } else if (match.awayGoals > match.homeGoals) {
      away.wins++;
      home.losses++;
      away.points += pointsSystem.win;
    } else {
      home.draws++;
      away.draws++;
      home.points += pointsSystem.draw;
      away.points += pointsSystem.draw;
    }
  }

  int _compareAccumulators({
    required _FootballAccumulator a,
    required _FootballAccumulator b,
    required List<FootballGroupMatch> groupMatches,
    required List<FootballGroupTiebreaker> tiebreakerOrder,
  }) {
    return _compareStandings(
      a: a.toStanding(position: 0),
      b: b.toStanding(position: 0),
      groupMatches: groupMatches,
      tiebreakerOrder: tiebreakerOrder,
    );
  }

  int _compareStandings({
    required FootballStanding a,
    required FootballStanding b,
    required List<FootballGroupMatch> groupMatches,
    required List<FootballGroupTiebreaker> tiebreakerOrder,
  }) {
    for (final tiebreaker in tiebreakerOrder) {
      final result = switch (tiebreaker) {
        FootballGroupTiebreaker.points => b.points.compareTo(a.points),
        FootballGroupTiebreaker.goalDifference => b.goalDifference.compareTo(
          a.goalDifference,
        ),
        FootballGroupTiebreaker.goalsFor => b.goalsFor.compareTo(a.goalsFor),
        FootballGroupTiebreaker.headToHeadPoints => _compareHeadToHead(
          a,
          b,
          groupMatches,
          _HeadToHeadMetric.points,
        ),
        FootballGroupTiebreaker.headToHeadGoalDifference => _compareHeadToHead(
          a,
          b,
          groupMatches,
          _HeadToHeadMetric.goalDifference,
        ),
        FootballGroupTiebreaker.headToHeadGoalsFor => _compareHeadToHead(
          a,
          b,
          groupMatches,
          _HeadToHeadMetric.goalsFor,
        ),
        FootballGroupTiebreaker.fairPlay => b.fairPlayPoints.compareTo(
          a.fairPlayPoints,
        ),
        FootballGroupTiebreaker.name => a.name.compareTo(b.name),
      };

      if (result != 0) {
        return result;
      }
    }

    return 0;
  }

  int _compareHeadToHead(
    FootballStanding a,
    FootballStanding b,
    List<FootballGroupMatch> groupMatches,
    _HeadToHeadMetric metric,
  ) {
    final headToHeadMatches = groupMatches.where((match) {
      return match.involves(a.teamKey) && match.involves(b.teamKey);
    }).toList();

    if (headToHeadMatches.isEmpty) {
      return 0;
    }

    var pointsA = 0;
    var pointsB = 0;
    var goalsA = 0;
    var goalsB = 0;

    for (final match in headToHeadMatches) {
      pointsA += match.pointsFor(a.teamKey, pointsSystem);
      pointsB += match.pointsFor(b.teamKey, pointsSystem);
      goalsA += match.goalsFor(a.teamKey);
      goalsB += match.goalsFor(b.teamKey);
    }

    return switch (metric) {
      _HeadToHeadMetric.points => pointsB.compareTo(pointsA),
      _HeadToHeadMetric.goalDifference => (goalsB - goalsA).compareTo(
        goalsA - goalsB,
      ),
      _HeadToHeadMetric.goalsFor => goalsB.compareTo(goalsA),
    };
  }
}

class _FootballAccumulator {
  final String teamKey;
  final String name;
  final String group;
  final int fairPlayPoints;

  int points = 0;
  int played = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  _FootballAccumulator({
    required this.teamKey,
    required this.name,
    required this.group,
    required this.fairPlayPoints,
  });

  FootballStanding toStanding({
    required int position,
    bool qualifiedDirectly = false,
    bool qualifiedAsBestThird = false,
  }) {
    return FootballStanding(
      teamKey: teamKey,
      name: name,
      group: group,
      position: position,
      points: points,
      played: played,
      wins: wins,
      draws: draws,
      losses: losses,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      fairPlayPoints: fairPlayPoints,
      qualifiedDirectly: qualifiedDirectly,
      qualifiedAsBestThird: qualifiedAsBestThird,
    );
  }
}

enum _HeadToHeadMetric { points, goalDifference, goalsFor }
