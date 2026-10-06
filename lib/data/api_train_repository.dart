import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'train_repository.dart';

/// Live data from the RailRadar API (https://railradar.in/docs).
///
/// Every answer from the API is wrapped like this:
///   { "success": true, "data": ..., "meta": ... }
/// [_get] unwraps it and returns only the "data" part.
///
/// Times from the API are full date-times in Indian Standard Time. The app's
/// models store times as minutes after 00:00 on the day the train started,
/// so they are converted in [_minutesFromStart].
class ApiTrainRepository implements TrainRepository {
  ApiTrainRepository({
    required this.baseUrl,
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String apiKey;
  final http.Client _client;

  // Remember search answers so the same text never costs a second request.
  final Map<String, List<TrainSummary>> _trainSearchCache =
      <String, List<TrainSummary>>{};
  final Map<String, List<Station>> _stationSearchCache =
      <String, List<Station>>{};

  static const Duration _istOffset = Duration(hours: 5, minutes: 30);

  // ---------------------------------------------------------------------
  // Networking
  // ---------------------------------------------------------------------

  Future<dynamic> _get(String path, [Map<String, String>? query]) async {
    final Uri uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );

    http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      ).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const RepoException(
        'The request took too long. Check your connection and try again.',
      );
    } on http.ClientException {
      throw const RepoException(
        'No internet connection. Connect and try again.',
      );
    }

    final int code = response.statusCode;
    if (code == 401 || code == 403) {
      throw const RepoException(
        'The API key was not accepted. Check the key in '
        'lib/data/api_key.dart.',
      );
    }
    if (code == 404) {
      throw const RepoException(
        'Nothing was found. Check the train number and the date.',
      );
    }
    if (code == 429) {
      throw const RepoException(
        'The data plan limit has been reached. Try again later.',
      );
    }
    if (code >= 500) {
      throw const RepoException(
        'The train data service is not responding. Try again in a few '
        'minutes.',
      );
    }
    if (code < 200 || code >= 300) {
      throw RepoException(
        'The train data service returned an error ($code). Try again.',
      );
    }

    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      body = null;
    }
    if (body is! Map<String, dynamic> || body['success'] != true) {
      throw const RepoException(
        'The train data service sent an unreadable reply. Try again.',
      );
    }
    return body['data'];
  }

  // ---------------------------------------------------------------------
  // Small helpers for reading JSON safely
  // ---------------------------------------------------------------------

  static String? _str(dynamic value) {
    if (value == null) return null;
    final String text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static Map<String, dynamic>? _map(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }

  static List<dynamic> _list(dynamic value) {
    return value is List ? value : const <dynamic>[];
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _ymd(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  /// Minutes from 00:00 IST on the start day to the moment [iso] describes.
  ///
  /// [startDay] is built with DateTime.utc purely as a container for the IST
  /// calendar date, so the result does not depend on the phone's time zone.
  static int? _minutesFromStart(dynamic iso, DateTime startDay) {
    final String? text = _str(iso);
    if (text == null) return null;
    final DateTime? parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    final DateTime istClock = parsed.toUtc().add(_istOffset);
    return istClock.difference(startDay).inMinutes;
  }

  /// "06:05" -> 365.
  static int? _clockToMinutes(dynamic value) {
    final String? text = _str(value);
    if (text == null) return null;
    final List<String> parts = text.split(':');
    if (parts.length < 2) return null;
    final int? h = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  static String _runDays(dynamic value) {
    final List<dynamic> days = _list(value);
    if (days.isEmpty) return '';
    if (days.length >= 7) return 'Daily';
    return days.map((dynamic d) {
      final String text = d.toString();
      if (text.isEmpty) return text;
      return text[0].toUpperCase() + text.substring(1);
    }).join(', ');
  }

  /// Statuses that mean the train has NOT reached a stop yet.
  static bool _notReached(String status) {
    return status.isEmpty ||
        status.contains('upcoming') ||
        status.contains('schedul') ||
        status.contains('pending') ||
        status.contains('not') ||
        status.contains('cancel') ||
        status.contains('skip');
  }

  // ---------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------

  @override
  Future<List<TrainSummary>> searchTrains(String query) async {
    final String q = query.trim().toLowerCase();
    if (q.length < 2) return <TrainSummary>[];
    final List<TrainSummary>? cached = _trainSearchCache[q];
    if (cached != null) return cached;

    final dynamic data = await _get(
      '/lookup/search/trains',
      <String, String>{'q': q, 'limit': '20'},
    );
    final List<TrainSummary> found = <TrainSummary>[];
    for (final dynamic item in _list(data)) {
      final Map<String, dynamic>? m = _map(item);
      final String? number = _str(m?['number']);
      if (m == null || number == null) continue;
      final String source = _str(m['source']) ?? '';
      final String destination = _str(m['destination']) ?? '';
      found.add(TrainSummary(
        number: number,
        name: _str(m['name']) ?? 'Train $number',
        // The search answer only has station codes, not full names.
        source: Station(source, source),
        destination: Station(destination, destination),
        runsOn: '',
      ));
    }
    _trainSearchCache[q] = found;
    return found;
  }

  @override
  Future<List<Station>> searchStations(String query) async {
    final String q = query.trim().toLowerCase();
    // A picked station is shown as "Name (CODE)". That is not a new search.
    if (q.length < 2 || q.contains('(')) return <Station>[];
    final List<Station>? cached = _stationSearchCache[q];
    if (cached != null) return cached;

    final dynamic data = await _get(
      '/lookup/search/stations',
      <String, String>{'q': q, 'limit': '10'},
    );
    final List<Station> found = <Station>[];
    for (final dynamic item in _list(data)) {
      final Map<String, dynamic>? m = _map(item);
      final String? code = _str(m?['code']);
      if (m == null || code == null) continue;
      found.add(Station(code, _str(m['name']) ?? code));
    }
    _stationSearchCache[q] = found;
    return found;
  }

  // ---------------------------------------------------------------------
  // Live status
  // ---------------------------------------------------------------------

  @override
  Future<TrainDetail> getTrain(String number) async {
    final LiveStatus live = await getLiveStatus(number, null);
    return live.train;
  }

  @override
  Future<LiveStatus> getLiveStatus(String number, DateTime? startDate) async {
    // The full route is requested (not only halts) so that the position in
    // "currentLocation" lines up with the sequence numbers in the route.
    final Map<String, String> query = <String, String>{};
    if (startDate != null) query['date'] = _ymd(startDate);

    final Map<String, dynamic>? d = _map(await _get(
      '/trains/${Uri.encodeComponent(number.trim())}/live',
      query,
    ));
    if (d == null) {
      throw const RepoException(
        'No running information is available for this train right now.',
      );
    }

    final String topStatus = (_str(d['status']) ?? '').toLowerCase();
    if (topStatus.contains('cancel')) {
      throw const RepoException('This train is cancelled on this date.');
    }

    // Keep only the stations where the train actually stops.
    final List<Map<String, dynamic>> rawStops = <Map<String, dynamic>>[];
    for (final dynamic item in _list(d['route'])) {
      final Map<String, dynamic>? m = _map(item);
      if (m != null && m['isHalt'] != false) rawStops.add(m);
    }
    if (rawStops.isEmpty) {
      throw const RepoException(
        'No route information is available for this train right now.',
      );
    }

    // The day the train started, as an IST calendar date.
    final DateTime now = DateTime.now();
    DateTime? startParsed = DateTime.tryParse(_str(d['startDate']) ?? '');
    if (startParsed == null) {
      final DateTime? firstDeparture = DateTime.tryParse(
        _str(rawStops.first['scheduledDeparture']) ?? '',
      );
      startParsed = firstDeparture == null
          ? (startDate ?? now)
          : firstDeparture.toUtc().add(_istOffset);
    }
    final DateTime startDay =
        DateTime.utc(startParsed.year, startParsed.month, startParsed.day);

    final List<RouteStop> stops = <RouteStop>[];
    final List<String> statuses = <String>[];
    final List<int> sequences = <int>[];
    for (final Map<String, dynamic> m in rawStops) {
      final String code = _str(m['stationCode']) ?? '';
      final dynamic distance = m['distance'];
      stops.add(RouteStop(
        station: Station(code, _str(m['stationName']) ?? code),
        arrival: _minutesFromStart(m['scheduledArrival'], startDay),
        departure: _minutesFromStart(m['scheduledDeparture'], startDay),
        distanceKm: distance is num ? distance.round() : 0,
        platform: _str(m['platform']),
        delayMinutes: _int(m['delayArrival']) ?? _int(m['delayDeparture']),
      ));
      statuses.add((_str(m['status']) ?? '').toLowerCase());
      sequences.add(_int(m['sequence']) ?? 0);
    }

    // Where is the train? Prefer the API's own "currentLocation".
    int reached = -1;
    bool standing = false;
    final Map<String, dynamic>? location = _map(d['currentLocation']);
    final int? locationSequence = _int(location?['sequence']);
    if (location != null && locationSequence != null) {
      final String locationStatus =
          (_str(location['status']) ?? '').toLowerCase();
      final bool locationReached = !_notReached(locationStatus);
      for (int i = 0; i < stops.length; i++) {
        final bool before = sequences[i] < locationSequence;
        final bool same = sequences[i] == locationSequence;
        if (before || (same && locationReached)) reached = i;
      }
      standing = reached >= 0 &&
          sequences[reached] == locationSequence &&
          !locationStatus.contains('depart') &&
          !locationStatus.contains('pass');
    } else {
      for (int i = 0; i < stops.length; i++) {
        if (!_notReached(statuses[i])) reached = i;
      }
      standing = reached >= 0 && !statuses[reached].contains('depart');
    }

    final int last = stops.length - 1;
    final bool finished = topStatus.contains('arriv') ||
        topStatus.contains('complet') ||
        topStatus.contains('reached') ||
        topStatus.contains('terminat');

    RunState state;
    int index;
    bool atStation;
    if (finished || reached >= last) {
      state = RunState.arrived;
      index = last;
      atStation = true;
    } else if (reached < 0) {
      state = RunState.notStarted;
      index = 0;
      atStation = true;
    } else {
      state = RunState.running;
      index = reached;
      atStation = standing;
    }

    // Coach order, e.g. "ENG-SLRD-GEN-S1-S2-B1". It can differ by station,
    // so take it from where the train is now.
    String? coachText = _str(rawStops[index]['coachPosition']);
    if (coachText == null) {
      for (final Map<String, dynamic> m in rawStops) {
        coachText = _str(m['coachPosition']);
        if (coachText != null) break;
      }
    }
    final List<String> coaches = coachText == null
        ? <String>[]
        : coachText
            .split('-')
            .map((String c) => c.trim())
            .where((String c) => c.isNotEmpty)
            .toList();

    final Map<String, dynamic>? train = _map(d['train']);
    final Map<String, dynamic>? source = _map(train?['source']);
    final Map<String, dynamic>? destination = _map(train?['destination']);
    final String trainNumber =
        _str(train?['number']) ?? _str(d['trainNumber']) ?? number;

    final TrainSummary summary = TrainSummary(
      number: trainNumber,
      name: _str(train?['name']) ??
          _str(d['trainName']) ??
          'Train $trainNumber',
      source: source == null
          ? stops.first.station
          : Station(
              _str(source['code']) ?? stops.first.station.code,
              _str(source['name']) ?? stops.first.station.name,
            ),
      destination: destination == null
          ? stops.last.station
          : Station(
              _str(destination['code']) ?? stops.last.station.code,
              _str(destination['name']) ?? stops.last.station.name,
            ),
      runsOn: _runDays(train?['runDays']),
    );

    final DateTime? updated =
        DateTime.tryParse(_str(d['lastUpdatedAt']) ?? '');

    return LiveStatus(
      train: TrainDetail(
        summary: summary,
        stops: stops,
        coachOrder: coaches,
      ),
      startDate: DateTime(startDay.year, startDay.month, startDay.day),
      state: state,
      currentIndex: index,
      atStation: atStation,
      delayMinutes:
          state == RunState.notStarted ? 0 : (_int(d['delayMinutes']) ?? 0),
      updatedAt: updated == null ? now : updated.toLocal(),
    );
  }

  // ---------------------------------------------------------------------
  // Trains between two stations
  // ---------------------------------------------------------------------

  @override
  Future<List<JourneyOption>> trainsBetween(
    String fromCode,
    String toCode,
  ) async {
    final Map<String, dynamic>? d = _map(await _get(
      '/trains/between/${Uri.encodeComponent(fromCode)}/'
      '${Uri.encodeComponent(toCode)}',
    ));
    if (d == null) return <JourneyOption>[];

    final Map<String, dynamic>? fromInfo = _map(d['from']);
    final Map<String, dynamic>? toInfo = _map(d['to']);
    final Station from = Station(
      _str(fromInfo?['code']) ?? fromCode,
      _str(fromInfo?['name']) ?? fromCode,
    );
    final Station to = Station(
      _str(toInfo?['code']) ?? toCode,
      _str(toInfo?['name']) ?? toCode,
    );

    final List<JourneyOption> options = <JourneyOption>[];
    for (final dynamic item in _list(d['trains'])) {
      final Map<String, dynamic>? m = _map(item);
      final Map<String, dynamic>? train = _map(m?['train']);
      final Map<String, dynamic>? fromStop = _map(m?['from']);
      final Map<String, dynamic>? toStop = _map(m?['to']);
      final String? number = _str(train?['number']);
      final int? departure = _clockToMinutes(fromStop?['departure']);
      if (m == null || train == null || number == null || departure == null) {
        continue;
      }

      // Work out the journey length, then place arrival after departure.
      int? duration = _int(m['duration']);
      if (duration == null || duration <= 0) {
        final int? arrival = _clockToMinutes(toStop?['arrival']);
        final int fromDay = _int(fromStop?['day']) ?? 1;
        final int toDay = _int(toStop?['day']) ?? fromDay;
        if (arrival != null) {
          duration = (toDay - fromDay) * 1440 + arrival - departure;
        }
      }
      if (duration == null || duration <= 0) continue;

      final dynamic distance = m['distance'];
      options.add(JourneyOption(
        train: TrainSummary(
          number: number,
          name: _str(train['name']) ?? 'Train $number',
          source: from,
          destination: to,
          runsOn: _runDays(train['runDays']),
        ),
        from: RouteStop(
          station: from,
          departure: departure,
          distanceKm: 0,
        ),
        to: RouteStop(
          station: to,
          arrival: departure + duration,
          distanceKm: distance is num ? distance.round() : 0,
        ),
      ));
    }
    options.sort((JourneyOption a, JourneyOption b) =>
        a.from.leaveTime.compareTo(b.from.leaveTime));
    return options;
  }

  // ---------------------------------------------------------------------
  // PNR
  // ---------------------------------------------------------------------

  @override
  Future<PnrStatus> getPnr(String pnr) async {
    throw const RepoException(
      'PNR status is not connected yet. It needs a second data provider, '
      'which comes in a later stage.',
    );
  }
}
