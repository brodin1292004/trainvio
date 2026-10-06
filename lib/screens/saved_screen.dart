import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/saved_trains_store.dart';
import '../widgets/state_views.dart';
import '../widgets/train_tile.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SavedTrainsStore store = SavedTrainsStore.instance;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.railBlue,
        foregroundColor: Colors.white,
        title: const Text('Saved trains'),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (BuildContext context, Widget? child) {
          final List<SavedTrain> saved = store.items;
          if (saved.isEmpty) {
            return const MessageView(
              icon: Icons.bookmark_border,
              title: 'No saved trains yet',
              message: 'Open a train and tap the bookmark at the top. '
                  'It will wait here for one-tap tracking.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: saved.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final SavedTrain train = saved[index];
              return TrainTile(
                number: train.number,
                name: train.name,
                detail: 'See where it is now',
                trailing: IconButton(
                  tooltip: 'Remove from saved',
                  icon: const Icon(Icons.bookmark, color: AppColors.railBlue),
                  onPressed: () => store.toggle(train.number, train.name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
