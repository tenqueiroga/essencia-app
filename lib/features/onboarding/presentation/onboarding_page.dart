import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/olfato_tokens.dart';
import '../../../core/providers/auth_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingData(
      icon: Icons.local_florist,
      title: 'Sua Coleção',
      subtitle: 'Cadastre seus perfumes, organize por ocasião e estação. Crie sua lista de desejos.',
    ),
    _OnboardingData(
      icon: Icons.auto_awesome,
      title: 'Aura',
      subtitle: 'Sua especialista pessoal em perfumes. Pergunte qual usar — ela conhece sua coleção, o clima, e sugere alternativas.',
    ),
    _OnboardingData(
      icon: Icons.camera_alt,
      title: 'Identificação por Foto',
      subtitle: 'Tire uma foto do frasco ou caixa e nossa IA identifica o perfume na hora.',
    ),
    _OnboardingData(
      icon: Icons.content_copy,
      title: 'Dupes & Preços',
      subtitle: 'Descubra clones mais baratos dos seus perfumes favoritos e compare preços de várias lojas.',
    ),
    _OnboardingData(
      icon: Icons.compare_arrows,
      title: 'Similares & Descoberta',
      subtitle: 'Encontre perfumes com perfil aromático parecido. Explore novas fragrâncias todo dia.',
    ),
  ];

  void _complete() {
    ref.read(authProvider.notifier).updateProfile({'onboarding_completed': true});
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _complete,
                child: const Text('Pular', style: TextStyle(color: OlfatoTokens.gray)),
              ),
            ),
            // Brand tagline
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text('Seu gosto, traduzido em perfume.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: OlfatoTokens.gray)),
            ),
            const SizedBox(height: 8),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => Container(
                width: _currentPage == i ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _currentPage == i ? OlfatoTokens.plum : OlfatoTokens.mist,
                  borderRadius: BorderRadius.circular(4)),
              )),
            ),
            const SizedBox(height: 24),
            // Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _currentPage == _pages.length - 1
                    ? _complete
                    : () => _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  child: Text(_currentPage == _pages.length - 1 ? 'Começar!' : 'Próximo'),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, size: 80, color: OlfatoTokens.plum),
          const SizedBox(height: 32),
          Text(data.title, style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(data.subtitle, style: const TextStyle(color: OlfatoTokens.gray, fontSize: 16, height: 1.5),
            textAlign: TextAlign.center),
        ],
      ),
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OnboardingData({required this.icon, required this.title, required this.subtitle});
}
