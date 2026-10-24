import 'package:flutter/material.dart';
import 'package:senmi/services/driver_api_service.dart';

class RideAdminNotificationsScreen extends StatefulWidget {
  const RideAdminNotificationsScreen({super.key});

  @override
  State<RideAdminNotificationsScreen> createState() =>
      _RideAdminNotificationsScreenState();
}

class _RideAdminNotificationsScreenState
    extends State<RideAdminNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _userIdController = TextEditingController();

  String _target = 'all';
  bool _sending = false;
  bool _loadingHistory = false;

  List<dynamic> _history = [];
  String? _historyError;

  static const Color _primary = Color(0xFF176B52);
  static const Color _background = Color(0xFFF5F7F6);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (_loadingHistory) return;

    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });

    try {
      final results = await RideService.getRideNotificationHistory();

      if (!mounted) return;

      setState(() {
        _history = results;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _historyError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingHistory = false;
        });
      }
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    int? userId;

    if (_target == 'single') {
      userId = int.tryParse(_userIdController.text.trim());

      if (userId == null || userId <= 0) {
        _showMessage('Enter a valid user ID.');
        return;
      }
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _sending = true;
    });

    try {
      final result = await RideService.sendRideNotification(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        target: _target,
        userId: userId,
      );

      if (!mounted) return;

      final recipientCount = result['recipient_count'];

      _showMessage(
        recipientCount != null
            ? 'Notification sent to $recipientCount recipient(s).'
            : 'Notification sent successfully.',
      );

      _titleController.clear();
      _messageController.clear();
      _userIdController.clear();

      await _loadHistory();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to send notification: '
        '${e.toString().replaceFirst('Exception: ', '')}',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red.shade700 : _primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _audienceLabel(dynamic value) {
    switch (value?.toString()) {
      case 'all':
        return 'All users';
      case 'drivers':
        return 'Drivers';
      case 'passengers':
        return 'Passengers';
      case 'single':
        return 'Single user';
      default:
        return value?.toString() ?? 'Unknown audience';
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Date unavailable';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();

    final local = date.toLocal();

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/${twoDigits(local.month)}/'
        '${local.year}  ${twoDigits(local.hour)}:'
        '${twoDigits(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Ride Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh history',
            onPressed: _loadingHistory ? null : _loadHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildComposeCard(),
              const SizedBox(height: 28),
              _buildHistoryHeader(),
              const SizedBox(height: 12),
              _buildHistory(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ride announcements',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Send updates to your Ride users and track sent messages.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposeCard() {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Compose notification',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              const Text(
                'Send to',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: _target,
                isExpanded: true,
                decoration: _inputDecoration(
                  hint: 'Select audience',
                  icon: Icons.groups_outlined,
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All users')),
                  DropdownMenuItem(value: 'drivers', child: Text('Drivers')),
                  DropdownMenuItem(
                    value: 'passengers',
                    child: Text('Passengers'),
                  ),
                  DropdownMenuItem(value: 'single', child: Text('One user')),
                ],
                onChanged: _sending
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          _target = value;
                        });
                      },
              ),

              if (_target == 'single') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _userIdController,
                  keyboardType: TextInputType.number,
                  enabled: !_sending,
                  decoration: _inputDecoration(
                    hint: 'Enter the user ID',
                    icon: Icons.person_outline,
                  ).copyWith(labelText: 'User ID'),
                  validator: (value) {
                    if (_target != 'single') return null;

                    final id = int.tryParse(value?.trim() ?? '');

                    if (id == null || id <= 0) {
                      return 'Enter a valid user ID.';
                    }

                    return null;
                  },
                ),
              ],

              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                enabled: !_sending,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(
                  hint: 'e.g. Important Ride update',
                  icon: Icons.title,
                ).copyWith(labelText: 'Notification title'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a notification title.';
                  }

                  if (value.trim().length > 200) {
                    return 'Title cannot exceed 200 characters.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                enabled: !_sending,
                minLines: 4,
                maxLines: 6,
                maxLength: 3000,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(
                  hint: 'Write your announcement here...',
                  icon: Icons.message_outlined,
                ).copyWith(labelText: 'Message', alignLabelWithHint: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the notification message.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _sending ? null : _sendNotification,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _sending
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    _sending ? 'Sending...' : 'Send notification',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: _primary),
      filled: true,
      fillColor: _background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Sent notification history',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          '${_history.length} messages',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    if (_loadingHistory && _history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_historyError != null && _history.isEmpty) {
      return _emptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load history',
        subtitle: _historyError!,
        action: TextButton.icon(
          onPressed: _loadHistory,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      );
    }

    if (_history.isEmpty) {
      return _emptyState(
        icon: Icons.notifications_none,
        title: 'No notifications yet',
        subtitle: 'Notifications you send will appear here.',
      );
    }

    return Column(
      children: _history.map((item) {
        final notification = item is Map
            ? Map<String, dynamic>.from(item)
            : <String, dynamic>{};

        final title =
            notification['title']?.toString() ?? 'Untitled notification';
        final message = notification['message']?.toString() ?? '';
        final target = notification['target'];
        final recipientCount = notification['recipient_count'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE3F1EB),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _audienceLabel(target),
                            style: const TextStyle(
                              color: _primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(color: Colors.grey.shade800, height: 1.5),
                  ),
                ],
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        recipientCount != null
                            ? '$recipientCount recipient(s)'
                            : 'Recipients not available',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        _formatDate(notification['created_at']),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
          ),
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      ),
    );
  }
}
