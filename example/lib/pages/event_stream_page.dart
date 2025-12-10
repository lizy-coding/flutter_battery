import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

/// Displays recent entries from the demo EventChannel stream.
class EventStreamPage extends StatelessWidget {
  const EventStreamPage({required this.eventsListenable, super.key});

  final ValueListenable<List<String>> eventsListenable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event stream log')),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: eventsListenable,
        builder: (context, events, _) {
          if (events.isEmpty) {
            return const Center(child: Text('No events yet. Trigger IoT actions to populate the stream.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) => ListTile(
              leading: const Icon(Icons.bubble_chart_outlined),
              title: Text(events[index]),
            ),
            separatorBuilder: (context, _) => const Divider(height: 1),
            itemCount: events.length,
          );
        },
      ),
    );
  }
}
