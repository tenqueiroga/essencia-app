import 'package:flutter/material.dart';
import '../../../app/theme/olfato_tokens.dart';
import '../../../app/theme/olfato_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../collection/presentation/type_selection_dialog.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _barcodeController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _foundPerfume;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: OlfatoTheme.scannerTheme,
      child: Scaffold(
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scan / Adicionar', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Escaneie. Entenda. Escolha.',
                style: TextStyle(color: OlfatoTokens.vanilla, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'Escaneie o código de barras ou digite manualmente',
                style: TextStyle(color: OlfatoTokens.textSecondaryDark),
              ),
              const SizedBox(height: 24),

              // Barcode scanner placeholder (web)
              GlassCard(
                child: Column(
                  children: [
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: OlfatoTokens.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: OlfatoTokens.borderDark),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner, size: 48, color: OlfatoTokens.textSecondaryDark),
                          SizedBox(height: 8),
                          Text('Câmera disponível no app mobile', style: TextStyle(color: OlfatoTokens.textSecondaryDark, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _barcodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Digite o código de barras...',
                        prefixIcon: const Icon(Icons.barcode_reader, color: OlfatoTokens.textSecondaryDark),
                        suffixIcon: IconButton(
                          icon: _isSearching
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: OlfatoTokens.pitanga))
                              : const Icon(Icons.search, color: OlfatoTokens.pitanga),
                          onPressed: _searchByBarcode,
                        ),
                      ),
                      onSubmitted: (_) => _searchByBarcode(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Error message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: OlfatoTokens.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: OlfatoTokens.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: OlfatoTokens.error, fontSize: 13))),
                    ],
                  ),
                ),

              // Found perfume
              if (_foundPerfume != null) ...[
                const SizedBox(height: 16),
                const Text('Perfume Encontrado!', style: TextStyle(color: OlfatoTokens.amber, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(color: OlfatoTokens.surfaceDark, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.local_florist, color: OlfatoTokens.amber, size: 30),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_foundPerfume!['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  '${_foundPerfume!['brand']} • ${_foundPerfume!['concentration'] ?? ''}',
                                  style: const TextStyle(color: OlfatoTokens.textSecondaryDark),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_foundPerfume!['top_notes'] != null)
                        _buildNotes('Topo', _foundPerfume!['top_notes']),
                      if (_foundPerfume!['heart_notes'] != null)
                        _buildNotes('Coração', _foundPerfume!['heart_notes']),
                      if (_foundPerfume!['base_notes'] != null)
                        _buildNotes('Base', _foundPerfume!['base_notes']),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addToCollection,
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar à Coleção'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Quick search alternative
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to explore/search
                  Navigator.of(context).pushNamed('/explore');
                },
                icon: const Icon(Icons.search),
                label: const Text('Buscar por nome ou marca'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: OlfatoTokens.vanilla,
                  side: const BorderSide(color: OlfatoTokens.borderDark),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _searchByBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _foundPerfume = null;
    });

    try {
      final response = await ApiClient().dio.get('/perfumes/barcode/$barcode');
      setState(() {
        _foundPerfume = response.data;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Perfume não encontrado com esse código. Tente buscar pelo nome.';
        _isSearching = false;
      });
    }
  }

  Future<void> _addToCollection() async {
    if (_foundPerfume == null) return;

    // Require type selection before adding
    final selectedType = await showTypeSelectionDialog(context);
    if (selectedType == null) return; // user dismissed

    try {
      await ApiClient().dio.post('/collection', data: {
        'perfume_id': _foundPerfume!['id'],
        'type': selectedType.apiValue,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_foundPerfume!['name']} adicionado à coleção!'), backgroundColor: OlfatoTokens.amber),
        );
        setState(() {
          _foundPerfume = null;
          _barcodeController.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfume já está na coleção'), backgroundColor: OlfatoTokens.error),
        );
      }
    }
  }

  Widget _buildNotes(String label, List<dynamic> notes) {
    if (notes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 65, child: Text('$label:', style: const TextStyle(color: OlfatoTokens.textSecondaryDark, fontSize: 12))),
          Expanded(child: Text(notes.join(', '), style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }
}
