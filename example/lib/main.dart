import 'package:flutter/material.dart';
import 'package:schedulersms/schedulersms.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SchedulerSMS Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SchedulerSmsHomePage(),
    );
  }
}

class SchedulerSmsHomePage extends StatefulWidget {
  const SchedulerSmsHomePage({super.key});

  @override
  State<SchedulerSmsHomePage> createState() => _SchedulerSmsHomePageState();
}

class _SchedulerSmsHomePageState extends State<SchedulerSmsHomePage> {
  final _smsService = SchedulerSmsService();
  final _recipientController = TextEditingController();
  final _messageController = TextEditingController();
  DateTime? _selectedDate;
  List<ScheduledSMS> _scheduledMessages = [];

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadScheduledMessages();
  }

  Future<void> _initializeService() async {
    try {
      await _smsService.initialize();
      
      // Listen to status updates
      _smsService.statusStream.listen((sms) {
        setState(() {
          final index = _scheduledMessages.indexWhere((s) => s.id == sms.id);
          if (index != -1) {
            _scheduledMessages[index] = sms;
          }
        });
        
        // Show notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SMS to ${sms.recipient}: ${sms.status.description}'),
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize: $e')),
      );
    }
  }

  Future<void> _loadScheduledMessages() async {
    final messages = await _smsService.getAllScheduledSms();
    setState(() {
      _scheduledMessages = messages;
    });
  }

  Future<void> _scheduleSms() async {
    if (_recipientController.text.isEmpty ||
        _messageController.text.isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      await _smsService.scheduleSms(
        recipient: _recipientController.text,
        message: _messageController.text,
        scheduledDate: _selectedDate!,
      );

      _recipientController.clear();
      _messageController.clear();
      setState(() {
        _selectedDate = null;
      });

      await _loadScheduledMessages();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS scheduled successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to schedule SMS: $e')),
      );
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _toggleActive(ScheduledSMS sms) async {
    if (sms.active) {
      await _smsService.disableScheduledSms(sms.id);
    } else {
      await _smsService.enableScheduledSms(sms.id);
    }
    await _loadScheduledMessages();
  }

  Future<void> _deleteSms(String id) async {
    await _smsService.deleteScheduledSms(id);
    await _loadScheduledMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SchedulerSMS'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Schedule form
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _recipientController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient (+63xxxxxxxxxx)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'No date selected'
                            : 'Scheduled: ${DateFormat('MMM dd, yyyy HH:mm').format(_selectedDate!)}',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _selectDateTime,
                      child: const Text('Select Date & Time'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _scheduleSms,
                    child: const Text('Schedule SMS'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Scheduled messages list
          Expanded(
            child: _scheduledMessages.isEmpty
                ? const Center(child: Text('No scheduled messages'))
                : ListView.builder(
                    itemCount: _scheduledMessages.length,
                    itemBuilder: (context, index) {
                      final sms = _scheduledMessages[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(sms.recipient),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sms.message),
                              const SizedBox(height: 4),
                              Text(
                                'Scheduled: ${DateFormat('MMM dd, yyyy HH:mm').format(sms.scheduledDate)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Status: ${sms.status.description}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: sms.active,
                                onChanged: (_) => _toggleActive(sms),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteSms(sms.id),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
