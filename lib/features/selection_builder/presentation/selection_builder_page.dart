import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/olfato_tokens.dart';
import '../../../core/network/api_client.dart';

/// Occasion options for Monte uma Seleção.
enum SelectionOccasion {
  trabalho('Trabalho'),
  noite('Noite'),
  date('Date'),
  presente('Presente');

  final String label;
  const SelectionOccasion(this.label);
}

/// Budget qualifier options (no real prices displayed).
enum BudgetQualifier {
  none('Sem preferência'),
  economico('Econômico'),
  intermediario('Intermediário'),
  premium('Premium');

  final String label;
  const BudgetQualifier(this.label);
}

/// Model for a perfume recommendation in the selection result.
class _PerfumeRecommendation {
  final String name;
  final String brand;
  final String volume;
  final String justification;

  const _PerfumeRecommendation({
    required this.name,
    required this.brand,
    required this.volume,
    required this.justification,
  });

  factory _PerfumeRecommendation.fromJson(Map<String, dynamic> json) {
    return _PerfumeRecommendation(
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      volume: json['volume'] as String? ?? '',
      justification: json['justification'] as String? ?? '',
    );
  }
}

/// Monte uma Seleção / Modo Presente page.
///
/// Route: `/selection-builder`
///
/// Allows users to build curated perfume selections for different occasions.
/// Calls POST `/api/chat/selection` with occasion, description, and budget qualifier.
class SelectionBuilderPage extends StatefulWidget {
  const SelectionBuilderPage({super.key});

  @override
  State<SelectionBuilderPage> createState() => _SelectionBuilderPageState();
}

class _SelectionBuilderPageState extends State<SelectionBuilderPage> {
  SelectionOccasion _selectedOccasion = SelectionOccasion.trabalho;
  BudgetQualifier _selectedBudget = BudgetQualifier.none;
  final TextEditingController _descriptionController = TextEditingController();
  String? _validationError;

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  List<_PerfumeRecommendation> _results = [];

  static const int _maxDescriptionLength = 500;
  static const int _minDescriptionLength = 10;
  static const Duration _timeout = Duration(seconds: 15);

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // ─── Validation ──────────────────────────────────────────────────────────

  bool _validateInput() {
    final text = _descriptionController.text.trim();
    if (text.isEmpty || text.length < _minDescriptionLength) {
      setState(() {
        _validationError = 'Descreva com mais detalhes o que busca.';
      });
      return false;
    }
    setState(() => _validationError = null);
    return true;
  }

  // ─── API Call ────────────────────────────────────────────────────────────

  Future<void> _generateSelection() async {
    if (!_validateInput()) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _results = [];
    });

    try {
      final response = await ApiClient()
          .dio
          .post('/chat/selection', data: {
            'occasion': _selectedOccasion.label.toLowerCase(),
            'description': _descriptionController.text.trim(),
            'budget_qualifier': _selectedBudget == BudgetQualifier.none
                ? null
                : _selectedBudget.label.toLowerCase(),
          })
          .timeout(_timeout);

      final data = response.data as Map<String, dynamic>;
      final perfumesJson = data['perfumes'] as List? ?? data['recommendations'] as List? ?? [];

      if (mounted) {
        setState(() {
          _results = perfumesJson
              .map((p) =>
                  _PerfumeRecommendation.fromJson(p as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage =
              'Não foi possível gerar a seleção. Tempo esgotado.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage =
              'Não foi possível gerar a seleção. Tente novamente.';
        });
      }
    }
  }

  // ─── Share ───────────────────────────────────────────────────────────────

  Future<void> _shareResults() async {
    if (_results.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('🎁 Minha Seleção Olfato — ${_selectedOccasion.label}');
    buffer.writeln();

    for (var i = 0; i < _results.length; i++) {
      final r = _results[i];
      buffer.writeln('${i + 1}. ${r.name} — ${r.brand} (${r.volume})');
      buffer.writeln('   ${r.justification}');
      buffer.writeln();
    }

    buffer.writeln('Criado com Olfato ✨');

    final text = buffer.toString();

    // Use the Clipboard + platform share intent approach
    // Since share_plus is not available, copy to clipboard as fallback
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Seleção copiada para compartilhar!',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: OlfatoTokens.plum,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          ),
        ),
      );
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OlfatoTokens.vanilla,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Monte uma Seleção',
          style: GoogleFonts.ebGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: OlfatoTokens.ink,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: OlfatoTokens.ink),
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Occasion tabs
          _buildOccasionTabs(),
          const SizedBox(height: 24),

          // Description input
          _buildDescriptionInput(),
          const SizedBox(height: 16),

          // Budget qualifier dropdown
          _buildBudgetDropdown(),
          const SizedBox(height: 24),

          // Generate button
          _buildGenerateButton(),

          // Error state
          if (_hasError) ...[
            const SizedBox(height: 24),
            _buildErrorState(),
          ],

          // Results
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildResultsSection(),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Occasion Tabs ───────────────────────────────────────────────────────

  Widget _buildOccasionTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ocasião',
          style: GoogleFonts.ebGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: OlfatoTokens.ink,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: OlfatoTokens.mist,
            borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
            border: Border.all(color: OlfatoTokens.borderLight),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: SelectionOccasion.values.map((occasion) {
              final isSelected = _selectedOccasion == occasion;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedOccasion = occasion),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? OlfatoTokens.plum : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(OlfatoTokens.radiusControl - 4),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: OlfatoTokens.plum.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      occasion.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color:
                            isSelected ? Colors.white : OlfatoTokens.ink,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Description Input ───────────────────────────────────────────────────

  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descreva o que busca',
          style: GoogleFonts.ebGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: OlfatoTokens.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _selectedOccasion == SelectionOccasion.presente
              ? 'Descreva para quem é o presente e suas preferências.'
              : 'Descreva o contexto, suas preferências ou o que espera.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: OlfatoTokens.gray,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLength: _maxDescriptionLength,
          maxLines: 4,
          minLines: 3,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: OlfatoTokens.ink,
          ),
          decoration: InputDecoration(
            hintText: _selectedOccasion == SelectionOccasion.presente
                ? 'Ex: Presente para minha mãe, ela gosta de perfumes florais suaves...'
                : 'Ex: Preciso de algo discreto e profissional para reuniões...',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: OlfatoTokens.gray.withValues(alpha: 0.7),
            ),
            filled: true,
            fillColor: OlfatoTokens.mist,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
              borderSide: BorderSide(color: OlfatoTokens.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
              borderSide: const BorderSide(color: OlfatoTokens.plum, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
              borderSide: const BorderSide(color: OlfatoTokens.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
              borderSide: const BorderSide(color: OlfatoTokens.error, width: 1.5),
            ),
            errorText: _validationError,
            errorStyle: GoogleFonts.inter(
              fontSize: 12,
              color: OlfatoTokens.error,
            ),
            contentPadding: const EdgeInsets.all(16),
            counterStyle: GoogleFonts.inter(
              fontSize: 11,
              color: OlfatoTokens.gray,
            ),
          ),
          onChanged: (_) {
            // Clear validation error when user types
            if (_validationError != null) {
              setState(() => _validationError = null);
            }
          },
        ),
      ],
    );
  }

  // ─── Budget Dropdown ─────────────────────────────────────────────────────

  Widget _buildBudgetDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Faixa de investimento (opcional)',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: OlfatoTokens.ink,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: OlfatoTokens.mist,
            borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
            border: Border.all(color: OlfatoTokens.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BudgetQualifier>(
              value: _selectedBudget,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: OlfatoTokens.gray),
              dropdownColor: OlfatoTokens.vanilla,
              borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: OlfatoTokens.ink,
              ),
              items: BudgetQualifier.values.map((budget) {
                return DropdownMenuItem(
                  value: budget,
                  child: Text(
                    budget.label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: OlfatoTokens.ink,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedBudget = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─── Generate Button ─────────────────────────────────────────────────────

  Widget _buildGenerateButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _generateSelection,
        style: ElevatedButton.styleFrom(
          backgroundColor: OlfatoTokens.pitanga,
          foregroundColor: Colors.white,
          disabledBackgroundColor: OlfatoTokens.pitanga.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 18),
            const SizedBox(width: 8),
            Text(
              'Gerar Seleção com Aura',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Loading State ───────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: OlfatoTokens.auraGradient,
              ),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aura está criando sua seleção...',
              style: GoogleFonts.ebGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: OlfatoTokens.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analisando perfumes para ${_selectedOccasion.label.toLowerCase()}',
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

  // ─── Error State ─────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OlfatoTokens.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
        border: Border.all(
          color: OlfatoTokens.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 32,
            color: OlfatoTokens.error.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Não foi possível gerar a seleção.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: OlfatoTokens.error,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _generateSelection,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(
              'Tentar novamente',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: OlfatoTokens.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(OlfatoTokens.radiusControl),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Results Section ─────────────────────────────────────────────────────

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: OlfatoTokens.plum),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedOccasion == SelectionOccasion.presente
                    ? 'Seleção para Presente'
                    : 'Sua Seleção — ${_selectedOccasion.label}',
                style: GoogleFonts.ebGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: OlfatoTokens.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Perfume cards
        ...List.generate(_results.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPerfumeCard(_results[index], index + 1),
          );
        }),

        const SizedBox(height: 16),

        // Share button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _shareResults,
            icon: const Icon(Icons.share_outlined, size: 18),
            label: Text(
              'Compartilhar seleção',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: OlfatoTokens.plum,
              side: const BorderSide(color: OlfatoTokens.plum),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(OlfatoTokens.radiusControl),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Perfume Card ────────────────────────────────────────────────────────

  Widget _buildPerfumeCard(_PerfumeRecommendation perfume, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OlfatoTokens.mist,
        borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
        border: Border.all(color: OlfatoTokens.borderLight),
        boxShadow: [OlfatoTokens.cardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: OlfatoTokens.auraGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$index',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Perfume info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  perfume.name,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: OlfatoTokens.ink,
                  ),
                ),
                const SizedBox(height: 2),
                // Brand + Volume
                Row(
                  children: [
                    Text(
                      perfume.brand,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: OlfatoTokens.plum,
                      ),
                    ),
                    if (perfume.volume.isNotEmpty) ...[
                      Text(
                        ' · ',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: OlfatoTokens.gray,
                        ),
                      ),
                      Text(
                        perfume.volume,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: OlfatoTokens.gray,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // Justification
                Text(
                  perfume.justification,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: OlfatoTokens.gray,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
