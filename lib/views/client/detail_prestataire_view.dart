import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../../configs/routes.dart';
import '../../configs/themes.dart';
import '../../configs/constants.dart';
import '../../models/prestataire.dart';
import '../../models/service.dart';
import '../../models/avis.dart';
import '../../viewmodels/prestataire_viewmodel.dart';
import '../../widgets/indicateur_chargement.dart';
import '../../widgets/carte_service.dart';

class DetailPrestataireView extends StatefulWidget {
  const DetailPrestataireView({super.key});

  @override
  State<DetailPrestataireView> createState() => _DetailPrestataireViewState();
}

class _DetailPrestataireViewState extends State<DetailPrestataireView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Prestataire? _prestataire;
  List<Service> _services = [];
  List<Avis> _avis = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;

    String? prestataireId;

    if (arguments is Map<String, dynamic> &&
        arguments.containsKey('prestataireId')) {
      prestataireId = arguments['prestataireId'] as String?;
    } else if (arguments is String) {
      prestataireId = arguments;
    } else if (arguments is Prestataire) {
      prestataireId = arguments.id;
    }

    if (prestataireId != null && prestataireId.isNotEmpty) {
      _chargerDonneesPrestataire(prestataireId);
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible de charger les détails du prestataire"),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _chargerDonneesPrestataire(String prestataireId) async {
    try {
      final prestataireViewModel = Provider.of<PrestataireViewModel>(
        context,
        listen: false,
      );

      await prestataireViewModel.chargerPrestataire(prestataireId);

      if (mounted) {
        setState(() {
          _prestataire = prestataireViewModel.prestataire;
          _services = prestataireViewModel.services;
          _avis = prestataireViewModel.avis;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(Constants.erreurChargement)),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_prestataire?.nomComplet ?? 'Prestataire'),
        backgroundColor: Couleurs.primaire,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Partage à venir")));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const IndicateurChargement()
          : _prestataire == null
          ? const Center(child: Text("Prestataire non trouvé"))
          : _buildContenu(),
      floatingActionButton: _prestataire != null
          ? FloatingActionButton.extended(
              onPressed: () {
                // Vérifier s'il y a des services disponibles
                if (_services.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Aucun service disponible pour ce prestataire",
                      ),
                    ),
                  );
                  return;
                }

                // Naviguer vers la page de réservation avec le premier service ou permettre la sélection
                Navigator.pushNamed(
                  context,
                  Routes.reservation,
                  arguments: {
                    'prestataireId': _prestataire!.id,
                    'prestataire': _prestataire!,
                    'services':
                        _services, // Passer tous les services pour permettre la sélection
                  },
                );
              },
              backgroundColor: Couleurs.primaire,
              icon: const Icon(Icons.calendar_today),
              label: const Text("Réserver"),
            )
          : null,
    );
  }

  Widget _buildContenu() {
    return Column(
      children: [
        _buildProfileHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildServicesTab(),
              _buildPortfolioTab(),
              _buildAvisTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: _prestataire!.photoProfil != null
                        ? NetworkImage(_prestataire!.photoProfil!)
                        : const AssetImage(Constants.imageProfilDefaut)
                              as ImageProvider,
                  ),
                  if (_prestataire!.estVerifieProfessionnellement ||
                      _prestataire!.estPremium)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _prestataire!.estPremium
                              ? Icons.star
                              : Icons.verified,
                          color: _prestataire!.estPremium
                              ? Colors.amber
                              : Couleurs.primaire,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _prestataire!.nomComplet,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _prestataire!.categories.join(', '),
                      style: TextStyle(
                        color: Couleurs.primaire,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        RatingBar.builder(
                          initialRating: _prestataire!.noteMoyenne,
                          minRating: 0,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 16,
                          ignoreGestures: true,
                          itemBuilder: (context, _) =>
                              const Icon(Icons.star, color: Colors.amber),
                          onRatingUpdate: (_) {},
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${_prestataire!.noteMoyenne.toStringAsFixed(1)} (${_prestataire!.nombreAvis})",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _prestataire!.adresse,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _prestataire!.description,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _ouvrirWhatsApp(_prestataire!.telephone),
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                  label: const Text("WhatsApp"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF25D366),
                    side: const BorderSide(color: Color(0xFF25D366)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _appelerPrestataire(_prestataire!.telephone),
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text("Appeler"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Couleurs.primaire,
                    side: BorderSide(color: Couleurs.primaire),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Couleurs.primaire,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Couleurs.primaire,
        tabs: const [
          Tab(text: "SERVICES"),
          Tab(text: "PORTFOLIO"),
          Tab(text: "AVIS"),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return _services.isEmpty
        ? _buildEmptyState("Aucun service disponible", Icons.work_outline)
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final service = _services[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: CarteService(
                  service: service,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.reservation,
                      arguments: {
                        'prestataireId': _prestataire!.id,
                        'serviceId': service.id,
                        'service': service, // Passer l'objet service complet
                        'prestataire':
                            _prestataire!, // Passer l'objet prestataire complet
                      },
                    );
                  },
                ),
              );
            },
          );
  }

  Widget _buildPortfolioTab() {
    return _prestataire!.photosPortfolio.isEmpty
        ? _buildEmptyState(
            "Aucune photo dans le portfolio",
            Icons.photo_library_outlined,
          )
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _prestataire!.photosPortfolio.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _prestataire!.photosPortfolio[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              );
            },
          );
  }

  Widget _buildAvisTab() {
    return _avis.isEmpty
        ? _buildEmptyState(
            "Aucun avis pour le moment",
            Icons.rate_review_outlined,
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _avis.length,
            itemBuilder: (context, index) {
              final avis = _avis[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            child: Icon(Icons.person, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Client anonyme",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  DateFormat(
                                    Constants.formatDate,
                                  ).format(avis.dateCreation),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              Text(
                                avis.note.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(avis.commentaire),
                      if (avis.photos != null && avis.photos!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: avis.photos!.length,
                              itemBuilder: (context, photoIndex) {
                                return Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      avis.photos![photoIndex],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
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

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _ouvrirWhatsApp(String telephone) async {
    String numero = telephone.replaceAll(' ', '');
    if (!numero.startsWith('+')) {
      numero = '+226$numero';
    }

    final Uri uri = Uri.parse('https://wa.me/$numero');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir WhatsApp")),
        );
      }
    }
  }

  Future<void> _appelerPrestataire(String telephone) async {
    final Uri uri = Uri.parse('tel:$telephone');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible de lancer l'appel")),
        );
      }
    }
  }
}
