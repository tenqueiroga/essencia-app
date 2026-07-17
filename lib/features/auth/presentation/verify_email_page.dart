import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/olfato_tokens.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Digite o código de 6 dígitos.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      await ApiClient().dio.post('/auth/verify-email', data: {'code': code});
      if (mounted) {
        // Update auth state
        final user = ref.read(authProvider).user;
        if (user != null) {
          final updated = Map<String, dynamic>.from(user);
          updated['email_verified'] = true;
          ref.read(authProvider.notifier).updateUser(updated);
        }
        context.go('/onboarding');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Código inválido ou expirado. Tente novamente.';
      });
    }
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _error = null; });
    try {
      await ApiClient().dio.post('/auth/resend-verification');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Código reenviado! Verifique seu email.'),
          backgroundColor: OlfatoTokens.plum,
        ));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Erro ao reenviar. Aguarde um momento.');
      }
    }
    if (mounted) setState(() => _resending = false);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final email = user?['email'] ?? '';

    return Scaffold(
      backgroundColor: OlfatoTokens.vanilla,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mark_email_unread_outlined, size: 64, color: OlfatoTokens.plum),
              const SizedBox(height: 24),
              Text(
                'Verifique seu email',
                style: GoogleFonts.ebGaramond(fontSize: 28, fontWeight: FontWeight.w700, color: OlfatoTokens.ink),
              ),
              const SizedBox(height: 12),
              Text(
                'Enviamos um código de 6 dígitos para:',
                style: GoogleFonts.inter(fontSize: 14, color: OlfatoTokens.gray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: OlfatoTokens.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 8, color: OlfatoTokens.ink),
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 8, color: OlfatoTokens.gray.withValues(alpha: 0.3)),
                  counterText: '',
                  filled: true,
                  fillColor: OlfatoTokens.mist,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: OlfatoTokens.plum, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: OlfatoTokens.error)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OlfatoTokens.plum,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Verificar', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _resending ? null : _resend,
                child: Text(
                  _resending ? 'Reenviando...' : 'Reenviar código',
                  style: GoogleFonts.inter(fontSize: 13, color: OlfatoTokens.plum, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
