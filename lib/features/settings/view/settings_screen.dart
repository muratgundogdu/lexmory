import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../game/providers/game_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [AppColors.surface, AppColors.background],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // 1. Premium App Bar
            _buildSliverAppBar(),

            // 2. Ayar Grupları
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.s24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppDimens.s24),
                  _buildSectionHeader("TERCİHLER"),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      icon: Icons.volume_up_rounded,
                      title: "Ses Efektleri",
                      trailing: _buildSwitch(true),
                    ),
                    _buildSettingsTile(
                      icon: Icons.music_note_rounded,
                      title: "Müzik",
                      trailing: _buildSwitch(false),
                    ),
                    _buildSettingsTile(
                      icon: Icons.vibration_rounded,
                      title: "Titreşim",
                      trailing: _buildSwitch(true),
                    ),
                  ]),

                  const SizedBox(height: AppDimens.s32),
                  _buildSectionHeader("DESTEK & BİLGİ"),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      icon: Icons.language_rounded,
                      title: "Dil",
                      subtitle: "Türkçe",
                      onTap: () {},
                    ),
                    _buildSettingsTile(
                      icon: Icons.verified_user_rounded,
                      title: "Gizlilik Politikası",
                      onTap: () {},
                    ),
                    _buildSettingsTile(
                      icon: Icons.mail_rounded,
                      title: "Bize Ulaşın",
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: AppDimens.s32),
                  _buildSectionHeader("TEHLİKELİ ALAN"),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      icon: Icons.delete_forever_rounded,
                      title: "Oyunu Sıfırla",
                      titleColor: AppColors.error,
                      onTap: () => _showResetDialog(context, ref),
                    ),
                  ]),

                  const SizedBox(height: 60),
                  _buildVersionInfo(),
                  const SizedBox(height: 120), // Bottom Nav boşluğu
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        background: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                "KONTROL PANELİ",
                style: AppTypography.labelSmall.copyWith(color: AppColors.primary, letterSpacing: 4),
              ),
              const SizedBox(height: 8),
              Text("Ayarlar", style: AppTypography.pageTitle.copyWith(fontSize: 28)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: titleColor ?? AppColors.primary, size: 22),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(color: titleColor ?? AppColors.textPrimary, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppTypography.bodyMedium.copyWith(fontSize: 12))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.border),
    );
  }

  Widget _buildSwitch(bool value) {
    return Switch.adaptive(
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: (v) {},
    );
  }

  Widget _buildVersionInfo() {
    return Column(
      children: [
        Text("LEXMORY", style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text("Versiyon 1.0.4", style: AppTypography.bodyMedium.copyWith(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text("Emin misin?", style: AppTypography.cardTitle),
        content: Text("Tüm ilerlemen ve kütüphanen silinecek. Bu işlem geri alınamaz.", style: AppTypography.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İPTAL", style: TextStyle(color: Colors.white70))),
          TextButton(
              onPressed: () {
                ref.read(gameProvider.notifier).resetGame();
                Navigator.pop(context);
              },
              child: const Text("EVET, SIFIRLA", style: TextStyle(color: AppColors.error))
          ),
        ],
      ),
    );
  }
}