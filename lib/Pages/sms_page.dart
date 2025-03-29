import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class SmsPage extends StatefulWidget {
  const SmsPage({super.key});

  @override
  State<SmsPage> createState() => _SmsPageState();
}

class _SmsPageState extends State<SmsPage> {
  List<SmsMessage> _messages = [];
  final SmsQuery _smsQuery = SmsQuery();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndFetchSms();
  }

  Future<void> _requestPermissionAndFetchSms() async {
    var status = await Permission.sms.request();
    if (status.isGranted) {
      List<SmsMessage> messages = await _smsQuery.querySms(
        kinds: [SmsQueryKind.inbox],
      );
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("SMS permission denied.")),
        );
      }
    }
  }

  Map<String, List<SmsMessage>> _groupMessagesByDate() {
    final Map<String, List<SmsMessage>> groupedMessages = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final formatter = DateFormat('d MMMM yyyy');

    for (var message in _messages) {
      if (message.date == null) continue;
      final messageDate = DateTime(message.date!.year, message.date!.month, message.date!.day);
      String key;

      if (messageDate == today) {
        key = 'Today';
      } else if (messageDate == yesterday) {
        key = 'Yesterday';
      } else {
        key = formatter.format(messageDate);
      }

      groupedMessages.putIfAbsent(key, () => []).add(message);
    }
    return groupedMessages;
  }

  @override
  Widget build(BuildContext context) {
    final groupedMessages = _groupMessagesByDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text("SMS Messages"),
        backgroundColor: Colors.yellow.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupedMessages.isEmpty
              ? const Center(child: Text("No SMS messages found."))
              : ListView.builder(
                  itemCount: groupedMessages.length,
                  itemBuilder: (context, index) {
                    final dateKey = groupedMessages.keys.elementAt(index);
                    final messages = groupedMessages[dateKey]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          color: Colors.grey.shade200,
                          child: Text(
                            dateKey,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        ...messages.map((message) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.sender ?? "Unknown Sender",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          message.body ?? "No content",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    message.date != null
                                        ? DateFormat('h:mm a').format(message.date!)
                                        : "",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    );
                  },
                ),
    );
  }
}