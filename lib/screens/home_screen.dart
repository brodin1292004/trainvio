import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../data/models.dart';
import '../data/repo.dart';
import '../data/saved_trains_store.dart';
import '../widgets/state_views.dart';
import '../widgets/train_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;
  String _query = '';
  bool _loading = false;
  String? _error;
  List<TrainSummary> _results = <TrainSummary>[];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final String q = value.trim();
    setState(() {
      _query = q;
      _error = null;
      _loading = q.isNotEmpty;
      if (q.isEmpty) _results = <TrainSummary>[];
    });
    if (q.isEmpty) {
      _requestId++;
      return;
    }
    // Wait until typing pauses so we do not send a request per keystroke.
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(q));
  }

  Future<void> _search(String q) async {
    final int id = ++_requestId;
    try {
      final List<TrainSummary> found = await repo.searchTrains(q);
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = found;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = errorMessage(e);
        _loading = false;
      });
    }
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: <Widget>[
            _buildHeader(),
            Expanded(child: _query.isEmpty ? _buildIdle() : _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.railBlue,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Train Vio',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Find a train and see where it is right now.',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                decoration: fieldDecoration(
                  hint: 'Train number or name',
                  icon: Icons.search,
                  suffix: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: _clear,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) return const LoadingView();
    if (_error != null) {
      return MessageView(
        icon: Icons.cloud_off,
        title: 'Search did not work',
        message: _error!,
        actionLabel: 'Try again',
        onAction: () => _onChanged(_controller.text),
      );
    }
    if (_results.isEmpty) {
      return MessageView(
        icon: Icons.search_off,
        title: 'No train matches "$_query"',
        message: 'Check the number, or type part of the train name.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final TrainSummary train = _results[index];
        return TrainTile(
          number: train.number,
          name: train.name,
          detail: train.source.name.isEmpty
              ? 'See where it is now'
              : '${train.source.name} to ${train.destination.name}',
        );
      },
    );
  }

  Widget _buildIdle() {
    return ListenableBuilder(
      listenable: SavedTrainsStore.instance,
      builder: (BuildContext context, Widget? child) {
        final List<SavedTrain> saved = SavedTrainsStore.instance.items;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (usingSampleData) ...<Widget>[
              const _SampleDataNotice(),
              const SizedBox(height: 20),
            ],
            const Text(
              'Saved trains',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            if (saved.isEmpty)
              const Panel(
                child: Text(
                  'Trains you save appear here for one-tap tracking. '
                  'Open a train and tap the bookmark.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.muted,
                  ),
                ),
              ),
            for (final SavedTrain train in saved)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TrainTile(
                  number: train.number,
                  name: train.name,
                  detail: 'See where it is now',
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SampleDataNotice extends StatelessWidget {
  const _SampleDataNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.boardYellow.withAlpha(60),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.boardYellow),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, color: AppColors.ink),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This build uses sample data, so timings are not real. '
              'Try 12625, 16127, 16606 or 12076. Paste your API key into '
              'lib/data/api_key.dart to switch to live data.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
