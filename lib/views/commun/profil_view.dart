// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../configs/themes.dart';
import '../../configs/constants.dart';
import '../../models/utilisateur.dart';
import '../../models/prestataire.dart';
import '../../viewmodels/profil_viewmodel.dart';
import '../../viewmodels/authentification_viewmodel.dart';

class ProfilView extends StatefulWidget {
  const ProfilView({super.key});

  @override
  State<ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends State<ProfilView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _telephoneController;
  late TextEditingController _adresseController;
  late TextEditingController _descriptionController;

  bool _isLoading = false;
  bool _isEditing = false;
  File? _imageFile;
  // Supprimé _scrollOffset car il n'était pas utilisé

  // Animations
  late AnimationController _menuAnimationController;
  late AnimationController _headerAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _itemsAnimationController;

  late Animation<double> _headerAnimation;
  late Animation<double> _fabAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _setupScrollListener();
    _loadUserData();
  }

  void _initializeControllers() {
    _nomController = TextEditingController();
    _prenomController = TextEditingController();
    _emailController = TextEditingController();
    _telephoneController = TextEditingController();
    _adresseController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  void _initializeAnimations() {
    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _itemsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _itemsAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Démarrer les animations
    _headerAnimationController.forward();
    _fabAnimationController.forward();
    _itemsAnimationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Si vous avez besoin d'utiliser l'offset du scroll plus tard,
      // vous pouvez le garder ici. Sinon, supprimez cette méthode complètement
      // et son appel dans initState()
    });
  }

  void _loadUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final utilisateur = Provider.of<AuthentificationViewModel>(
        context,
        listen: false,
      ).utilisateur;

      if (utilisateur != null) {
        _nomController.text = utilisateur.nom;
        _prenomController.text = utilisateur.prenom;
        _emailController.text = utilisateur.email;
        _telephoneController.text = utilisateur.telephone;

        if (utilisateur is Prestataire) {
          _adresseController.text = utilisateur.adresse;
          _descriptionController.text = utilisateur.description;
        }
      }
    });
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    _menuAnimationController.dispose();
    _headerAnimationController.dispose();
    _fabAnimationController.dispose();
    _itemsAnimationController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });

    if (_isEditing) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  Future<void> _pickImage() async {
    // Supprimé la variable locale 'picker' inutilisée
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildImagePickerBottomSheet(),
    );
  }

  Widget _buildImagePickerBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Changer la photo de profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildImageSourceButton(
                      icon: Icons.camera_alt,
                      title: 'Caméra',
                      onTap: () => _selectImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImageSourceButton(
                      icon: Icons.photo_library,
                      title: 'Galerie',
                      onTap: () => _selectImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Couleurs.primaire),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    Navigator.pop(context);

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _sauvegarderProfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final profilViewModel = Provider.of<ProfilViewModel>(
        context,
        listen: false,
      );
      final authViewModel = Provider.of<AuthentificationViewModel>(
        context,
        listen: false,
      );
      final utilisateur = authViewModel.utilisateur;

      if (utilisateur == null) {
        throw Exception("Utilisateur non connecté");
      }

      String? photoProfilUrl;

      if (_imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('photos_profil')
            .child('${utilisateur.id}.jpg');

        await ref.putFile(_imageFile!);
        photoProfilUrl = await ref.getDownloadURL();
      }

      if (utilisateur.type == TypeUtilisateur.prestataire) {
        await profilViewModel.mettreAJourProfilPrestataire(
          nom: _nomController.text,
          prenom: _prenomController.text,
          telephone: _telephoneController.text,
          adresse: _adresseController.text,
          description: _descriptionController.text,
          photoProfil: photoProfilUrl,
        );
      } else {
        await profilViewModel.mettreAJourProfilClient(
          nom: _nomController.text,
          prenom: _prenomController.text,
          telephone: _telephoneController.text,
          photoProfil: photoProfilUrl,
        );
      }

      _showSuccessSnackBar();
      _toggleEditMode();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Profil mis à jour avec succès'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Erreur: $message')),
          ],
        ),
        backgroundColor: Couleurs.erreur,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final authViewModel = Provider.of<AuthentificationViewModel>(
                  context,
                  listen: false,
                );
                await authViewModel.deconnexion();
                if (!mounted) return;
                Navigator.of(context).pushReplacementNamed('/connexion');
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Couleurs.erreur),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer<AuthentificationViewModel>(
        builder: (context, authViewModel, _) {
          final utilisateur = authViewModel.utilisateur;

          if (utilisateur == null) {
            return const Center(
              child: Text(
                'Veuillez vous connecter pour accéder à votre profil',
              ),
            );
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(utilisateur),
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildBody(utilisateur),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSliverAppBar(Utilisateur utilisateur) {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false, // 👈 Ajoutez cette ligne
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedBuilder(
          animation: _headerAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Couleurs.primaire.withAlpha((255 * 0.9).toInt()),
                    Couleurs.primaire.withAlpha((255 * 0.7).toInt()),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Effet de particules en arrière-plan
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ParticlesPainter(animation: _headerAnimation),
                    ),
                  ),
                  // Contenu principal
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          _buildAnimatedAvatar(utilisateur),
                          const SizedBox(height: 16),
                          _buildUserInfo(utilisateur),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((255 * 0.2).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.more_vert, color: Colors.white),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 12),
                  Text('Paramètres'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'help',
              child: Row(
                children: [Icon(Icons.help), SizedBox(width: 12), Text('Aide')],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Déconnexion', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'settings':
                Navigator.pushNamed(context, '/parametres');
                break;
              case 'help':
                // Navigation vers l'aide
                break;
              case 'logout':
                _showLogoutDialog();
                break;
            }
          },
        ),
      ],
    );
  }

  Widget _buildAnimatedAvatar(Utilisateur utilisateur) {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.7 + (_headerAnimation.value * 0.3),
          child: GestureDetector(
            onTap: _isEditing ? _pickImage : null,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withAlpha(
                          (255 * 0.3).toInt(),
                        ), // ≈ alpha 77
                        Colors.white.withAlpha(
                          (255 * 0.1).toInt(),
                        ), // ≈ alpha 25
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 46,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (utilisateur.photoProfil != null
                                    ? NetworkImage(utilisateur.photoProfil!)
                                    : AssetImage(
                                        utilisateur is Prestataire
                                            ? Constants
                                                  .imageProfilPrestaireDefaut
                                            : Constants.imageProfilDefaut,
                                      ))
                                as ImageProvider,
                    ),
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Couleurs.primaire,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfo(Utilisateur utilisateur) {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _headerAnimation.value,
          child: Column(
            children: [
              Text(
                utilisateur.nomComplet,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(
                    (255 * 0.2).toInt(),
                  ), // équiv. à opacity 0.2
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withAlpha((255 * 0.3).toInt()),
                  ), // équiv. à opacity 0.3
                ),
                child: Text(
                  utilisateur.type == TypeUtilisateur.client
                      ? 'Client'
                      : 'Prestataire',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(Utilisateur utilisateur) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Informations personnelles'),
              const SizedBox(height: 20),
              _buildPersonalInfoFields(),

              if (utilisateur is Prestataire) ...[
                const SizedBox(height: 32),
                _buildSectionTitle('Informations professionnelles'),
                const SizedBox(height: 20),
                _buildProfessionalInfoFields(utilisateur),
              ],

              const SizedBox(height: 40),
              if (_isEditing) _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPersonalInfoFields() {
    return Column(
      children: [
        _buildModernTextField(
          controller: _nomController,
          label: 'Nom',
          icon: Icons.person,
          enabled: _isEditing,
          validator: (value) =>
              value?.isEmpty == true ? 'Veuillez entrer votre nom' : null,
        ),
        const SizedBox(height: 20),
        _buildModernTextField(
          controller: _prenomController,
          label: 'Prénom',
          icon: Icons.person_outline,
          enabled: _isEditing,
          validator: (value) =>
              value?.isEmpty == true ? 'Veuillez entrer votre prénom' : null,
        ),
        const SizedBox(height: 20),
        _buildModernTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          enabled: false,
        ),
        const SizedBox(height: 20),
        _buildModernTextField(
          controller: _telephoneController,
          label: 'Téléphone',
          icon: Icons.phone,
          enabled: _isEditing,
          keyboardType: TextInputType.phone,
          validator: (value) =>
              value?.isEmpty == true ? 'Veuillez entrer votre téléphone' : null,
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoFields(Prestataire prestataire) {
    return Column(
      children: [
        _buildModernTextField(
          controller: _adresseController,
          label: 'Adresse',
          icon: Icons.location_on,
          enabled: _isEditing,
          validator: (value) =>
              value?.isEmpty == true ? 'Veuillez entrer votre adresse' : null,
        ),
        const SizedBox(height: 20),
        _buildModernTextField(
          controller: _descriptionController,
          label: 'Description professionnelle',
          icon: Icons.description,
          enabled: _isEditing,
          maxLines: 3,
          validator: (value) =>
              value?.isEmpty == true ? 'Veuillez entrer une description' : null,
        ),
        const SizedBox(height: 20),
        _buildCategoriesSelection(prestataire),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(
          color: enabled ? Colors.black87 : Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: enabled ? Couleurs.primaire : Colors.grey[400],
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Couleurs.primaire, width: 2),
          ),
          labelStyle: TextStyle(
            color: enabled ? Couleurs.primaire : Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSelection(Prestataire prestataire) {
    if (!_isEditing && prestataire.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catégories de services',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Consumer<ProfilViewModel>(
          builder: (context, profilViewModel, _) {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: Constants.categories.map((categorie) {
                final isSelected = prestataire.categories.contains(categorie);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: FilterChip(
                    label: Text(
                      categorie,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Couleurs.primaire,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: _isEditing
                        ? (selected) =>
                              profilViewModel.toggleCategorie(categorie)
                        : null,
                    backgroundColor: Colors.grey[100],
                    selectedColor: Couleurs.primaire,
                    checkmarkColor: Colors.white,
                    elevation: isSelected ? 4 : 0,
                    shadowColor: Couleurs.primaire.withAlpha(
                      76,
                    ), // 0.3 * 255 = 76.5 ≈ 76
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Couleurs.primaire, Couleurs.primaire.withAlpha(204)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Couleurs.primaire.withAlpha(76), // 0.3 * 255 = 76
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _sauvegarderProfil,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Sauvegarder les modifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: _toggleEditMode,
            backgroundColor: _isEditing ? Colors.green : Couleurs.primaire,
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            label: Text(_isEditing ? 'Terminer' : 'Modifier'),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}

// Custom Painter pour l'effet de particules
class ParticlesPainter extends CustomPainter {
  final Animation<double> animation;

  ParticlesPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
          .withAlpha(26) // 0.1 * 255 = 25.5 ≈ 26
      ..style = PaintingStyle.fill;
    // Dessiner des particules animées
    for (int i = 0; i < 20; i++) {
      final x = (i * 37) % size.width;
      final y = (i * 53 + animation.value * 100) % size.height;
      final radius = (2 + (i % 3)) * animation.value;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
