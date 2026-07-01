import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/perfume_detail_sheet.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  String? _conversationId;
  bool _isSending = false;
  List<Map<String, dynamic>> _conversations = [];

  final List<String> _suggestions = [
    'Qual perfume usar hoje?',
    'Sugira algo para o clima de agora',
    'Perfume para um jantar romântico?',
    'Tenho lacunas na coleção?',
    'Qual perfume para o trabalho?',
  ];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final response = await ApiClient().dio.get('/chat/conversations');
      if (mounted) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(response.data);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadConversation(String conversationId) async {
    try {
      final response = await ApiClient().dio.get('/chat/conversations/$conversationId/messages');
      final messages = List<Map<String, dynamic>>.from(response.data);
      if (mounted) {
        setState(() {
          _conversationId = conversationId;
          _messages.clear();
          for (final msg in messages) {
            _messages.add({
              'role': msg['role'] as String,
              'content': msg['content'] as String,
            });
          }
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Text('Essence AI',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  // History button
                  if (_conversations.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.history, color: AppColors.textSecondary),
                      tooltip: 'Histórico',
                      onPressed: _showHistory,
                    ),
                  // New chat button
                  if (_messages.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.add_comment_outlined, color: AppColors.textSecondary),
                      tooltip: 'Nova conversa',
                      onPressed: () => setState(() {
                        _messages.clear();
                        _conversationId = null;
                      }),
                    ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: _messages.isEmpty ? _buildEmptyChat() : _buildMessageList(),
            ),
            if (_messages.isEmpty) _buildSuggestionChips(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Conversas Anteriores',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conv = _conversations[index];
                    final msgCount = conv['messages_count'] ?? 0;
                    final updatedAt = conv['updated_at'] as String?;
                    final date = updatedAt != null
                        ? DateTime.tryParse(updatedAt)
                        : null;
                    final dateStr = date != null
                        ? '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'
                        : '';

                    return ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.chat_bubble_outline,
                            color: AppColors.accent, size: 18),
                      ),
                      title: Text('Conversa ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('$msgCount mensagens • $dateStr',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      trailing: conv['id'] == _conversationId
                          ? const Icon(Icons.check_circle,
                              color: AppColors.gold, size: 18)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        _loadConversation(conv['id']);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyChat() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 56, color: AppColors.gold),
          SizedBox(height: 16),
          Text('Olá! Sou a Essence AI 🌿',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Especialista em perfumaria!\nPosso sugerir o perfume ideal para o clima, ocasião ou estilo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isSending) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.gold)),
                  SizedBox(width: 8),
                  Text('Pensando...',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
          );
        }
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              borderRadius: 14,
              child: _buildMessageContent(context, msg['content'] ?? '', isUser),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionChips() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _suggestions.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(_suggestions[index],
                    style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.surfaceLight,
                side: const BorderSide(color: AppColors.glassBorder),
                onPressed: () {
                  _controller.text = _suggestions[index];
                  _sendMessage();
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isSending,
              decoration: InputDecoration(
                hintText: 'Pergunte sobre perfumes...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor:
                _isSending ? AppColors.textMuted : AppColors.gold,
            child: IconButton(
              icon: const Icon(Icons.send,
                  color: AppColors.background, size: 20),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
      BuildContext context, String content, bool isUser) {
    if (isUser) {
      return Text(content,
          style: const TextStyle(fontSize: 14, height: 1.4));
    }

    // Parse markdown bold (**text**) as perfume links
    final regex = RegExp(r'\*\*(.+?)\*\*');
    final matches = regex.allMatches(content);

    if (matches.isEmpty) {
      return Text(content,
          style: const TextStyle(fontSize: 14, height: 1.4));
    }

    // Build rich text with clickable perfume names
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
            text: content.substring(lastEnd, match.start),
            style: const TextStyle(
                fontSize: 14, height: 1.4, color: AppColors.textPrimary)));
      }
      // The perfume name (clickable)
      final perfumeName = match.group(1)!;
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onTap: () => _openPerfumeByName(context, perfumeName),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
            decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.3))),
            child: Text(perfumeName,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent)),
          ),
        ),
      ));
      lastEnd = match.end;
    }

    // Remaining text
    if (lastEnd < content.length) {
      spans.add(TextSpan(
          text: content.substring(lastEnd),
          style: const TextStyle(
              fontSize: 14, height: 1.4, color: AppColors.textPrimary)));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Future<void> _openPerfumeByName(BuildContext context, String name) async {
    final cleanName =
        name.replaceAll(RegExp(r'\s*\(.*?\)\s*'), '').trim();

    try {
      final response = await ApiClient().dio.get('/perfumes/search',
          queryParameters: {'q': cleanName});
      final results = response.data as List;
      if (results.isNotEmpty && context.mounted) {
        openPerfumeDetailSheet(context, results.first);
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isSending = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      // Create conversation if needed
      if (_conversationId == null) {
        final convResponse =
            await ApiClient().dio.post('/chat/conversations');
        _conversationId = convResponse.data['id'];
        // Refresh conversation list
        _loadConversations();
      }

      // Send message
      final response = await ApiClient().dio.post(
        '/chat/conversations/$_conversationId/messages',
        data: {'message': text},
      );

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response.data['content'] ?? 'Sem resposta'
        });
        _isSending = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              '⚠️ Não consegui processar sua pergunta. Tente novamente em instantes.'
        });
        _isSending = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
