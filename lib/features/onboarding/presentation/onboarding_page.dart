import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/olfato_tokens.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;

  // Quiz answers
  String? _experience; // iniciante, intermediario, avancado
  List<String> _preferredFamilies = [];
  String? _gender; // masculino, feminino, ambos
  String? _occasion; // dia_a_dia, trabalho, noite, especial
  String? _intensity; // leve, moderada, forte
  String? _budget; // ate_100, 100_300, 300_500, acima_500

  static const _totalPages = 8; // 2 intro + 6 quiz

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _complete();
    }
  }

  void _complete() async {
    final profile = {
      'experience': _experience,
      'preferred_families': _preferredFamilies,
      'gender': _gender,
      'occasion': _occasion,
      'intensity': _intensity,
      'budget': _budget,
    };

    try {
      await ApiClient().dio.patch('/user/profile', data: {
        'onboarding_completed': true,
        'taste_profile': profile,
      });
    } catch (_) {}

    ref.read(authProvider.notifier).updateProfile({'onboarding_completed': true});
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OlfatoTokens.vanilla,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: skip + progress
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
              child: Row(
                children: [
                  // Progress
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentPage + 1) / _totalPages,
                        backgroundColor: OlfatoTokens.mist,
                        valueColor: const AlwaysStoppedAnimation(OlfatoTokens.plum),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _complete,
                    child: Text('Pular', style: GoogleFonts.inter(fontSize: 13, color: OlfatoTokens.gray)),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildWelcome(),
                  _buildFeatures(),
                  _buildQuizExperience(),
                  _buildQuizFamilies(),
                  _buildQuizGender(),
                  _buildQuizOccasion(),
                  _buildQuizIntensity(),
                  _buildQuizBudget(),
                ],
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed() ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OlfatoTokens.plum,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: OlfatoTokens.plum.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl)),
                  ),
                  child: Text(
                    _currentPage >= _totalPages - 1 ? 'Começar!' : _currentPage < 2 ? 'Próximo' : 'Continuar',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    if (_currentPage < 2) return true; // intro pages
    if (_currentPage == 2) return _experience != null;
    if (_currentPage == 3) return _preferredFamilies.isNotEmpty;
    if (_currentPage == 4) return _gender != null;
    if (_currentPage == 5) return _occasion != null;
    if (_currentPage == 6) return _intensity != null;
    if (_currentPage == 7) return _budget != null;
    return true;
  }

  // ─── Page 1: Welcome ──────────────────────────────────────────────────────

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/olfato_simbolo.png', width: 72, height: 72,
            errorBuilder: (_, __, ___) => Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: OlfatoTokens.auraGradient),
              child: const Icon(Icons.local_florist, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(height: 24),
          Text('Bem-vindo ao PerfumIA', style: GoogleFonts.ebGaramond(fontSize: 28, fontWeight: FontWeight.w700, color: OlfatoTokens.ink), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('Seu gosto, traduzido em perfume.', style: GoogleFonts.inter(fontSize: 15, color: OlfatoTokens.gray, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Text('Vamos conhecer um pouco do seu perfil olfativo para personalizar sua experiência.', style: GoogleFonts.inter(fontSize: 14, color: OlfatoTokens.ink, height: 1.6), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ─── Page 2: Features overview ────────────────────────────────────────────

  Widget _buildFeatures() {
    final features = [
      ('🧴', 'Coleção', 'Organize perfumes, decants e amostras'),
      ('🤖', 'Aura IA', 'Assistente pessoal que conhece seu gosto'),
      ('📷', 'Scan', 'Identifique perfumes por foto'),
      ('💰', 'Preços', 'Compare preços de 4 lojas brasileiras'),
      ('📊', 'Comparador', 'Compare perfumes lado a lado com IA'),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('O que você pode fazer', style: GoogleFonts.ebGaramond(fontSize: 24, fontWeight: FontWeight.w700, color: OlfatoTokens.ink)),
          const SizedBox(height: 24),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Text(f.$1, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.$2, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: OlfatoTokens.ink)),
                    Text(f.$3, style: GoogleFonts.inter(fontSize: 12, color: OlfatoTokens.gray)),
                  ],
                )),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ─── Quiz Pages ───────────────────────────────────────────────────────────

  Widget _buildQuizExperience() {
    return _quizPage(
      title: 'Qual seu nível com perfumes?',
      subtitle: 'Isso nos ajuda a calibrar as sugestões.',
      options: [
        ('iniciante', '🌱', 'Iniciante', 'Estou começando a explorar'),
        ('intermediario', '🌿', 'Intermediário', 'Tenho alguns perfumes e quero expandir'),
        ('avancado', '🌳', 'Avançado', 'Coleciono e entendo de notas'),
      ],
      selected: _experience,
      onSelect: (v) => setState(() => _experience = v),
    );
  }

  Widget _buildQuizFamilies() {
    final families = [
      ('Floral', '🌸'), ('Amadeirada', '🪵'), ('Oriental', '🕌'),
      ('Cítrica', '🍋'), ('Fresca', '🌊'), ('Gourmand', '🍫'),
      ('Aromática', '🌿'), ('Fougère', '🌾'), ('Aquática', '💧'),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Famílias que te atraem', style: GoogleFonts.ebGaramond(fontSize: 22, fontWeight: FontWeight.w700, color: OlfatoTokens.ink)),
          const SizedBox(height: 8),
          Text('Selecione 1 ou mais (pode mudar depois)', style: GoogleFonts.inter(fontSize: 13, color: OlfatoTokens.gray)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: families.map((f) {
              final isSelected = _preferredFamilies.contains(f.$1);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) { _preferredFamilies.remove(f.$1); }
                  else { _preferredFamilies.add(f.$1); }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? OlfatoTokens.plum : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? OlfatoTokens.plum : OlfatoTokens.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(f.$2, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(f.$1, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : OlfatoTokens.ink)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizGender() {
    return _quizPage(
      title: 'Qual sua preferência?',
      subtitle: 'Em relação a fragrâncias.',
      options: [
        ('masculino', '♂️', 'Masculinas', 'Prefiro fragrâncias masculinas'),
        ('feminino', '♀️', 'Femininas', 'Prefiro fragrâncias femininas'),
        ('ambos', '⚧️', 'Sem preferência', 'Gosto de ambas'),
      ],
      selected: _gender,
      onSelect: (v) => setState(() => _gender = v),
    );
  }

  Widget _buildQuizOccasion() {
    return _quizPage(
      title: 'Quando mais usa perfume?',
      subtitle: 'Principal ocasião de uso.',
      options: [
        ('dia_a_dia', '☀️', 'Dia a dia', 'Trabalho, faculdade, rotina'),
        ('trabalho', '💼', 'Profissional', 'Reuniões e ambiente corporativo'),
        ('noite', '🌙', 'Noite / Saídas', 'Jantares, festas, encontros'),
        ('especial', '✨', 'Ocasiões especiais', 'Eventos, datas importantes'),
      ],
      selected: _occasion,
      onSelect: (v) => setState(() => _occasion = v),
    );
  }

  Widget _buildQuizIntensity() {
    return _quizPage(
      title: 'Intensidade preferida?',
      subtitle: 'Quanto quer que sintam sua fragrância.',
      options: [
        ('leve', '🌬️', 'Leve / Íntima', 'Só quem está bem perto sente'),
        ('moderada', '🌤️', 'Moderada', 'Quem passa perto percebe'),
        ('forte', '🔥', 'Forte / Marcante', 'Deixa rastro por onde passa'),
      ],
      selected: _intensity,
      onSelect: (v) => setState(() => _intensity = v),
    );
  }

  Widget _buildQuizBudget() {
    return _quizPage(
      title: 'Faixa de investimento?',
      subtitle: 'Quanto costuma gastar em perfume.',
      options: [
        ('ate_100', '💚', 'Até R\$100', 'Bom custo-benefício'),
        ('100_300', '💜', 'R\$100 - R\$300', 'Intermediário'),
        ('300_500', '💎', 'R\$300 - R\$500', 'Premium'),
        ('acima_500', '👑', 'Acima de R\$500', 'Luxo / Nicho'),
      ],
      selected: _budget,
      onSelect: (v) => setState(() => _budget = v),
    );
  }

  // ─── Reusable quiz layout ─────────────────────────────────────────────────

  Widget _quizPage({
    required String title,
    required String subtitle,
    required List<(String value, String emoji, String label, String desc)> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.ebGaramond(fontSize: 22, fontWeight: FontWeight.w700, color: OlfatoTokens.ink)),
          const SizedBox(height: 8),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: OlfatoTokens.gray)),
          const SizedBox(height: 28),
          ...options.map((opt) {
            final isSelected = selected == opt.$1;
            return GestureDetector(
              onTap: () => onSelect(opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? OlfatoTokens.plum.withValues(alpha: 0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
                  border: Border.all(
                    color: isSelected ? OlfatoTokens.plum : OlfatoTokens.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(opt.$2, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(opt.$3, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: OlfatoTokens.ink)),
                        Text(opt.$4, style: GoogleFonts.inter(fontSize: 12, color: OlfatoTokens.gray)),
                      ],
                    )),
                    if (isSelected)
                      Icon(Icons.check_circle, color: OlfatoTokens.plum, size: 22),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }
}
