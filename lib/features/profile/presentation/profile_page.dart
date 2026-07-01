import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/glass_card.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  List<dynamic>? _badges;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final responses = await Future.wait([
        ApiClient().dio.get('/badges'),
        ApiClient().dio.get('/collection/stats'),
      ]);
      if (mounted) setState(() {
        _badges = responses[0].data as List<dynamic>;
        _stats = responses[1].data as Map<String, dynamic>;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.gold,
                child: Text(
                  (user?['name'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 32, color: AppColors.background),
                ),
              ),
              const SizedBox(height: 12),
              Text(user?['name'] ?? 'Usuário',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text(user?['email'] ?? '', style: const TextStyle(color: AppColors.textSecondary)),
              if (user?['is_admin'] == true)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Text('ADMIN', style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 20),

              // Stats
              Row(children: [
                Expanded(child: _StatCard(label: 'Perfumes', value: '${_stats?['total'] ?? 0}')),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(label: 'Avaliados', value: '${_stats?['rated'] ?? 0}')),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(label: 'Nota Média', value: '${_stats?['average_rating'] ?? '-'}')),
              ]),
              const SizedBox(height: 20),

              // Badges section
              if (_badges != null && _badges!.isNotEmpty) ...[
                Row(children: [
                  const Text('Badges', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showAllBadges(),
                    child: const Text('Ver Todos', style: TextStyle(color: AppColors.gold, fontSize: 12)),
                  ),
                ]),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _badges!.take(6).length,
                    itemBuilder: (_, i) {
                      final b = _badges![i];
                      final unlocked = b['unlocked'] == true;
                      return Container(
                        width: 64,
                        margin: const EdgeInsets.only(right: 8),
                        child: Column(children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: unlocked ? AppColors.gold.withValues(alpha: 0.15) : AppColors.surfaceLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: unlocked ? AppColors.gold : AppColors.glassBorder)),
                            child: Icon(Icons.emoji_events,
                              color: unlocked ? AppColors.gold : AppColors.textMuted, size: 22),
                          ),
                          const SizedBox(height: 4),
                          Text(b['name'] ?? '', style: TextStyle(fontSize: 9,
                            color: unlocked ? AppColors.textPrimary : AppColors.textMuted),
                            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Settings
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  _SettingsTile(icon: Icons.book_outlined, title: 'Diário Olfativo', onTap: () => context.go('/journal')),
                  const Divider(color: AppColors.glassBorder, height: 1),
                  _SettingsTile(icon: Icons.download_outlined, title: 'Exportar Meus Dados', onTap: _exportData),
                  const Divider(color: AppColors.glassBorder, height: 1),
                  _SettingsTile(icon: Icons.delete_forever_outlined, title: 'Excluir Conta', titleColor: AppColors.error, onTap: _deleteAccount),
                  const Divider(color: AppColors.glassBorder, height: 1),
                  _SettingsTile(icon: Icons.logout, title: 'Sair', onTap: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  }),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportData() async {
    try {
      final response = await ApiClient().dio.get('/user/export');
      if (mounted) {
        showDialog(context: context, builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Dados Exportados'),
          content: SizedBox(
            width: double.maxFinite, height: 300,
            child: SingleChildScrollView(child: SelectableText(
              response.data.toString(),
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))],
        ));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao exportar dados'), backgroundColor: AppColors.error));
    }
  }

  void _deleteAccount() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Excluir Conta?'),
      content: const Text('Seus dados serão removidos em até 30 dias. Esta ação não pode ser desfeita.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await ApiClient().dio.delete('/user/account');
              ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/login');
            } catch (_) {}
          },
          child: const Text('Excluir', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ));
  }

  void _showAllBadges() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.9, expand: false,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Center(child: Text('Todas as Conquistas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            const SizedBox(height: 16),
            ...(_badges ?? []).map<Widget>((b) {
              final unlocked = b['unlocked'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: unlocked ? AppColors.gold.withValues(alpha: 0.15) : AppColors.surfaceLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: unlocked ? AppColors.gold : AppColors.glassBorder)),
                      child: Icon(Icons.emoji_events, color: unlocked ? AppColors.gold : AppColors.textMuted, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold,
                          color: unlocked ? AppColors.textPrimary : AppColors.textMuted)),
                        Text(b['description'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    )),
                    if (unlocked) const Icon(Icons.check_circle, color: AppColors.gold, size: 20)
                    else const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 18),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(children: [
        Text(value, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ]),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? titleColor;
  final VoidCallback? onTap;
  const _SettingsTile({required this.icon, required this.title, this.titleColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppColors.textSecondary),
      title: Text(title, style: TextStyle(color: titleColor)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
      onTap: onTap,
    );
  }
}
