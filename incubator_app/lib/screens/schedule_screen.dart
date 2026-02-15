import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/schedule.dart';
import '../services/incubator_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<Schedule>> _schedulesFuture;

  @override
  void initState() {
    super.initState();
    _refreshSchedules();
  }

  void _refreshSchedules() {
    final service = context.read<IncubatorService>();
    if (service.currentIncubatorId != null) {
      setState(() {
        _schedulesFuture = service.getSchedules(service.currentIncubatorId!);
      });
    } else {
      _schedulesFuture = Future.value([]);
    }
  }

  Future<void> _deleteSchedule(int id) async {
    final service = context.read<IncubatorService>();
    if (service.currentIncubatorId != null) {
      await service.deleteSchedule(service.currentIncubatorId!, id);
      _refreshSchedules();
    }
  }

  void _showAddScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddScheduleDialog(),
    ).then((added) {
      if (added == true) {
        _refreshSchedules();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSchedules,
          ),
        ],
      ),
      body: FutureBuilder<List<Schedule>>(
        future: _schedulesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final schedules = snapshot.data ?? [];

          if (schedules.isEmpty) {
            return const Center(child: Text('No schedules set.'));
          }

          return ListView.builder(
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final s = schedules[index];
              return Dismissible(
                key: Key(s.id.toString()),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) => _deleteSchedule(s.id),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Schedule?'),
                      content: const Text(
                        'Are you sure you want to delete this schedule?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: Icon(_getDeviceIcon(s.deviceType)),
                    title: Text(
                      '${s.deviceName} ${s.activeState ? "ON" : "OFF"}',
                    ),
                    subtitle: Text('${s.timeRange} ${_formatDays(s.daysMask)}'),
                    trailing: Switch(
                      value: s.enabled,
                      onChanged: (val) {
                        // Toggle enable (Requires Edit API, for now just show state)
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getDeviceIcon(int type) {
    switch (type) {
      case 0:
        return Icons.wind_power; // Fan
      case 1:
        return Icons.thermostat; // Heater
      case 2:
        return Icons.water_drop; // Humidifier
      case 3:
        return Icons.rotate_right; // Turner
      default:
        return Icons.devices;
    }
  }

  String _formatDays(int mask) {
    if (mask == 127) return 'Every Day';
    List<String> days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    List<String> active = [];
    for (int i = 0; i < 7; i++) {
      if ((mask >> i) & 1 == 1) active.add(days[i]);
    }
    return active.join(', ');
  }
}

class AddScheduleDialog extends StatefulWidget {
  const AddScheduleDialog({super.key});

  @override
  State<AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<AddScheduleDialog> {
  int _selectedDevice = 0; // 0=Fan
  int _selectedAction = 1; // 1=ON
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  final List<bool> _days = List.filled(7, true); // Sun..Sat

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Schedule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _selectedDevice,
              decoration: const InputDecoration(labelText: 'Device'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Fan')),
                DropdownMenuItem(value: 1, child: Text('Heater')),
                DropdownMenuItem(value: 2, child: Text('Humidifier')),
              ],
              onChanged: (val) => setState(() => _selectedDevice = val!),
            ),
            DropdownButtonFormField<int>(
              initialValue: _selectedAction,
              decoration: const InputDecoration(labelText: 'Action'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Turn ON')),
                DropdownMenuItem(value: 0, child: Text('Turn OFF')),
              ],
              onChanged: (val) => setState(() => _selectedAction = val!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (t != null) setState(() => _startTime = t);
                    },
                    child: Text('Start: ${_startTime.format(context)}'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _endTime,
                      );
                      if (t != null) setState(() => _endTime = t);
                    },
                    child: Text('End: ${_endTime.format(context)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Days'),
            Wrap(
              spacing: 4,
              children: List.generate(7, (index) {
                return FilterChip(
                  label: Text(['S', 'M', 'T', 'W', 'T', 'F', 'S'][index]),
                  selected: _days[index],
                  onSelected: (val) => setState(() => _days[index] = val),
                  showCheckmark: false,
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _save() {
    int mask = 0;
    for (int i = 0; i < 7; i++) {
      if (_days[i]) mask |= (1 << i);
    }
    if (mask == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select at least one day')));
      return;
    }

    final schedule = Schedule(
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      deviceType: _selectedDevice,
      activeState: _selectedAction == 1,
      daysMask: mask,
    );

    final service = context.read<IncubatorService>();
    if (service.currentIncubatorId != null) {
      service.addSchedule(service.currentIncubatorId!, schedule).then((_) {
        Navigator.pop(context, true);
      });
    }
  }
}
