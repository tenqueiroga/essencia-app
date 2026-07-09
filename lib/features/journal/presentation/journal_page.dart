import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/olfato_tokens.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/glass_card.dart';

class JournalPage extends ConsumerStatefulWidget {
  const JournalPage({super.key});

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDay;
  List<dynamic> _entries = [];
  List<dynamic> _collection = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _proxyUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.contains('fimgs.net')) {
      return 'https://perfumia.com.br/api/image-proxy?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final responses = await Future.wait([
        ApiClient().dio.get('/journal', queryParameters: {
          'month': _selectedMonth.month,
          'year': _selectedMonth.year,
        }),
        ApiClient().dio.get('/collection'),
      ]);
      setState(() {
        _entries = responses[0].data as List<dynamic>;
        _collection = (responses[1].data['data'] as List<dynamic>?) ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diário Olfativo'),
        backgroundColor: Colors.transparent,
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: OlfatoTokens.amber))
        : Column(
            children: [
              _buildMonthSelector(),
              _buildCalendar(),
              const Divider(color: OlfatoTokens.borderLight),
              Expanded(child: _buildDayEntries()),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: OlfatoTokens.amber,
        onPressed: _showAddEntry,
        child: const Icon(Icons.add, color: OlfatoTokens.vanilla),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: OlfatoTokens.amber),
            onPressed: () {
              setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
              _loadData();
            },
          ),
          Text(
            DateFormat('MMMM yyyy', 'pt_BR').format(_selectedMonth),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: OlfatoTokens.amber),
            onPressed: () {
              setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    // Days with entries
    final entryDays = _entries.map((e) {
      final dateStr = e['date']?.toString() ?? '';
      final date = DateTime.tryParse(dateStr);
      return date?.day ?? 0;
    }).toSet();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'].map((d) => Expanded(
              child: Center(child: Text(d, style: const TextStyle(color: OlfatoTokens.gray, fontSize: 11))),
            )).toList(),
          ),
          const SizedBox(height: 4),
          // Days grid
          ...List.generate(6, (week) {
            return Row(
              children: List.generate(7, (dow) {
                final dayIndex = week * 7 + dow - startWeekday + 1;
                if (dayIndex < 1 || dayIndex > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 36));
                }

                final isToday = dayIndex == DateTime.now().day &&
                    _selectedMonth.month == DateTime.now().month &&
                    _selectedMonth.year == DateTime.now().year;
                final hasEntry = entryDays.contains(dayIndex);
                final isSelected = _selectedDay?.day == dayIndex;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDay = DateTime(_selectedMonth.year, _selectedMonth.month, dayIndex)),
                    child: Container(
                      height: 36,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isSelected ? OlfatoTokens.amber.withValues(alpha: 0.2)
                            : hasEntry ? OlfatoTokens.amber.withValues(alpha: 0.08)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday ? Border.all(color: OlfatoTokens.amber, width: 1) : null,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$dayIndex', style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? OlfatoTokens.amber : OlfatoTokens.ink,
                              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal)),
                            if (hasEntry)
                              Container(width: 4, height: 4, decoration: BoxDecoration(
                                color: OlfatoTokens.amber, shape: BoxShape.circle)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayEntries() {
    if (_selectedDay == null) {
      return const Center(child: Text('Selecione um dia para ver ou registrar', style: TextStyle(color: OlfatoTokens.gray)));
    }

    final dayStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final dayEntries = _entries.where((e) {
      final entryDate = e['date']?.toString() ?? '';
      // Handle both "2026-07-06" and "2026-07-06T00:00:00.000000Z" formats
      return entryDate.startsWith(dayStr);
    }).toList();

    if (dayEntries.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.edit_note, size: 40, color: OlfatoTokens.gray),
          const SizedBox(height: 8),
          Text('Nenhum registro em ${DateFormat('dd/MM').format(_selectedDay!)}',
            style: const TextStyle(color: OlfatoTokens.gray)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _showAddEntry,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Registrar perfume'),
          ),
        ],
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayEntries.length,
      itemBuilder: (_, i) {
        final entry = dayEntries[i];
        final perfume = entry['perfume'];
        final imageUrl = _proxyUrl(perfume?['image_url'] as String?);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Perfume image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 60,
                    color: Colors.white,
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.local_florist, color: OlfatoTokens.amber, size: 24))
                        : const Icon(Icons.local_florist, color: OlfatoTokens.amber, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(perfume?['name'] ?? 'Perfume', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (perfume?['brand'] != null)
                      Text(perfume['brand'], style: const TextStyle(color: OlfatoTokens.amber, fontSize: 12)),
                    if (entry['occasion'] != null)
                      Text(entry['occasion'], style: const TextStyle(color: OlfatoTokens.gray, fontSize: 12)),
                    if (entry['notes'] != null)
                      Text(entry['notes'], style: const TextStyle(color: OlfatoTokens.gray, fontSize: 11)),
                  ],
                )),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: OlfatoTokens.error, size: 20),
                  onPressed: () async {
                    await ApiClient().dio.delete('/journal/${entry['id']}');
                    _loadData();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddEntry() {
    if (_collection.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Adicione perfumes à coleção primeiro'),
        backgroundColor: OlfatoTokens.error));
      return;
    }

    String? selectedPerfumeId;
    final occasionCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final date = _selectedDay ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: OlfatoTokens.mist,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: OlfatoTokens.gray, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Registrar — ${DateFormat('dd/MM/yyyy').format(date)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              // Perfume selector
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(hintText: 'Selecionar perfume'),
                dropdownColor: OlfatoTokens.mist,
                items: _collection.map<DropdownMenuItem<String>>((item) {
                  final p = item['perfume'];
                  return DropdownMenuItem(value: p['id'] as String, child: Text(p['name'] ?? ''));
                }).toList(),
                onChanged: (v) => selectedPerfumeId = v,
              ),
              const SizedBox(height: 12),
              TextField(controller: occasionCtrl, decoration: const InputDecoration(hintText: 'Ocasião (opcional)')),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, decoration: const InputDecoration(hintText: 'Notas pessoais (opcional)'), maxLines: 2),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () async {
                  if (selectedPerfumeId == null) return;
                  await ApiClient().dio.post('/journal', data: {
                    'perfume_id': selectedPerfumeId,
                    'date': DateFormat('yyyy-MM-dd').format(date),
                    'occasion': occasionCtrl.text.isNotEmpty ? occasionCtrl.text : null,
                    'notes': notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                  });
                  if (mounted) { Navigator.pop(ctx); _loadData(); }
                },
                child: const Text('Salvar Registro'),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
