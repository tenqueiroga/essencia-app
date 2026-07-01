import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/glass_card.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  String? _nameForRegister;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Redirect if authenticated
    ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated) {
        final onboarded = next.user?['onboarding_completed'] == true;
        context.go(onboarded ? '/' : '/onboarding');
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.background, Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_florist, size: 80, color: AppColors.gold),
                  const SizedBox(height: 16),
                  Text(
                    'Perfume Collection',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seu assistente pessoal de perfumes',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 40),
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (authState.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              authState.error!,
                              style: const TextStyle(color: AppColors.error),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Toggle Login/Register
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLogin = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _isLogin ? AppColors.gold : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Entrar',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _isLogin ? AppColors.gold : AppColors.textMuted,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLogin = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: !_isLogin ? AppColors.gold : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Criar Conta',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: !_isLogin ? AppColors.gold : AppColors.textMuted,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Name field (register only)
                        if (!_isLogin) ...[
                          TextField(
                            onChanged: (v) => _nameForRegister = v,
                            decoration: const InputDecoration(
                              hintText: 'Nome',
                              prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Password
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'Senha',
                            prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _submit,
                            child: authState.isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(_isLogin ? 'Entrar' : 'Criar Conta'),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.glassBorder)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('ou', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ),
                            const Expanded(child: Divider(color: AppColors.glassBorder)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Google button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: authState.isLoading ? null : _signInWithGoogle,
                            icon: const Icon(Icons.g_mobiledata, size: 24),
                            label: const Text('Continuar com Google'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.glassBorder),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Admin hint
                  const SizedBox(height: 24),
                  Text(
                    'Admin: admin@perfumecollection.app / password',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (_isLogin) {
      ref.read(authProvider.notifier).loginWithEmail(email, password);
    } else {
      final name = _nameForRegister?.trim() ?? '';
      if (name.isEmpty) return;
      ref.read(authProvider.notifier).register(name, email, password);
    }
  }

  Future<void> _signInWithGoogle() async {
    // Google Sign-In will be configured later with API keys
    ref.read(authProvider.notifier).loginWithEmail(
      'test@example.com',
      'password',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
