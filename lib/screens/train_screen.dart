import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../data/repo.dart';
import '../data/saved_trains_store.dart';
import '../widgets/coach_strip.dart';
import '../widgets/delay_pill.dart';
import '../widgets/state_views.dart';
import '../widgets/station_board.dart';

/// Live running status of one train: where it is, how late it is, the coach
/// order and the full route.
class TrainScreen extends StatefulWidget {
  const TrainScreen({
    super.key,
    required this.number,
    required this.name,
    this.highlightCoach,
  });

  final String number;
  final String name;

  /// The passenger's coach, when the screen is opened from a PNR.
  final String? highlightCoach;

  @override
  State<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends State<TrainScreen> {
  // Choice 0 asks for the run that is in progress right now. The others
  // ask for the run that started on a specific day.
  static const List<String> _dayLabels = <String>[
    'Current run',
    'Today',
    'Yesterday',
    '2 days ago',
  ];

  final SavedTrainsStore _store = SavedTrainsStore.instance;
  int _dayChoice = 0;
  late Future<LiveStatus> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  DateTime? get _startDate {
    if (_dayChoice == 0) return null;
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (_dayChoice - 1));
  }

  Future<LiveStatus> _load() =>
      repo.getLiveStatus(widget.number, _startDate);

  Future<void> _refresh() async {
    final Future<LiveStatus> next = _load();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      // The FutureBuilder below shows the error.
    }
  }

  void _pickDay(int choice) {
    if (choice == _dayChoice) return;
    setState(() {
      _dayChoice = choice;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.railBlue,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Train ${widget.number}',
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ],
        ),
        actions: <Widget>[
          ListenableBuilder(
            listenable: _store,
            builder: (BuildContext context, Widget? child) {
              final bool saved = _store.isSaved(widget.number);
              return IconButton(
                tooltip: saved ? 'Remove from saved' : 'Save train',
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                onPressed: () => _store.toggle(widget.number, widget.name),
              );
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<LiveStatus>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<LiveStatus> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return MessageView(
              icon: Icons.cloud_off,
              title: 'Could not load this train',
              message: errorMessage(snapshot.error),
              actionLabel: 'Try again',
              onAction: _refresh,
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: _buildContent(snapshot.data!),
          );
        },
      ),
    );
  }

  Widget _buildContent(LiveStatus live) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildDayPicker(),
        const SizedBox(height: 12),
        _buildStatus(live),
        const SizedBox(height: 12),
        _buildCoaches(live),
        const SizedBox(height: 12),
        _buildRoute(live),
      ],
    );
  }

  Widget _buildDayPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Which journey',
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: <Widget>[
            for (int i = 0; i < _dayLabels.length; i++)
              ChoiceChip(
                label: Text(_dayLabels[i]),
                selected: _dayChoice == i,
                onSelected: (bool selected) => _pickDay(i),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatus(LiveStatus live) {
    final RouteStop current = live.currentStop;
    final RouteStop? next = live.nextStop;

    String caption = 'Now at';
    String detail = '';
    switch (live.state) {
      case RunState.notStarted:
        caption = 'Yet to start from';
        detail = 'Departs at ${clockTime(current.leaveTime)} on '
            '${shortDate(live.startDate)}.';
        break;
      case RunState.arrived:
        caption = 'Reached';
        detail = 'This journey is complete.';
        break;
      case RunState.running:
        caption = live.atStation ? 'Now at' : 'Left';
        if (next != null) {
          final int nextDelay = next.delayMinutes ?? live.delayMinutes;
          detail = 'Next stop ${next.station.name}, expected at '
              '${clockTime(next.reachTime + nextDelay)}.';
        }
        break;
    }

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          StationBoard(
            caption: caption,
            name: current.station.name,
            code: current.station.code,
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              if (live.state != RunState.notStarted)
                DelayPill(delayMinutes: live.delayMinutes),
              const Spacer(),
              Text(
                'Updated ${timeOfDay(live.updatedAt)}',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
          if (detail.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              detail,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.ink,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoaches(LiveStatus live) {
    final String? mine = widget.highlightCoach;
    final List<String> coaches = live.train.coachOrder;
    String caption = 'Counted from the engine.';
    if (coaches.isEmpty) {
      caption = 'The coach order is not available for this train.';
    } else if (mine != null) {
      caption = 'Your coach $mine is marked in yellow.';
    }
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _PanelTitle('Coach position'),
          const SizedBox(height: 2),
          Text(
            caption,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          if (coaches.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            CoachStrip(coaches: coaches, highlight: mine),
          ],
        ],
      ),
    );
  }

  Widget _buildRoute(LiveStatus live) {
    final List<RouteStop> stops = live.train.stops;
    final bool started = live.state != RunState.notStarted;
    final bool between = live.state == RunState.running && !live.atStation;

    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < stops.length; i++) {
      rows.add(_StopRow(
        stop: stops[i],
        isFirst: i == 0,
        isLast: i == stops.length - 1,
        reached: started && i <= live.currentIndex,
        lineBelowDone: started &&
            (i < live.currentIndex || (i == live.currentIndex && between)),
        trainIsHere: i == live.currentIndex && live.atStation,
        // Use the delay reported for this stop when there is one. Otherwise
        // assume the train's current delay for the stops still ahead.
        delayMinutes: stops[i].delayMinutes ??
            ((started && i > live.currentIndex) ? live.delayMinutes : 0),
      ));
      if (between && i == live.currentIndex) {
        rows.add(const _BetweenRow());
      }
    }

    return Panel(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 4),
            child: _PanelTitle('Route'),
          ),
          ...rows,
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    );
  }
}

const double _timeColumn = 56;
const double _railColumn = 40;

/// The yellow marker that shows where the train is on the route.
class _TrainMarker extends StatelessWidget {
  const _TrainMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.boardYellow,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: const Icon(Icons.train, size: 15, color: AppColors.ink),
    );
  }
}

class _RailSegment extends StatelessWidget {
  const _RailSegment({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(width: 4, color: color));
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.stop,
    required this.isFirst,
    required this.isLast,
    required this.reached,
    required this.lineBelowDone,
    required this.trainIsHere,
    required this.delayMinutes,
  });

  final RouteStop stop;
  final bool isFirst;
  final bool isLast;
  final bool reached;
  final bool lineBelowDone;
  final bool trainIsHere;
  final int delayMinutes;

  @override
  Widget build(BuildContext context) {
    final int scheduled = stop.reachTime;
    final int day = journeyDay(scheduled);

    final List<String> facts = <String>[
      stop.station.code,
      '${stop.distanceKm} km',
      if (stop.platform != null) 'Platform ${stop.platform}',
      if (day > 1) 'Day $day',
    ];

    Widget dot;
    if (trainIsHere) {
      dot = const _TrainMarker();
    } else {
      dot = Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: reached ? AppColors.railBlue : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: reached ? AppColors.railBlue : AppColors.muted,
            width: 2,
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: _timeColumn,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    clockTime(scheduled),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      decoration: delayMinutes > 0
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (delayMinutes > 0)
                    Text(
                      clockTime(scheduled + delayMinutes),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: delayColor(delayMinutes),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: _railColumn,
            child: Column(
              children: <Widget>[
                _RailSegment(
                  color: isFirst
                      ? Colors.transparent
                      : (reached ? AppColors.railBlue : AppColors.line),
                ),
                dot,
                _RailSegment(
                  color: isLast
                      ? Colors.transparent
                      : (lineBelowDone ? AppColors.railBlue : AppColors.line),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    stop.station.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          trainIsHere ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    facts.join(', '),
                    style:
                        const TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown between two stops while the train is running between them.
class _BetweenRow extends StatelessWidget {
  const _BetweenRow();

  @override
  Widget build(BuildContext context) {
    return const IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(width: _timeColumn),
          SizedBox(
            width: _railColumn,
            child: Column(
              children: <Widget>[
                _RailSegment(color: AppColors.railBlue),
                _TrainMarker(),
                _RailSegment(color: AppColors.line),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Train is here',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
