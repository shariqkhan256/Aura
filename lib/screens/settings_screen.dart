import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/theme_service.dart';
import 'info_screens.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeService themeService;

  const SettingsScreen({
    super.key, 
    required this.themeService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform().timeout(
        const Duration(seconds: 3),
      );
      if (mounted) {
        setState(() {
          // versionName (version) + versionCode (buildNumber)
          _version = "${packageInfo.version} (${packageInfo.buildNumber})";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _version = "1.0.0"; 
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(context, "Appearance"),
          AnimatedBuilder(
            animation: widget.themeService,
            builder: (context, _) {
              return _buildSwitchTile(
                context,
                icon: widget.themeService.isDarkMode 
                    ? Icons.dark_mode_rounded 
                    : Icons.light_mode_rounded,
                title: "Dark Mode",
                subtitle: widget.themeService.isDarkMode ? "On" : "Off",
                value: widget.themeService.isDarkMode,
                onChanged: (_) => widget.themeService.toggleTheme(),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, "App Information"),
          _buildSettingTile(
            context,
            icon: Icons.info_outline_rounded,
            title: "Version",
            subtitle: _version,
            onTap: null,
          ),
          _buildSettingTile(
            context,
            icon: Icons.code_rounded,
            title: "Developer Information",
            subtitle: "View technical details",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeveloperInfoScreen()),
              );
            },
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader(context, "Legal"),
          _buildSettingTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            subtitle: "How we protect your data",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          _buildSettingTile(
            context,
            icon: Icons.gavel_rounded,
            title: "Terms of Service",
            subtitle: "Usage guidelines",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.secondary.withOpacity(0.8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.secondary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: theme.disabledColor, fontSize: 13),
        ),
        trailing: onTap != null 
          ? Icon(Icons.chevron_right_rounded, color: theme.disabledColor)
          : null,
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.secondary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: theme.disabledColor, fontSize: 13),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
