import 'api_key.dart';
import 'api_train_repository.dart';
import 'mock_train_repository.dart';
import 'train_repository.dart';

/// The one place where the app chooses its data source.
///
/// With no API key pasted into api_key.dart the app uses sample data.
/// With a key it uses live data from RailRadar.
const bool usingSampleData = railRadarApiKey == 'PASTE_YOUR_KEY_HERE';

final TrainRepository repo = usingSampleData
    ? MockTrainRepository()
    : ApiTrainRepository(
        baseUrl: 'https://api.railradar.in/v1',
        apiKey: railRadarApiKey,
      );
