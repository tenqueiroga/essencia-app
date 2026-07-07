import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/olfato_tokens.dart';
import '../../../core/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLogin = true;
  String? _nameForRegister;
  String? _passwordError;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Redirect if authenticated (but not if viewing shared content)
    ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated) {
        final currentPath = GoRouterState.of(context).uri.path;
        if (currentPath.startsWith('/shared/')) return;
        final onboarded = next.user?['onboarding_completed'] == true;
        context.go(onboarded ? '/' : '/onboarding');
      }
    });

    return Scaffold(
      backgroundColor: OlfatoTokens.vanilla,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Olfato brand symbol
                ClipRRect(
                  borderRadius: BorderRadius.circular(64),
                  child: Image.asset(
                    'assets/images/olfato_simbolo.png',
                    width: 130,
                    height: 130,
                    errorBuilder: (_, __, ___) => Container(
                      width: 130,
                      height: 130,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: OlfatoTokens.auraGradient,
                      ),
                      child: const Center(
                        child: Text('O', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Olfato',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: OlfatoTokens.ink,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seu gosto, traduzido em perfume.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: OlfatoTokens.gray,
                        fontStyle: FontStyle.italic,
                      ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: OlfatoTokens.mist,
                    borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
                    border: Border.all(color: OlfatoTokens.borderLight, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      if (authState.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            authState.error!,
                            style: const TextStyle(color: OlfatoTokens.error),
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
                                      color: _isLogin ? OlfatoTokens.plum : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Entrar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _isLogin ? OlfatoTokens.plum : OlfatoTokens.gray,
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
                                      color: !_isLogin ? OlfatoTokens.plum : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Criar Conta',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !_isLogin ? OlfatoTokens.plum : OlfatoTokens.gray,
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
                            prefixIcon: Icon(Icons.person_outline, color: OlfatoTokens.gray),
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
                          prefixIcon: Icon(Icons.email_outlined, color: OlfatoTokens.gray),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Password
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: _isLogin ? 'Senha' : 'Senha (mín. 8, letras e números)',
                          prefixIcon: const Icon(Icons.lock_outline, color: OlfatoTokens.gray),
                        ),
                      ),

                      // Confirm password (only on register)
                      if (!_isLogin) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'Confirmar senha',
                            prefixIcon: Icon(Icons.lock_outline, color: OlfatoTokens.gray),
                          ),
                        ),
                      ],

                      // Password validation error
                      if (_passwordError != null) ...[
                        const SizedBox(height: 8),
                        Text(_passwordError!, style: const TextStyle(color: OlfatoTokens.error, fontSize: 12)),
                      ],

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
                          Expanded(child: Divider(color: OlfatoTokens.borderLight)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('ou', style: TextStyle(color: OlfatoTokens.gray, fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: OlfatoTokens.borderLight)),
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
                            foregroundColor: OlfatoTokens.ink,
                            side: const BorderSide(color: OlfatoTokens.borderLight),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
      if (name.length < 2) {
        setState(() => _passwordError = 'Nome deve ter pelo menos 2 caracteres.');
        return;
      }
      if (password.length < 8) {
        setState(() => _passwordError = 'Senha deve ter pelo menos 8 caracteres.');
        return;
      }
      if (!RegExp(r'[a-zA-Z]').hasMatch(password) || !RegExp(r'[0-9]').hasMatch(password)) {
        setState(() => _passwordError = 'Senha deve conter letras e números.');
        return;
      }
      if (password != _confirmPasswordController.text) {
        setState(() => _passwordError = 'Senhas não conferem.');
        return;
      }
      setState(() => _passwordError = null);
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
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
