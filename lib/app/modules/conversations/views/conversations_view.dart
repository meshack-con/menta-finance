import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/controllers/admin_badges_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/ruler_avatar.dart';
import '../models/conversation_model.dart';

/// Ukurasa wa Admin kuona/kujibu mazungumzo na Wanachama - muundo wa
/// paneli mbili: kushoto orodha ya mazungumzo, kulia 'thread' iliyochaguliwa.
class ConversationsView extends StatefulWidget {
  const ConversationsView({super.key});

  @override
  State<ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends State<ConversationsView> {
  List<ConversationModel> _conversations = [];
  bool _isLoadingList = true;
  int? _selectedRulerId;
  String? _selectedRulerName;
  String? _selectedMembershipCode;
  List<ConversationMessageModel> _thread = [];
  bool _isLoadingThread = false;
  final _replyCtrl = TextEditingController();
  bool _isSending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _loadConversations(silent: true);
      if (_selectedRulerId != null) _loadThread(_selectedRulerId!, silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent) setState(() => _isLoadingList = true);
    try {
      final data = await Get.find<ApiClient>().get('/api/admin/messages/conversations');
      final updated = (data as List).map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) setState(() => _conversations = updated);
    } catch (_) {
    } finally {
      if (mounted && !silent) setState(() => _isLoadingList = false);
    }
  }

  Future<void> _loadThread(int rulerId, {bool silent = false}) async {
    if (!silent) setState(() => _isLoadingThread = true);
    try {
      final data = await Get.find<ApiClient>().get('/api/admin/messages/conversations/$rulerId');
      final updated = (data as List).map((e) => ConversationMessageModel.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted && _selectedRulerId == rulerId) setState(() => _thread = updated);
    } catch (_) {
      if (!silent) _thread = [];
    } finally {
      if (mounted && !silent) setState(() => _isLoadingThread = false);
    }
    Get.find<AdminBadgesController>().refresh_();
  }

  Future<void> _openConversation(ConversationModel c) async {
    setState(() {
      _selectedRulerId = c.rulerId;
      _selectedRulerName = c.rulerName;
      _selectedMembershipCode = c.membershipCode;
    });
    await _loadThread(c.rulerId);
    _loadConversations(silent: true);
  }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty || _selectedRulerId == null) return;
    setState(() => _isSending = true);
    try {
      await Get.find<ApiClient>().post('/api/admin/messages/conversations/$_selectedRulerId/reply', body: {'message': _replyCtrl.text.trim()});
      _replyCtrl.clear();
      await _loadThread(_selectedRulerId!);
      _loadConversations(silent: true);
    } catch (_) {
      Get.snackbar('Hitilafu', 'Imeshindikana kutuma jibu.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteMessage(ConversationMessageModel m) async {
    final confirmed = await Get.dialog<bool>(AlertDialog(
      title: const Text('Futa Ujumbe'),
      content: const Text('Una uhakika unataka kufuta ujumbe huu?'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Ghairi')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Get.back(result: true),
          child: const Text('Futa'),
        ),
      ],
    ));
    if (confirmed != true) return;
    try {
      await Get.find<ApiClient>().delete('/api/admin/messages/conversations/messages/${m.id}');
      if (_selectedRulerId != null) await _loadThread(_selectedRulerId!);
    } catch (_) {
      Get.snackbar('Hitilafu', 'Imeshindikana kufuta ujumbe.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Mazungumzo na Wanachama',
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 180,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 340, child: _buildConversationsList()),
            const SizedBox(width: 16),
            Expanded(child: _buildThreadPanel()),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.06), border: const Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(children: [
              const Icon(Icons.forum_outlined, size: 18, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Text('Mazungumzo (${_conversations.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.primaryGreen)),
            ]),
          ),
          Expanded(
            child: _isLoadingList
                ? const Center(child: CircularProgressIndicator())
                : _conversations.isEmpty
                    ? const EmptyStateWidget(icon: Icons.chat_bubble_outline, title: 'Hakuna Mazungumzo', subtitle: 'Wanachama watakapotuma ujumbe, yataonekana hapa.')
                    : ListView.separated(
                        itemCount: _conversations.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, i) {
                          final c = _conversations[i];
                          final isSelected = c.rulerId == _selectedRulerId;
                          return InkWell(
                            onTap: () => _openConversation(c),
                            child: Container(
                              color: isSelected ? AppColors.primaryGreen.withOpacity(0.08) : null,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  RulerAvatar(rulerId: c.rulerId, name: c.rulerName, radius: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.rulerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 2),
                                        Text(c.lastMessage ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  if (c.unreadCount > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(10)),
                                      child: Text('${c.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadPanel() {
    final cardDecoration = BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
    );

    if (_selectedRulerId == null) {
      return Container(
        decoration: cardDecoration,
        child: const EmptyStateWidget(icon: Icons.forum_outlined, title: 'Chagua Mazungumzo', subtitle: 'Bofya mwanachama upande wa kushoto kuona/kujibu ujumbe wake.'),
      );
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: cardDecoration,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryGreen.withOpacity(0.06),
            child: Row(children: [
              RulerAvatar(rulerId: _selectedRulerId, name: _selectedRulerName ?? '', radius: 18),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedRulerName ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                  if (_selectedMembershipCode != null) Text(_selectedMembershipCode!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ]),
          ),
          Expanded(
            child: Container(
              color: AppColors.inputFill.withOpacity(0.4),
              child: _isLoadingThread
                  ? const Center(child: CircularProgressIndicator())
                  : _thread.isEmpty
                      ? const EmptyStateWidget(icon: Icons.chat_bubble_outline, title: 'Bado Hakuna Ujumbe', subtitle: 'Andika jibu chini kuanza mazungumzo.')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _thread.length,
                          itemBuilder: (context, i) => _buildBubble(_thread[i]),
                        ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _replyCtrl,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Andika jibu lako...',
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendReply(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _isSending ? null : _sendReply,
                icon: _isSending ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(ConversationMessageModel m) {
    final isAdmin = m.sender == 'ADMIN';
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAdmin ? AppColors.primaryGreen : Theme.of(context).cardColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isAdmin ? 14 : 2),
          bottomRight: Radius.circular(isAdmin ? 2 : 14),
        ),
        border: isAdmin ? null : Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(m.message, style: TextStyle(color: isAdmin ? Colors.white : AppColors.textPrimary, fontSize: 13.5)),
          const SizedBox(height: 3),
          Text(DateFormat('dd/MM HH:mm').format(m.createdAt), style: TextStyle(fontSize: 10, color: isAdmin ? Colors.white70 : AppColors.textSecondary)),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: isAdmin
            ? [
                // MUHIMU: kitufe cha kufuta kinaonekana TU kwenye ujumbe za
                // ADMIN (backend inazuia kufuta za MEMBER pia, hii ni
                // ulinzi wa ziada upande wa UI).
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textSecondary),
                  onPressed: () => _deleteMessage(m),
                  tooltip: 'Futa',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
                const SizedBox(width: 4),
                bubble,
              ]
            : [bubble],
      ),
    );
  }
}
