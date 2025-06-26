import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../configs/themes.dart';
import '../../configs/constants.dart';
import '../../models/service.dart';
import '../../viewmodels/prestataire_viewmodel.dart';
import '../../widgets/bouton_principal.dart';

class GestionServicesView extends StatefulWidget {
  const GestionServicesView({super.key});

  @override
  State<GestionServicesView> createState() => _GestionServicesViewState();
}

class _GestionServicesViewState extends State<GestionServicesView>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixController = TextEditingController();
  String _categorieSelectionnee = Constants.categories.first;
  String? _obtenirIdPrestataireConnecte() {
    // Exemple avec FirebaseAuth
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
    // Ou avec votre système d'auth
    // return AuthService.instance.currentUserId;
  }

  List<File> _photosSelectionnees = [];
  Service? _serviceEnModification;
  bool _estEnChargement = false;
  bool _formulaireOuvert = false;
  bool _selectionEnCours = false;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chargerPrestataireConnecte();
    });
  }

  Future<void> _chargerPrestataireConnecte() async {
    String? prestataireId = _obtenirIdPrestataireConnecte();

    if (prestataireId != null) {
      await Provider.of<PrestataireViewModel>(
        context,
        listen: false,
      ).chargerPrestataire(prestataireId);
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _ouvrirFormulaire() {
    setState(() {
      _formulaireOuvert = true;
    });
    _animationController.forward();
  }

  void _fermerFormulaire() {
    _animationController.reverse().then((_) {
      setState(() {
        _formulaireOuvert = false;
      });
    });
  }

  void _reinitialiserFormulaire() {
    _titreController.clear();
    _descriptionController.clear();
    _prixController.clear();
    setState(() {
      _categorieSelectionnee = Constants.categories.first;
      _photosSelectionnees = [];
      _serviceEnModification = null;
    });
    _fermerFormulaire();
  }

  Future<void> _selectionnerPhotos() async {
    if (_selectionEnCours) return;

    setState(() {
      _selectionEnCours = true;
    });

    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(imageQuality: 75);

      if (images.isNotEmpty) {
        setState(() {
          _photosSelectionnees.addAll(images.map((xfile) => File(xfile.path)));
        });
      }
    } catch (e) {
      if (kDebugMode) print('Erreur sélection image: $e');
    } finally {
      setState(() {
        _selectionEnCours = false;
      });
    }
  }

  void _supprimerPhoto(int index) {
    setState(() {
      _photosSelectionnees.removeAt(index);
    });
  }

  void _modifierService(Service service) {
    setState(() {
      _serviceEnModification = service;
      _titreController.text = service.titre;
      _descriptionController.text = service.description;
      _prixController.text = service.prix.toString();
      _categorieSelectionnee = service.categorie;
    });
    _ouvrirFormulaire();
  }

  Future<void> _enregistrerService() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _estEnChargement = true;
      });

      try {
        final viewModel = Provider.of<PrestataireViewModel>(
          context,
          listen: false,
        );

        final titre = _titreController.text.trim();
        final description = _descriptionController.text.trim();
        final prix = double.parse(_prixController.text.trim());

        if (_serviceEnModification == null) {
          await viewModel.ajouterService(
            titre: titre,
            description: description,
            prix: prix,
            categorie: _categorieSelectionnee,
            photosFichiers: _photosSelectionnees,
          );
          _afficherSnackBar('Service ajouté avec succès', Icons.check_circle);
        } else {
          await viewModel.mettreAJourService(
            serviceId: _serviceEnModification!.id,
            titre: titre,
            description: description,
            prix: prix,
            categorie: _categorieSelectionnee,
            photosFichiers: _photosSelectionnees,
          );
          await viewModel.chargerServices(_obtenirIdPrestataireConnecte());
          _afficherSnackBar('Service modifié avec succès', Icons.check_circle);
        }

        _reinitialiserFormulaire();
      } catch (e) {
        _afficherSnackBar(
          'Erreur: ${e.toString()}',
          Icons.error,
          estErreur: true,
        );
      } finally {
        setState(() {
          _estEnChargement = false;
        });
      }
    }
  }

  void _supprimerService(String serviceId) async {
    setState(() {
      _estEnChargement = true;
    });

    try {
      final viewModel = Provider.of<PrestataireViewModel>(
        context,
        listen: false,
      );
      await viewModel.supprimerService(serviceId);
      _afficherSnackBar('Service supprimé avec succès', Icons.delete_forever);
    } catch (e) {
      _afficherSnackBar(
        'Erreur: ${e.toString()}',
        Icons.error,
        estErreur: true,
      );
    } finally {
      setState(() {
        _estEnChargement = false;
      });
    }
  }

  void _afficherSnackBar(
    String message,
    IconData icon, {
    bool estErreur = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: estErreur ? Couleurs.erreur : Couleurs.succes,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _afficherDialogueConfirmation(String serviceId, String titre) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Couleurs.erreur.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning, color: Couleurs.erreur),
            ),
            const SizedBox(width: 12),
            const Text('Confirmation'),
          ],
        ),
        content: Text('Voulez-vous vraiment supprimer le service "$titre" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _supprimerService(serviceId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Couleurs.erreur,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaire() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Couleurs.primaire.withOpacity(0.05), Colors.white],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Couleurs.primaire.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _serviceEnModification == null
                                  ? Icons.add
                                  : Icons.edit,
                              color: Couleurs.primaire,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _serviceEnModification == null
                                ? 'Nouveau service'
                                : 'Modifier le service',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Couleurs.primaire,
                                ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _reinitialiserFormulaire,
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _titreController,
                        label: 'Titre du service',
                        icon: Icons.work_outline,
                        validator: (value) => value?.isEmpty == true
                            ? 'Veuillez entrer un titre'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description du service',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                        validator: (value) => value?.isEmpty == true
                            ? 'Veuillez entrer une description'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _prixController,
                        label: 'Prix (FCFA)',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty == true) {
                            return 'Veuillez entrer un prix';
                          }
                          try {
                            double.parse(value!);
                          } catch (e) {
                            return 'Veuillez entrer un prix valide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(),
                      const SizedBox(height: 24),
                      _buildSectionPhotos(),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: BoutonPrincipal(
                          onPressed: _estEnChargement
                              ? null
                              : _enregistrerService,
                          texte: _serviceEnModification == null
                              ? 'Ajouter le service'
                              : 'Enregistrer les modifications',
                          estChargement: _estEnChargement,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Couleurs.primaire),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Couleurs.primaire, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Catégorie',
          prefixIcon: const Icon(Icons.category, color: Couleurs.primaire),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        value: _categorieSelectionnee,
        items: Constants.categories.map((categorie) {
          return DropdownMenuItem<String>(
            value: categorie,
            child: Text(categorie),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _categorieSelectionnee = newValue!;
          });
        },
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildSectionPhotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library, color: Couleurs.primaire),
            const SizedBox(width: 8),
            Text(
              'Photos du service',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Couleurs.primaire,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_serviceEnModification?.photos.isNotEmpty == true) ...[
          _buildPhotosExistantes(),
          const SizedBox(height: 16),
        ],
        if (_photosSelectionnees.isNotEmpty) ...[
          _buildNouvellesPhotos(),
          const SizedBox(height: 16),
        ],
        _buildBoutonAjouterPhotos(),
      ],
    );
  }

  Widget _buildPhotosExistantes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos existantes',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _serviceEnModification!.photos.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _serviceEnModification!.photos[index],
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[200],
                        child: const Icon(Icons.error, color: Colors.grey),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNouvellesPhotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nouvelles photos',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _photosSelectionnees.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _photosSelectionnees[index],
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _supprimerPhoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Couleurs.erreur,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBoutonAjouterPhotos() {
    return InkWell(
      onTap: _selectionnerPhotos,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Couleurs.primaire.withOpacity(0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          color: Couleurs.primaire.withOpacity(0.05),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: Couleurs.primaire),
            SizedBox(width: 12),
            Text(
              'Ajouter des photos',
              style: TextStyle(
                color: Couleurs.primaire,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.titre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Couleurs.primaire.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${service.prix.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            color: Couleurs.primaire,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          service.categorie,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Switch(
                      value: service.estDisponible,
                      onChanged: (value) {
                        Provider.of<PrestataireViewModel>(
                          context,
                          listen: false,
                        ).modifierDisponibiliteService(service.id, value);
                      },
                      activeColor: Couleurs.primaire,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Couleurs.secondaire.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Couleurs.secondaire,
                              size: 20,
                            ),
                          ),
                          onPressed: () => _modifierService(service),
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Couleurs.erreur.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Couleurs.erreur,
                              size: 20,
                            ),
                          ),
                          onPressed: () => _afficherDialogueConfirmation(
                            service.id,
                            service.titre,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (service.photos.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: service.photos.length,
                  itemBuilder: (context, photoIndex) {
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          service.photos[photoIndex],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.error,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _formulaireOuvert
          ? null
          : AppBar(
              backgroundColor: Colors.grey[50],
              elevation: 0,
              scrolledUnderElevation: 0,
              actions: [
                if (!_formulaireOuvert)
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: ElevatedButton.icon(
                      onPressed: _ouvrirFormulaire,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Nouveau'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Couleurs.primaire,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          String? prestataireId = _obtenirIdPrestataireConnecte();
          if (prestataireId != null) {
            await Provider.of<PrestataireViewModel>(
              context,
              listen: false,
            ).chargerServices(prestataireId);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (_formulaireOuvert) _buildFormulaire(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_formulaireOuvert) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.business_center,
                            color: Couleurs.primaire,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Mes services',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Couleurs.primaire,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                    Consumer<PrestataireViewModel>(
                      builder: (context, viewModel, child) {
                        // Vérifier si le prestataire est chargé avant d'afficher les services
                        if (viewModel.prestataire == null) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Chargement du profil...'),
                                ],
                              ),
                            ),
                          );
                        }

                        if (viewModel.estChargement) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (viewModel.services.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Couleurs.primaire.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.business_center,
                                    size: 48,
                                    color: Couleurs.primaire,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Aucun service pour le moment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ajoutez votre premier service pour commencer',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: viewModel.services
                              .map((service) => _buildServiceCard(service))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
