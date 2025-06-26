import 'package:faso_services/models/utilisateur.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../configs/themes.dart';
import '../../viewmodels/authentification_viewmodel.dart';

class ParametresView extends StatefulWidget {
  const ParametresView({super.key});

  @override
  State<ParametresView> createState() => _ParametresViewState();
}

class _ParametresViewState extends State<ParametresView> {
  bool _notificationsActivees = true;
  bool _localisationActivee = true;
  bool _themeNuit = false;
  String _versionApp = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chargerVersionApp();
  }

  Future<void> _chargerVersionApp() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _versionApp = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _deconnexion() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final authViewModel = Provider.of<AuthentificationViewModel>(
        context,
        listen: false,
      );
      await authViewModel.deconnexion();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/connexion');
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _partagerApplication() async {
    final result = await SharePlus.instance.share(
      ShareParams(
        text:
            'Découvrez FasoServices, l\'application qui vous met en relation avec des prestataires de services de qualité au Burkina Faso! Téléchargez-la ici: [lien_vers_app]',
        subject: 'FasoServices - Services à domicile au Burkina Faso',
      ),
    );

    // Optionnel: gérer le résultat
    if (result.status == ShareResultStatus.success) {
      debugPrint('Partage effectué avec succès');
    } else if (result.status == ShareResultStatus.dismissed) {
      debugPrint('Partage annulé par l\'utilisateur');
    }
  }

  Future<void> _contacterSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@fasoservices.bf',
      query: 'subject=Demande d\'assistance - FasoServices',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        _showContactDialog();
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Couleurs.erreur,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showComingSoonSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text('Bientôt disponible'),
          ],
        ),
        backgroundColor: Couleurs.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Couleurs.blanc,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.support_agent, color: Couleurs.primaire, size: 24),
            const SizedBox(width: 12),
            Text(
              'Contacter le support',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ],
        ),
        content: Text(
          'Contactez-nous à:\nsupport@fasoservices.bf',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserProfileCard(),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Général',
              icon: Icons.settings,
              children: [
                _buildSwitchItem(
                  title: 'Mode sombre',
                  subtitle: 'Interface en thème sombre',
                  value: _themeNuit,
                  onChanged: (value) {
                    setState(() => _themeNuit = value);
                    _showComingSoonSnackBar();
                  },
                  icon: Icons.dark_mode,
                ),
                _buildListItem(
                  title: 'Langue',
                  subtitle: 'Français',
                  icon: Icons.language,
                  onTap: _showComingSoonSnackBar,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Notifications',
              icon: Icons.notifications,
              children: [
                _buildSwitchItem(
                  title: 'Notifications push',
                  subtitle: 'Alertes pour vos réservations',
                  value: _notificationsActivees,
                  onChanged: (value) =>
                      setState(() => _notificationsActivees = value),
                  icon: Icons.notifications_active,
                ),
                _buildSwitchItem(
                  title: 'Notifications email',
                  subtitle: 'Recevoir des emails',
                  value: false,
                  onChanged: (value) => _showComingSoonSnackBar(),
                  icon: Icons.email,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Confidentialité',
              icon: Icons.security,
              children: [
                _buildSwitchItem(
                  title: 'Localisation',
                  subtitle: 'Services à proximité',
                  value: _localisationActivee,
                  onChanged: (value) =>
                      setState(() => _localisationActivee = value),
                  icon: Icons.location_on,
                ),
                _buildListItem(
                  title: 'Politique de confidentialité',
                  icon: Icons.privacy_tip,
                  onTap: _showComingSoonSnackBar,
                ),
                _buildListItem(
                  title: 'Conditions d\'utilisation',
                  icon: Icons.description,
                  onTap: _showComingSoonSnackBar,
                ),
                _buildListItem(
                  title: 'Changer le mot de passe',
                  icon: Icons.lock,
                  onTap: _showComingSoonSnackBar,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'À propos',
              icon: Icons.info,
              children: [
                _buildListItem(
                  title: 'Partager l\'application',
                  icon: Icons.share,
                  onTap: _partagerApplication,
                ),
                _buildListItem(
                  title: 'Noter l\'application',
                  icon: Icons.star,
                  onTap: _showComingSoonSnackBar,
                ),
                _buildListItem(
                  title: 'Contacter le support',
                  icon: Icons.support_agent,
                  onTap: _contacterSupport,
                ),
                Consumer<AuthentificationViewModel>(
                  builder: (context, authViewModel, _) {
                    final utilisateur = authViewModel.utilisateur;
                    if (utilisateur?.type == TypeUtilisateur.client) {
                      return _buildListItem(
                        title: 'Devenir prestataire',
                        icon: Icons.business,
                        onTap: _showComingSoonSnackBar,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                _buildVersionItem(),
              ],
            ),
            const SizedBox(height: 24),
            _buildLogoutButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileCard() {
    return Consumer<AuthentificationViewModel>(
      builder: (context, authViewModel, _) {
        final utilisateur = authViewModel.utilisateur;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Couleurs.primaire.withAlpha(
                      26,
                    ), // 0.1 * 255 = 25.5 ≈ 26
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Icon(Icons.person, color: Couleurs.primaire, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        utilisateur?.nom ?? 'Utilisateur',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Couleurs.primaire.withAlpha(26), // 0.1 * 255
                          borderRadius: BorderRadius.circular(8),
                        ),

                        child: Text(
                          utilisateur?.type == TypeUtilisateur.prestataire
                              ? 'Prestataire'
                              : 'Client',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Couleurs.primaire,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pushNamed('/profil'),
                  icon: Icon(
                    Icons.edit,
                    color: Couleurs.texteSecondaire,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Couleurs.primaire.withAlpha(26),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Couleurs.primaire, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Couleurs.primaire,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Couleurs.primaire.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Couleurs.primaire, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Couleurs.primaire,
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required String title,
    String? subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Couleurs.primaire.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Couleurs.primaire, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Couleurs.texteSecondaire,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.info, color: Colors.grey, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Version $_versionApp',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _deconnexion,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 8),
                  Text('Se déconnecter'),
                ],
              ),
      ),
    );
  }
}
