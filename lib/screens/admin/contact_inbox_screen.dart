import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/library_info.dart';
import '../../services/library_info_service.dart';
import '../../utils/theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';

/// Admin inbox for messages submitted by visitors via the landing page
/// Contact form. Each message comes from the local `contact_messages` table.
class ContactInboxScreen extends StatefulWidget {
  const ContactInboxScreen({super.key});

  @override
  State<ContactInboxScreen> createState() => _ContactInboxScreenState();
}

class _ContactInboxScreenState extends State<ContactInboxScreen> {
  List<ContactMessage> _items = [];
  bool _loading = true;
  bool _unhandledOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = context.read<LibraryInfoService>();
    setState(() => _loading = true);
    _items = await svc.inbox(unhandledOnly: _unhandledOnly);
    setState(() => _loading = false);
  }

  Future<void> _markHandled(ContactMessage m) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Mark as handled',
      message: 'Mark the message from "${m.name}" as handled? It will be hidden '
          'from the unread inbox.',
      confirmLabel: 'Mark handled',
    );
    if (confirmed != true) return;
    final svc = context.read<LibraryInfoService>();
    final auth = context.read<AuthProvider>();
    await svc.markContactHandled(m.id!, actorId: auth.currentUser?.id);
    _load();
  }

  Future<void> _delete(ContactMessage m) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete message',
      message: 'Permanently delete the message from "${m.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;
    final svc = context.read<LibraryInfoService>();
    final auth = context.read<AuthProvider>();
    await svc.deleteContactMessage(m.id!, actorId: auth.currentUser?.id);
    _load();
  }

  Future<void> _reply(BuildContext context, ContactMessage m) async {
    // Open the user's email client with prefilled subject/body. We don't ship
    // a mailto launcher here, so we just show the composed draft in a dialog
    // that the admin can copy.
    final draft = '''
To: ${m.email}
Subject: RE: ${m.subject}

Hello ${m.name},

Thank you for contacting the Injibara University Library.

[Your reply here]

Best regards,
The Library Team
''';
    await showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reply draft',
            style: TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: double.maxFinite,
          child: SelectableText(
            draft,
            style: const TextStyle(fontFamily: 'PT Serif', fontSize: 11.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _markHandled(m);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Mark handled'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppHeaderBar(
        title: 'Contact Inbox',
        subtitle: '${_items.length} message(s) shown',
        showMenu: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.cream,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Unhandled only'),
                  selected: _unhandledOnly,
                  onSelected: (v) {
                    setState(() => _unhandledOnly = v);
                    _load();
                  },
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: _unhandledOnly ? Colors.white : AppTheme.ink,
                    fontFamily: 'PT Serif',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFD6CFBE)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const EmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'No messages',
                        message: 'When visitors submit the Contact form on the '
                            'landing page, their messages appear here.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 60),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final m = _items[i];
                          return _MessageCard(
                            message: m,
                            onReply: () => _reply(context, m),
                            onMarkHandled: () => _markHandled(m),
                            onDelete: () => _delete(m),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final ContactMessage message;
  final VoidCallback onReply, onMarkHandled, onDelete;
  const _MessageCard({
    required this.message,
    required this.onReply,
    required this.onMarkHandled,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = message.isHandled ? AppTheme.success : AppTheme.warning;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Text(
                    message.name.isNotEmpty
                        ? message.name.substring(0, 1).toUpperCase()
                        : '?',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.name,
                        style: const TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      Text(
                        '${message.email} · ${DateUtilsX.relative(message.submittedAt)}',
                        style: const TextStyle(
                          fontFamily: 'PT Serif',
                          fontSize: 11,
                          color: AppTheme.slate,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    message.isHandled ? 'Handled' : 'New',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'PT Serif',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: Text(
                message.subject,
                style: const TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.message,
              style: const TextStyle(
                fontFamily: 'PT Serif',
                fontSize: 12.5,
                color: AppTheme.ink,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onReply,
                  icon: const Icon(Icons.reply_rounded, size: 16),
                  label: const Text('Reply'),
                ),
                const SizedBox(width: 8),
                if (!message.isHandled)
                  ElevatedButton.icon(
                    onPressed: onMarkHandled,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('Mark handled'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.danger, size: 18),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
