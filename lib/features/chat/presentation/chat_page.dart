import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/olfato_tokens.dart';
import '../../../core/network/api_client.dart';
import '../models/daily_suggestion.dart';
import 'chat_helpers.dart';

/// Private typedef for the public PerfumeSuggestion used within this page.
typedef _PerfumeSuggestion = PerfumeSuggestion;

class ChatPage extends StatefulWidget {
  final String? initialMessage;
  const ChatPage({super.key, this.initialMessage});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  String? _conversationId;
  bool _isSending = false;
  String? _lastFailedMessage;
  DailySuggestion? _dailySuggestion;
  bool _loadingSuggestion = false;

  static const _quickChips = [
    'Perfume para o calor',
    'Dupe de luxo',
    'Escolha um decante',
    'Presente até R\$300',
  ];

  @override
  void initState() {
    super.initState();
    _loadDailySuggestion();
    // If an initial message was provided (e.g., from scan/detail pages), send it
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = widget.initialMessage!;
        _sendMessage();
      });
    }
  }

  Future<void> _loadDailySuggestion() async {
    setState(() => _loadingSuggestion = true);
    try {
      final response = await ApiClient().dio.get('/suggestions/daily');
      final data = response.data as Map<String, dynamic>;
      final suggestionData = data['suggestion'] as Map<String, dynamic>? ?? data;
      if (mounted) {
        setState(() {
          _dailySuggestion = DailySuggestion.fromJson({
            'perfume_name': suggestionData['perfume']?['name'] ?? suggestionData['perfume_name'] ?? '',
            'compatibility_score': suggestionData['compatibility_score'] ?? 0,
            'justification': suggestionData['justification'] ?? '',
            'is_owned': suggestionData['is_owned'] ?? false,
            'perfume_id': suggestionData['perfume']?['id']?.toString() ?? suggestionData['perfume_id']?.toString(),
          });
          _loadingSuggestion = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSuggestion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OlfatoTokens.vanilla,
      body: SafeArea(
        child: Column(
          children: [
            _buildAuraHeader(context),
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : _buildMessageList(),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // ─── AuraHeader ──────────────────────────────────────────────────────────

  Widget _buildAuraHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: OlfatoTokens.vanilla,
        border: Border(
          bottom: BorderSide(
            color: OlfatoTokens.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Gradient avatar
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: OlfatoTokens.auraGradient,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          // Title
          Text(
            'Aura',
            style: GoogleFonts.ebGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: OlfatoTokens.ink,
            ),
          ),
          const Spacer(),
          // History button
          IconButton(
            icon: const Icon(Icons.history, color: OlfatoTokens.gray),
            onPressed: _showConversationHistory,
            tooltip: 'Histórico',
          ),
          // Close button (X)
          IconButton(
            icon: const Icon(Icons.close, color: OlfatoTokens.ink),
            onPressed: () => context.pop(),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }

  // ─── Empty State (QuickChips + SugestaoDoDia) ─────────────────────────────

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sugestão do Dia card
          if (_dailySuggestion != null) _buildSugestaoDoDiaCard(),
          if (_dailySuggestion != null) const SizedBox(height: 24),
          if (_loadingSuggestion)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: OlfatoTokens.plum,
                ),
              ),
            ),

          // Quick Chips section
          Text(
            'Pergunte à Aura',
            style: GoogleFonts.ebGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: OlfatoTokens.ink,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickChips.map((chip) => _buildQuickChip(chip)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String text) {
    return GestureDetector(
      onTap: () {
        _controller.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: OlfatoTokens.mist,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          border: Border.all(color: OlfatoTokens.borderLight),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: OlfatoTokens.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildSugestaoDoDiaCard() {
    final suggestion = _dailySuggestion!;
    return GestureDetector(
      onTap: suggestion.perfumeId != null
          ? () => context.push('/perfume/${suggestion.perfumeId}')
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: OlfatoTokens.auraGradient,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
          boxShadow: [OlfatoTokens.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Sugestão do dia',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              suggestion.perfumeName,
              style: GoogleFonts.ebGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${suggestion.compatibilityScore}% compatível',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.justification,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
            if (!suggestion.isOwned) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Não está na sua coleção',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Message List ─────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isSending) {
          return _buildTypingIndicator();
        }
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        final content = msg['content'] as String? ?? '';
        final isError = msg['isError'] == true;

        if (isError) {
          return _buildErrorMessage(content);
        }

        if (!isUser) {
          // Parse perfume suggestions from Aura response
          final suggestions = _parsePerfumeSuggestions(content);
          if (suggestions.isNotEmpty) {
            return _buildAuraMessageWithCards(content, suggestions);
          }
        }

        return _buildMessageBubble(content, isUser);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: OlfatoTokens.vanilla,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          border: Border.all(color: OlfatoTokens.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: OlfatoTokens.plum,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Pensando...',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: OlfatoTokens.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? OlfatoTokens.mist : OlfatoTokens.vanilla,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          border: Border.all(color: OlfatoTokens.borderLight, width: 0.5),
        ),
        child: Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: OlfatoTokens.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String content) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OlfatoTokens.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          border: Border.all(
            color: OlfatoTokens.error.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: OlfatoTokens.error,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _retryLastMessage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: OlfatoTokens.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tentar novamente',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: OlfatoTokens.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuraMessageWithCards(
    String content,
    List<_PerfumeSuggestion> suggestions,
  ) {
    // Remove perfume pattern lines from content for cleaner text display
    final cleanedContent = _removePerfumePatterns(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cleanedContent.trim().isNotEmpty)
          _buildMessageBubble(cleanedContent.trim(), false),
        // Inline perfume cards
        ...suggestions.map((s) => _buildInlinePerfumeCard(s)),
      ],
    );
  }

  Widget _buildInlinePerfumeCard(_PerfumeSuggestion suggestion) {
    return GestureDetector(
      onTap: () => _navigateToPerfume(suggestion),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 0, right: 40),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
          border: Border.all(color: OlfatoTokens.borderLight),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 2),
              blurRadius: 8,
              color: OlfatoTokens.ink.withValues(alpha: 0.05),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gradient accent bar
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                gradient: OlfatoTokens.auraGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: OlfatoTokens.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    suggestion.house,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: OlfatoTokens.gray,
                    ),
                  ),
                ],
              ),
            ),
            // Compatibility badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: OlfatoTokens.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${suggestion.compatibility}%',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: OlfatoTokens.green,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: OlfatoTokens.gray,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Input Area ──────────────────────────────────────────────────────────

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: OlfatoTokens.vanilla,
        border: Border(
          top: BorderSide(color: OlfatoTokens.borderLight, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_isSending,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: OlfatoTokens.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Pergunte algo à Aura...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: OlfatoTokens.gray,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: OlfatoTokens.mist,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isSending ? null : OlfatoTokens.auraGradient,
                  color: _isSending ? OlfatoTokens.gray : null,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Disclaimer
          Text(
            'Aura pode cometer erros. Confirme sempre.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: OlfatoTokens.gray,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ─── Messaging Logic ─────────────────────────────────────────────────────

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
      }

      // Send message with 15s timeout
      final response = await ApiClient()
          .dio
          .post(
            '/chat/conversations/$_conversationId/messages',
            data: {'message': text},
          )
          .timeout(const Duration(seconds: 15));

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response.data['content'] ?? 'Sem resposta',
        });
        _isSending = false;
        _lastFailedMessage = null;
      });
    } on TimeoutException {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Não foi possível obter resposta. Tempo esgotado.',
          'isError': true,
        });
        _isSending = false;
        _lastFailedMessage = text;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              'Não consegui processar sua pergunta. Tente novamente.',
          'isError': true,
        });
        _isSending = false;
        _lastFailedMessage = text;
      });
    }
    _scrollToBottom();
  }

  void _retryLastMessage() {
    if (_lastFailedMessage == null) return;
    // Remove the error message
    setState(() {
      if (_messages.isNotEmpty && _messages.last['isError'] == true) {
        _messages.removeLast();
      }
      // Also remove the user message that failed
      if (_messages.isNotEmpty && _messages.last['role'] == 'user') {
        _messages.removeLast();
      }
    });
    _controller.text = _lastFailedMessage!;
    _sendMessage();
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

  // ─── Perfume Suggestion Parsing ───────────────────────────────────────────

  /// Delegates to the top-level [parsePerfumeSuggestions] function.
  List<_PerfumeSuggestion> _parsePerfumeSuggestions(String content) {
    return parsePerfumeSuggestions(content);
  }

  /// Removes perfume pattern lines from the content so the text bubble
  /// displays the prose without the structured data that gets shown as cards.
  String _removePerfumePatterns(String content) {
    // Remove lines matching numbered perfume patterns
    final lines = content.split('\n');
    final cleaned = lines.where((line) {
      final trimmed = line.trim();
      // Remove lines that are purely perfume entries
      if (RegExp(r'^\d+\.\s*.+[-–—].+[-–—]\s*\d{1,3}%').hasMatch(trimmed)) {
        return false;
      }
      if (RegExp(r'^\*\*.+\*\*\s*[-–—]?\s*.+\s*[-–—]?\s*\d{1,3}%')
          .hasMatch(trimmed)) {
        return false;
      }
      return true;
    }).toList();
    return cleaned.join('\n');
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  Future<void> _navigateToPerfume(_PerfumeSuggestion suggestion) async {
    if (suggestion.id != null && suggestion.id!.isNotEmpty) {
      context.push('/perfume/${suggestion.id}');
      return;
    }
    // Try exact search first
    try {
      final response = await ApiClient().dio.get(
        '/perfumes/search',
        queryParameters: {'q': '${suggestion.name} ${suggestion.house}'.trim()},
      );
      final results = response.data;
      final list = results is List ? results : [];
      if (list.isNotEmpty && mounted) {
        // Find best match by name similarity
        final exactMatch = list.firstWhere(
          (p) => (p['name'] as String?)?.toLowerCase() == suggestion.name.toLowerCase(),
          orElse: () => list.first,
        );
        final perfumeId = exactMatch['id']?.toString();
        if (perfumeId != null && perfumeId.isNotEmpty) {
          context.push('/perfume/$perfumeId');
          return;
        }
      }
    } catch (_) {}
    
    // Fallback: show snackbar that perfume wasn't found
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Não encontrei "${suggestion.name}" na base. Tente buscar no Explorar.'),
        backgroundColor: OlfatoTokens.gray,
      ));
    }
  }

  // ─── Conversation History ───────────────────────────────────────────────

  Future<void> _showConversationHistory() async {
    try {
      final response = await ApiClient().dio.get('/chat/conversations');
      final conversations = response.data as List;
      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        backgroundColor: OlfatoTokens.vanilla,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        isScrollControlled: true,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scroll) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: OlfatoTokens.gray, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  Text('Conversas anteriores', style: GoogleFonts.ebGaramond(fontSize: 20, fontWeight: FontWeight.w700, color: OlfatoTokens.ink)),
                ]),
              ),
              Expanded(
                child: conversations.isEmpty
                  ? Center(child: Text('Nenhuma conversa anterior', style: GoogleFonts.inter(color: OlfatoTokens.gray)))
                  : ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: conversations.length,
                      itemBuilder: (_, i) {
                        final conv = conversations[i] as Map<String, dynamic>;
                        final lastMessage = conv['last_message'] as String? ?? conv['title'] as String? ?? 'Conversa ${i + 1}';
                        final updatedAt = conv['updated_at'] as String?;
                        
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _loadConversation(conv['id']?.toString() ?? '');
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: OlfatoTokens.mist,
                              borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
                              border: Border.all(color: OlfatoTokens.borderLight),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.chat_bubble_outline, color: OlfatoTokens.plum, size: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lastMessage,
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: OlfatoTokens.ink),
                                        maxLines: 2, overflow: TextOverflow.ellipsis,
                                      ),
                                      if (updatedAt != null)
                                        Text(
                                          _formatDate(updatedAt),
                                          style: GoogleFonts.inter(fontSize: 11, color: OlfatoTokens.gray),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: OlfatoTokens.gray, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _loadConversation(String conversationId) async {
    if (conversationId.isEmpty) return;
    try {
      final response = await ApiClient().dio.get('/chat/conversations/$conversationId/messages');
      final messages = response.data as List;
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Há ${diff.inHours}h';
      if (diff.inDays < 7) return 'Há ${diff.inDays} dias';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
