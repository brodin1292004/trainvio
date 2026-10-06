import 'models.dart';
import 'train_repository.dart';

/// Sample data so every screen works before a live API is connected.
///
/// The train numbers and names are real, but the timings, distances,
/// platforms and coach orders below are ILLUSTRATIVE ONLY. Never ship this
/// repository in the Play Store build.
class MockTrainRepository implements TrainRepository {
  static const Duration _latency = Duration(milliseconds: 450);

  static const Map<String, String> _stationNames = <String, String>{
    'MS': 'Chennai Egmore',
    'TPJ': 'Tiruchchirappalli Jn',
    'MDU': 'Madurai Jn',
    'TEN': 'Tirunelveli Jn',
    'NCJ': 'Nagercoil Jn',
    'KZT': 'Kuzhithurai',
    'TVC': 'Thiruvananthapuram Central',
    'QLN': 'Kollam Jn',
    'ALLP': 'Alappuzha',
    'KTYM': 'Kottayam',
    'ERS': 'Ernakulam Jn',
    'ERN': 'Ernakulam Town',
    'TCR': 'Thrissur',
    'GUV': 'Guruvayur',
    'SRR': 'Shoranur Jn',
    'PGT': 'Palakkad Jn',
    'CBE': 'Coimbatore Jn',
    'ED': 'Erode Jn',
    'KPD': 'Katpadi Jn',
    'BZA': 'Vijayawada Jn',
    'NGP': 'Nagpur Jn',
    'BPL': 'Bhopal Jn',
    'AGC': 'Agra Cantt',
    'NDLS': 'New Delhi',
    'CLT': 'Kozhikode',
    'CAN': 'Kannur',
    'KGQ': 'Kasaragod',
    'MAQ': 'Mangaluru Central',
  };

  /// Minutes after 00:00 on the day the train starts.
  static int _t(int day, int hour, int minute) =>
      (day - 1) * 1440 + hour * 60 + minute;

  static Station _station(String code) =>
      Station(code, _stationNames[code] ?? code);

  static RouteStop _stop(
    String code,
    int? arrival,
    int? departure,
    int km,
    String platform,
  ) {
    return RouteStop(
      station: _station(code),
      arrival: arrival,
      departure: departure,
      distanceKm: km,
      platform: platform,
    );
  }

  static TrainDetail _train(
    String number,
    String name,
    List<RouteStop> stops,
    List<String> coaches,
  ) {
    return TrainDetail(
      summary: TrainSummary(
        number: number,
        name: name,
        source: stops.first.station,
        destination: stops.last.station,
      ),
      stops: stops,
      coachOrder: coaches,
    );
  }

  static const List<String> _sleeperRake = <String>[
    'ENG', 'SLR', 'GEN', 'GEN', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6',
    'S7', 'S8', 'B1', 'B2', 'B3', 'A1', 'GEN', 'SLR',
  ];

  static const List<String> _chairRake = <String>[
    'ENG', 'SLR', 'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'D8',
    'C1', 'C2', 'SLR',
  ];

  static final List<TrainDetail> _trains = <TrainDetail>[
    _train('16127', 'Guruvayur Express', <RouteStop>[
      _stop('MS', null, _t(1, 10, 20), 0, '5'),
      _stop('TPJ', _t(1, 15, 25), _t(1, 15, 30), 337, '3'),
      _stop('MDU', _t(1, 18, 10), _t(1, 18, 15), 493, '1'),
      _stop('TEN', _t(1, 21, 25), _t(1, 21, 30), 650, '2'),
      _stop('NCJ', _t(1, 23, 10), _t(1, 23, 15), 724, '1'),
      _stop('KZT', _t(1, 23, 48), _t(1, 23, 50), 757, '1'),
      _stop('TVC', _t(2, 0, 55), _t(2, 1, 0), 795, '2'),
      _stop('QLN', _t(2, 2, 10), _t(2, 2, 13), 860, '1'),
      _stop('ERS', _t(2, 5, 25), _t(2, 5, 30), 1016, '4'),
      _stop('TCR', _t(2, 6, 55), _t(2, 6, 58), 1090, '2'),
      _stop('GUV', _t(2, 7, 40), null, 1113, '1'),
    ], _sleeperRake),
    _train('12625', 'Kerala Express', <RouteStop>[
      _stop('TVC', null, _t(1, 12, 15), 0, '1'),
      _stop('QLN', _t(1, 13, 17), _t(1, 13, 20), 65, '2'),
      _stop('KTYM', _t(1, 15, 2), _t(1, 15, 5), 160, '1'),
      _stop('ERN', _t(1, 16, 25), _t(1, 16, 30), 221, '1'),
      _stop('TCR', _t(1, 17, 55), _t(1, 17, 58), 295, '1'),
      _stop('PGT', _t(1, 19, 35), _t(1, 19, 40), 372, '3'),
      _stop('CBE', _t(1, 21, 0), _t(1, 21, 5), 426, '2'),
      _stop('ED', _t(1, 22, 40), _t(1, 22, 45), 527, '4'),
      _stop('KPD', _t(2, 3, 20), _t(2, 3, 25), 800, '1'),
      _stop('BZA', _t(2, 12, 10), _t(2, 12, 20), 1300, '6'),
      _stop('NGP', _t(2, 23, 40), _t(2, 23, 45), 1970, '2'),
      _stop('BPL', _t(3, 5, 45), _t(3, 5, 50), 2360, '1'),
      _stop('AGC', _t(3, 12, 55), _t(3, 13, 0), 2880, '2'),
      _stop('NDLS', _t(3, 16, 20), null, 3030, '5'),
    ], _sleeperRake),
    _train('16606', 'Ernad Express', <RouteStop>[
      _stop('NCJ', null, _t(1, 2, 0), 0, '2'),
      _stop('TVC', _t(1, 3, 30), _t(1, 3, 35), 71, '3'),
      _stop('QLN', _t(1, 4, 42), _t(1, 4, 45), 136, '1'),
      _stop('ALLP', _t(1, 6, 28), _t(1, 6, 30), 221, '1'),
      _stop('ERS', _t(1, 8, 0), _t(1, 8, 5), 278, '2'),
      _stop('TCR', _t(1, 9, 28), _t(1, 9, 30), 352, '2'),
      _stop('SRR', _t(1, 10, 25), _t(1, 10, 30), 385, '4'),
      _stop('CLT', _t(1, 12, 10), _t(1, 12, 15), 471, '1'),
      _stop('CAN', _t(1, 14, 0), _t(1, 14, 5), 560, '1'),
      _stop('KGQ', _t(1, 15, 35), _t(1, 15, 37), 646, '1'),
      _stop('MAQ', _t(1, 17, 50), null, 692, '3'),
    ], _sleeperRake),
    _train('12076', 'Jan Shatabdi Express', <RouteStop>[
      _stop('TVC', null, _t(1, 5, 55), 0, '1'),
      _stop('QLN', _t(1, 6, 53), _t(1, 6, 55), 65, '1'),
      _stop('KTYM', _t(1, 8, 17), _t(1, 8, 20), 160, '1'),
      _stop('ERN', _t(1, 9, 27), _t(1, 9, 30), 221, '2'),
      _stop('TCR', _t(1, 10, 38), _t(1, 10, 40), 295, '2'),
      _stop('SRR', _t(1, 11, 35), _t(1, 11, 40), 328, '3'),
      _stop('CLT', _t(1, 13, 5), null, 414, '1'),
    ], _chairRake),
  ];

  TrainDetail _find(String number) {
    for (final TrainDetail train in _trains) {
      if (train.summary.number == number) return train;
    }
    throw const RepoException('No train found with that number.');
  }

  @override
  Future<List<TrainSummary>> searchTrains(String query) async {
    await Future<void>.delayed(_latency);
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return <TrainSummary>[];
    return _trains
        .map((TrainDetail t) => t.summary)
        .where((TrainSummary s) =>
            s.number.startsWith(q) || s.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<List<Station>> searchStations(String query) async {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return <Station>[];
    final List<Station> matches = <Station>[];
    _stationNames.forEach((String code, String name) {
      if (code.toLowerCase().startsWith(q) || name.toLowerCase().contains(q)) {
        matches.add(Station(code, name));
      }
    });
    return matches;
  }

  @override
  Future<TrainDetail> getTrain(String number) async {
    await Future<void>.delayed(_latency);
    return _find(number);
  }

  @override
  Future<LiveStatus> getLiveStatus(String number, DateTime? startDate) async {
    await Future<void>.delayed(_latency);
    final TrainDetail train = _find(number);
    final List<RouteStop> stops = train.stops;

    // A fixed, made-up delay per train so the demo looks realistic.
    final int delay = (int.tryParse(number) ?? 0) % 4 * 9;

    final DateTime now = DateTime.now();
    final DateTime start = startDate ?? now;
    final DateTime midnight = DateTime(start.year, start.month, start.day);
    final int elapsed = now.difference(midnight).inMinutes - delay;

    RunState state;
    int index;
    bool atStation;

    if (elapsed < stops.first.leaveTime) {
      state = RunState.notStarted;
      index = 0;
      atStation = true;
    } else if (elapsed >= stops.last.reachTime) {
      state = RunState.arrived;
      index = stops.length - 1;
      atStation = true;
    } else {
      state = RunState.running;
      index = 0;
      for (int i = 0; i < stops.length; i++) {
        if (stops[i].reachTime <= elapsed) index = i;
      }
      atStation = elapsed < stops[index].leaveTime;
    }

    return LiveStatus(
      train: train,
      startDate: midnight,
      state: state,
      currentIndex: index,
      atStation: atStation,
      delayMinutes: state == RunState.notStarted ? 0 : delay,
      updatedAt: now,
    );
  }

  @override
  Future<List<JourneyOption>> trainsBetween(
    String fromCode,
    String toCode,
  ) async {
    await Future<void>.delayed(_latency);
    final List<JourneyOption> options = <JourneyOption>[];
    for (final TrainDetail train in _trains) {
      final int from = train.stops
          .indexWhere((RouteStop s) => s.station.code == fromCode);
      final int to =
          train.stops.indexWhere((RouteStop s) => s.station.code == toCode);
      if (from >= 0 && to > from) {
        options.add(JourneyOption(
          train: train.summary,
          from: train.stops[from],
          to: train.stops[to],
        ));
      }
    }
    options.sort((JourneyOption a, JourneyOption b) =>
        (a.from.leaveTime % 1440).compareTo(b.from.leaveTime % 1440));
    return options;
  }

  @override
  Future<PnrStatus> getPnr(String pnr) async {
    await Future<void>.delayed(_latency);
    if (!RegExp(r'^\d{10}$').hasMatch(pnr)) {
      throw const RepoException('A PNR number has exactly 10 digits.');
    }
    final TrainDetail train = _find('12625');
    final DateTime now = DateTime.now();
    return PnrStatus(
      pnr: pnr,
      train: train.summary,
      journeyDate: DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 3)),
      from: _station('TVC'),
      to: _station('CBE'),
      travelClass: 'Sleeper (SL)',
      chartPrepared: false,
      passengers: const <Passenger>[
        Passenger(
          number: 1,
          bookingStatus: 'WL 12',
          currentStatus: 'Confirmed',
          coach: 'S4',
          berth: '23 Lower',
        ),
        Passenger(
          number: 2,
          bookingStatus: 'WL 13',
          currentStatus: 'Confirmed',
          coach: 'S4',
          berth: '24 Middle',
        ),
      ],
    );
  }
}
