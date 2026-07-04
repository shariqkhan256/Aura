import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class DeveloperInfoScreen extends StatelessWidget {
  const DeveloperInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Developer Information"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.code_rounded,
                  size: 64,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    "Aura",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Powered by BlueX",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoRow(theme, Icons.category_outlined, "Category", "Productivity / Utilities"),
            const SizedBox(height: 24),
            _buildSection(
              theme,
              "Description",
              "Aura is a text-to-audio application that converts written text into natural-sounding speech using on-device artificial intelligence. All text processing is performed locally on the user’s device, ensuring offline functionality, fast performance, and strong privacy protection.",
            ),
            const SizedBox(height: 32),
            _buildSection(
                theme,
                "Contact Information",
                ""
                    " Email: shariqkhan2677@gmail.com\n\nFeel free to reach out for support, feedback, or business inquiries."
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.secondary),
        const SizedBox(width: 12),
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(value),
      ],
    );
  }

  Widget _buildSection(ThemeData theme, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.6,
            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🔐 Privacy Policy",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Last Updated: January 18, 2026",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            const Text(
              "Aura is built with a privacy-first approach and respects user data at all times.",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            _buildPolicySection(
              theme,
              "1. Data Collection",
              "Aura does not collect, store, or share any personal or sensitive user data.",
            ),
            _buildPolicySection(
              theme,
              "2. On-Device AI Processing",
              "All text entered by the user is processed entirely on the device. No text, audio, or data is transmitted to external servers. Generated audio remains on the device unless the user chooses to save or share it.",
            ),
            _buildPolicySection(
              theme,
              "3. Internet Usage",
              "Aura does not require an internet connection for text-to-audio conversion. Internet access may only be used for: App updates and Optional improvements.",
            ),
            _buildPolicySection(
              theme,
              "4. Permissions",
              "Aura may request Storage access to save generated audio files. Permissions are used strictly for core functionality.",
            ),
            _buildPolicySection(
              theme,
              "5. Third-Party Services",
              "Aura does not use third-party analytics, advertisements, or tracking tools.",
            ),
            _buildPolicySection(
              theme,
              "6. Children’s Privacy",
              "Aura does not knowingly collect data from children under the age of 13.",
            ),
            _buildPolicySection(
              theme,
              "7. Policy Updates",
              "Any changes to this Privacy Policy will be updated within the app or app store listing.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection(ThemeData theme, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📜 Terms & Conditions",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Last Updated: January 18, 2026",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            const Text(
              "By using Aura, you agree to the following terms.",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            _buildSection(
              theme,
              "1. App Usage",
              "Aura is intended for personal, educational, and productivity use only. Users must use the app responsibly and legally.",
            ),
            _buildSection(
              theme,
              "2. User Content",
              "Users are solely responsible for the text they input. Aura does not monitor or store user-generated content.",
            ),
            _buildSection(
              theme,
              "3. Intellectual Property",
              "Aura and its features are owned by BlueX. Generated audio content belongs to the user.",
            ),
            _buildSection(
              theme,
              "4. Disclaimer",
              "Aura is provided “as is” without warranties. BlueX is not responsible for misuse of generated audio or any resulting consequences.",
            ),
            _buildSection(
              theme,
              "5. Modifications",
              "BlueX reserves the right to update, modify, or discontinue the app at any time.",
            ),
            _buildSection(
              theme,
              "6. Termination",
              "Access may be limited if these terms are violated.",
            ),
            _buildSection(
              theme,
              "7. Acceptance",
              "By installing or using Aura, you confirm acceptance of these Terms & Conditions.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
