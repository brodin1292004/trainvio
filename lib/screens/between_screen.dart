import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../data/repo.dart';
import '../widgets/state_views.dart';
import '../widgets/train_tile.dart';

/// Find every train that runs from one station to another.
class BetweenScreen extends StatefulWidget {
  const BetweenScreen({super.key});

  @override
  State<BetweenScreen> createState() => _BetweenScreenState();
}

class _BetweenScreenState extends State<BetweenScreen> {
  final TextEditingController _fromText = TextEditingController();
  final TextEditingController _toText = TextEditingController();
  final FocusNode _fromFocus = FocusNode();
  final FocusNode _toFocus = FocusNode();

  Station? _from;
  Station? _to;
  String? _problem;
  int _lookupId = 0;
  Future<List<JourneyOption>>? _future;

  @override
  void dispose() {
    _fromText.dispose();
    _toText.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  void _swap() {
    FocusScope.of(context).unfocus();
    final Station? station = _from;
    final String text = _fromText.text;
    setState(() {
      _from = _to;
      _to = station;
      _fromText.text = _toText.text;
      _toText.text = text;
      _future = null;
      _problem = null;
    });
  }

  void _find() {
    FocusScope.of(context).unfocus();
    final Station? from = _from;
    final Station? to = _to;
    if (from == null || to == null) {
      setState(() {
        _problem = 'Pick both stations from the suggestions.';
        _future = null;
      });
      return;
    }
    if (from.code == to.code) {
      setState(() {
        _problem = 'Pick two different stations.';
        _future = null;
      });
      return;
    }
    setState(() {
      _problem = null;
      _future = repo.trainsBetween(from.code, to.code);
    });
  }

  /// Waits until typing pauses before asking for station suggestions, so
  /// that every keystroke does not cost a request.
  Future<Iterable<Station>> _stationOptions(String text) async {
    final int id = ++_lookupId;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (id != _lookupId) return const <Station>[];
    try {
      return await repo.searchStations(text);
    } catch (_) {
      return const <Station>[];
    }
  }

  Widget _stationField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<Station?> onPicked,
  }) {
    return Autocomplete<Station>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: (Station s) => '${s.name} (${s.code})',
      optionsBuilder: (TextEditingValue value) =>
          _stationOptions(value.text),
      onSelected: (Station s) => onPicked(s),
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController fieldController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted,
      ) {
        return TextField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          textInputAction: TextInputAction.next,
          // Typing again means the earlier pick no longer applies.
          onChanged: (String value) => onPicked(null),
          onSubmitted: (String value) => onFieldSubmitted(),
          decoration: fieldDecoration(hint: hint, icon: icon),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.railBlue,
        foregroundColor: Colors.white,
        title: const Text('Find trains'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    _stationField(
                      hint: 'From station',
                      icon: Icons.trip_origin,
                      controller: _fromText,
                      focusNode: _fromFocus,
                      onPicked: (Station? s) => setState(() => _from = s),
                    ),
                    const SizedBox(height: 10),
                    _stationField(
                      hint: 'To station',
                      icon: Icons.place_outlined,
                      controller: _toText,
                      focusNode: _toFocus,
                      onPicked: (Station? s) => setState(() => _to = s),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Swap stations',
                icon: const Icon(Icons.swap_vert),
                onPressed: _swap,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _find,
              child: const Text('Find trains', style: TextStyle(fontSize: 16)),
            ),
          ),
          if (_problem != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              _problem!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.veryLate,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _buildResults(),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final Future<List<JourneyOption>>? future = _future;
    if (future == null) {
      return const Text(
        'Type a station name or code, such as Kollam or QLN, and pick it '
        'from the list.',
        style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.muted),
      );
    }
    return FutureBuilder<List<JourneyOption>>(
      future: future,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<JourneyOption>> snapshot,
      ) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snapshot.hasError) {
          return MessageView(
            icon: Icons.cloud_off,
            title: 'Could not find trains',
            message: errorMessage(snapshot.error),
            actionLabel: 'Try again',
            onAction: _find,
          );
        }
        final List<JourneyOption> options =
            snapshot.data ?? <JourneyOption>[];
        if (options.isEmpty) {
          return const MessageView(
            icon: Icons.search_off,
            title: 'No direct trains',
            message: 'No train runs directly between these two stations.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              options.length == 1
                  ? '1 train'
                  : '${options.length} trains, earliest first',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            for (final JourneyOption option in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TrainTile(
                  number: option.train.number,
                  name: option.train.name,
                  detail: 'Leaves ${clockTime(option.from.leaveTime)}, '
                      'arrives ${clockTime(option.to.reachTime)}, '
                      '${durationLabel(option.durationMinutes)}',
                ),
              ),
          ],
        );
      },
    );
  }
}
