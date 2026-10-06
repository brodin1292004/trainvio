import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../data/repo.dart';
import '../widgets/state_views.dart';
import '../widgets/train_tile.dart';

/// Check the booking status of a ticket by its 10-digit PNR number.
class PnrScreen extends StatefulWidget {
  const PnrScreen({super.key});

  @override
  State<PnrScreen> createState() => _PnrScreenState();
}

class _PnrScreenState extends State<PnrScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _problem;
  Future<PnrStatus>? _future;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    FocusScope.of(context).unfocus();
    final String pnr = _controller.text.trim();
    if (pnr.length != 10) {
      setState(() {
        _problem = 'Enter all 10 digits of the PNR.';
        _future = null;
      });
      return;
    }
    setState(() {
      _problem = null;
      _future = repo.getPnr(pnr);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Future<PnrStatus>? future = _future;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.railBlue,
        foregroundColor: Colors.white,
        title: const Text('PNR status'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            maxLength: 10,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            textInputAction: TextInputAction.done,
            onSubmitted: (String value) => _check(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
            decoration: fieldDecoration(
              hint: '10-digit PNR',
              icon: Icons.confirmation_number_outlined,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _check,
              child: const Text(
                'Check PNR status',
                style: TextStyle(fontSize: 16),
              ),
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
          if (future == null)
            const Text(
              'The PNR is printed at the top of your ticket and in the '
              'booking SMS.',
              style:
                  TextStyle(fontSize: 14, height: 1.4, color: AppColors.muted),
            )
          else
            FutureBuilder<PnrStatus>(
              future: future,
              builder: (
                BuildContext context,
                AsyncSnapshot<PnrStatus> snapshot,
              ) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingView();
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return MessageView(
                    icon: Icons.cloud_off,
                    title: 'Could not check this PNR',
                    message: errorMessage(snapshot.error),
                    actionLabel: 'Try again',
                    onAction: _check,
                  );
                }
                return _PnrResult(status: snapshot.data!);
              },
            ),
        ],
      ),
    );
  }
}

class _PnrResult extends StatelessWidget {
  const _PnrResult({required this.status});

  final PnrStatus status;

  @override
  Widget build(BuildContext context) {
    String? firstCoach;
    for (final Passenger p in status.passengers) {
      if (p.coach != null) {
        firstCoach = p.coach;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${status.train.number} ${status.train.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${status.from.name} to ${status.to.name}',
                style: const TextStyle(fontSize: 15, color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                '${shortDate(status.journeyDate)}, ${status.travelClass}',
                style: const TextStyle(fontSize: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                status.chartPrepared
                    ? 'Chart prepared'
                    : 'Chart not prepared yet',
                style: const TextStyle(fontSize: 14, color: AppColors.muted),
              ),
              const Divider(height: 28, color: AppColors.line),
              for (final Passenger p in status.passengers)
                _PassengerRow(passenger: p),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => openTrain(
              context,
              status.train.number,
              status.train.name,
              highlightCoach: firstCoach,
            ),
            icon: const Icon(Icons.train),
            label: const Text('See live status and coach position'),
          ),
        ),
      ],
    );
  }
}

class _PassengerRow extends StatelessWidget {
  const _PassengerRow({required this.passenger});

  final Passenger passenger;

  @override
  Widget build(BuildContext context) {
    final bool confirmed =
        passenger.currentStatus.toLowerCase().startsWith('confirm');
    final List<String> seat = <String>[
      if (passenger.coach != null) 'Coach ${passenger.coach}',
      if (passenger.berth != null) 'Berth ${passenger.berth}',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Passenger ${passenger.number}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  seat.isEmpty
                      ? 'Booked as ${passenger.bookingStatus}'
                      : '${seat.join(', ')}. Booked as '
                          '${passenger.bookingStatus}',
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            passenger.currentStatus,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: confirmed ? AppColors.onTime : AppColors.late,
            ),
          ),
        ],
      ),
    );
  }
}
