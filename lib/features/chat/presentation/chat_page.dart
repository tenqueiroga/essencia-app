import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  bool _isLoadingPerfume = false;
  List<Map<String, dynamic>> _conversations = [];

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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Icon
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.elevated,
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.gold, size: 26),
          ),
          const SizedBox(height: 20),
          // Title
          const Text(
            'SUA CONSULTORA\nDE FRAGRÂNCIAS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle
          const Text(
            'Me conte a ocasião e eu escolho o perfume ideal.\nTambém posso sugerir novas fragrâncias para sua coleção! 🌸',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 28),
          // Collection card (CTA)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.elevated,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Text(
                  'Para recomendações personalizadas, cadastre seus perfumes na Minha Coleção. Assim posso indicar a fragrância perfeita para cada momento! ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => GoRouter.of(context).go('/collection'),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Ir para Minha Coleção'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Suggestion chips as larger cards
          _buildSuggestionCards(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSuggestionCards() {
    final suggestions = [
      {'emoji': '🛍️', 'text': 'Quero comprar um novo!'},
      {'emoji': '🌙', 'text': 'Sugira algo para um encontro'},
      {'emoji': '💼', 'text': 'Perfume para o trabalho'},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // Dynamic weather chip
        _WeatherChip(onTap: (text) {
          _controller.text = text;
          _sendMessage();
        }),
        ...suggestions.map((s) => GestureDetector(
          onTap: () {
            _controller.text = s['text']!;
            _sendMessage();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.elevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '${s['emoji']} ${s['text']}',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
        )),
      ],
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
                hintText: 'Qual perfume você usará hoje?',
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(perfumeName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent)),
                const SizedBox(width: 3),
                const Icon(Icons.open_in_new, size: 10, color: AppColors.accent),
              ],
            ),
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
    if (_isLoadingPerfume) return; // Prevent multiple taps

    final cleanName =
        name.replaceAll(RegExp(r'\s*\(.*?\)\s*'), '').trim();

    setState(() => _isLoadingPerfume = true);

    // Show loading snackbar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('Buscando $cleanName...'),
            ],
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: AppColors.elevated,
        ),
      );
    }

    try {
      final response = await ApiClient().dio.get('/perfumes/search',
          queryParameters: {'q': cleanName});
      final results = response.data as List;
      if (results.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        openPerfumeDetailSheet(context, results.first);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfume não encontrado na base'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.elevated,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } finally {
      if (mounted) setState(() => _isLoadingPerfume = false);
    }
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

class _WeatherChip extends StatefulWidget {
  final void Function(String text) onTap;
  const _WeatherChip({required this.onTap});

  @override
  State<_WeatherChip> createState() => _WeatherChipState();
}

class _WeatherChipState extends State<_WeatherChip> {
  String? _chipText;
  String _emoji = '🌡️';

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final response = await ApiClient().dio.get('/suggestions/seasonal');
      final weather = response.data['weather'] as Map<String, dynamic>?;
      if (weather != null && mounted) {
        final temp = (weather['temperature'] as num).round();
        String emoji;
        String desc;
        if (temp >= 30) { emoji = '☀️'; desc = 'calor de ${temp}°C'; }
        else if (temp >= 25) { emoji = '🌤️'; desc = '${temp}°C agradáveis'; }
        else if (temp >= 18) { emoji = '🌥️'; desc = 'clima ameno (${temp}°C)'; }
        else { emoji = '🧥'; desc = 'frio de ${temp}°C'; }

        setState(() {
          _emoji = emoji;
          _chipText = 'O que usar com $desc?';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final text = _chipText ?? 'Qual perfume usar hoje?';
    return GestureDetector(
      onTap: () => widget.onTap(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Text(
          '$_emoji $text',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
      ),
    );
  }
}
