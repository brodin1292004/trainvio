class Station {
  const Station(this.code, this.name);

  final String code;
  final String name;
}

class TrainSummary {
  const TrainSummary({
    required this.number,
    required this.name,
    required this.source,
    required this.destination,
    this.runsOn = 'Daily',
  });

  final String number;
  final String name;
  final Station source;
  final Station destination;
  final String runsOn;
}

/// One halt on a train's route.
///
/// [arrival] and [departure] are minutes after 00:00 on the day the train
/// starts. [arrival] is null at the first station, [departure] at the last.
class RouteStop {
  const RouteStop({
    required this.station,
    required this.distanceKm,
    this.arrival,
    this.departure,
    this.platform,
    this.delayMinutes,
  });

  final Station station;
  final int? arrival;
  final int? departure;
  final int distanceKm;
  final String? platform;

  /// Delay at this stop when the data source reports one per stop.
  final int? delayMinutes;

  int get reachTime => arrival ?? departure ?? 0;
  int get leaveTime => departure ?? arrival ?? 0;
}

class TrainDetail {
  const TrainDetail({
    required this.summary,
    required this.stops,
    required this.coachOrder,
  });

  final TrainSummary summary;
  final List<RouteStop> stops;

  /// Coaches from the engine end, e.g. ENG, SLR, GEN, S1, S2 ...
  final List<String> coachOrder;
}

enum RunState { notStarted, running, arrived }

class LiveStatus {
  const LiveStatus({
    required this.train,
    required this.startDate,
    required this.state,
    required this.currentIndex,
    required this.atStation,
    required this.delayMinutes,
    required this.updatedAt,
  });

  final TrainDetail train;

  /// The date the train left its first station.
  final DateTime startDate;
  final RunState state;

  /// Index in [TrainDetail.stops] of the last station the train reached.
  final int currentIndex;

  /// True while the train is standing at [currentStop].
  final bool atStation;
  final int delayMinutes;
  final DateTime updatedAt;

  RouteStop get currentStop => train.stops[currentIndex];

  RouteStop? get nextStop {
    final int next = currentIndex + 1;
    return next < train.stops.length ? train.stops[next] : null;
  }
}

/// A train that runs between two chosen stations.
class JourneyOption {
  const JourneyOption({
    required this.train,
    required this.from,
    required this.to,
  });

  final TrainSummary train;
  final RouteStop from;
  final RouteStop to;

  int get durationMinutes => to.reachTime - from.leaveTime;
}

class Passenger {
  const Passenger({
    required this.number,
    required this.bookingStatus,
    required this.currentStatus,
    this.coach,
    this.berth,
  });

  final int number;
  final String bookingStatus;
  final String currentStatus;
  final String? coach;
  final String? berth;
}

class PnrStatus {
  const PnrStatus({
    required this.pnr,
    required this.train,
    required this.journeyDate,
    required this.from,
    required this.to,
    required this.travelClass,
    required this.chartPrepared,
    required this.passengers,
  });

  final String pnr;
  final TrainSummary train;
  final DateTime journeyDate;
  final Station from;
  final Station to;
  final String travelClass;
  final bool chartPrepared;
  final List<Passenger> passengers;
}

/// An error with a message that is safe to show to the user.
class RepoException implements Exception {
  const RepoException(this.message);

  final String message;

  @override
  String toString() => message;
}
