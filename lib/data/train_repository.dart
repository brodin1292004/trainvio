import 'models.dart';

/// Everything the screens need to know about trains.
///
/// Screens only ever talk to this interface, so the data source (sample
/// data or the live API) can change without touching the UI.
abstract class TrainRepository {
  Future<List<TrainSummary>> searchTrains(String query);

  Future<List<Station>> searchStations(String query);

  Future<TrainDetail> getTrain(String number);

  /// [startDate] is the date the train left its first station. Pass null
  /// to get the run that is in progress right now.
  Future<LiveStatus> getLiveStatus(String number, DateTime? startDate);

  Future<List<JourneyOption>> trainsBetween(String fromCode, String toCode);

  Future<PnrStatus> getPnr(String pnr);
}
