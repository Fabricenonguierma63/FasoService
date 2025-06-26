import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../configs/themes.dart';
import '../../services/localisation_service.dart';
import '../../services/base_donnees_service.dart';
import '../../models/prestataire.dart';
import '../../widgets/carte_prestataire.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PrestatairesProchesView extends StatefulWidget {
  const PrestatairesProchesView({super.key});

  @override
  State<PrestatairesProchesView> createState() =>
      _PrestatairesProchesViewState();
}

class _PrestatairesProchesViewState extends State<PrestatairesProchesView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Position? _currentPosition;
  List<PrestataireAvecDistance> _prestatairesProches = [];
  bool _isLoading = true;
  bool _showMap = false;
  String? _errorMessage;
  double _rayonKm = 5.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _chargerPrestatairesProches();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  Future<void> _chargerPrestatairesProches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final localisationService = Provider.of<LocalisationService>(
        context,
        listen: false,
      );
      final baseDonneesService = Provider.of<BaseDonneesService>(
        context,
        listen: false,
      );

      // Obtenir la position actuelle
      final position = await localisationService.obtenirPositionActuelle();
      if (position == null) {
        setState(() {
          _errorMessage =
              'Impossible d\'obtenir votre localisation. '
              'Vérifiez que les services de localisation sont activés.';
          _isLoading = false;
        });
        return;
      }

      _currentPosition = position;

      // Récupérer tous les prestataires (à adapter selon votre base de données)
      final prestataires = await baseDonneesService
          .obtenirPrestatairesAvecCoordonnees();

      // Calculer les distances et filtrer par rayon
      final prestatairesAvecDistance = <PrestataireAvecDistance>[];

      for (final prestataire in prestataires) {
        if (prestataire.latitude != null && prestataire.longitude != null) {
          final distance = localisationService.calculerDistance(
            position.latitude,
            position.longitude,
            prestataire.latitude!,
            prestataire.longitude!,
          );

          if (distance <= _rayonKm) {
            prestatairesAvecDistance.add(
              PrestataireAvecDistance(
                prestataire: prestataire,
                distance: distance,
              ),
            );
          }
        }
      }

      // Trier par distance
      prestatairesAvecDistance.sort((a, b) => a.distance.compareTo(b.distance));

      setState(() {
        _prestatairesProches = prestatairesAvecDistance;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : _buildContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Couleurs.primaire,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prestataires proches',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          if (_currentPosition != null)
            Text(
              'Dans un rayon de ${_rayonKm.toInt()} km',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(_showMap ? Icons.list_rounded : Icons.map_rounded),
          onPressed: () {
            setState(() {
              _showMap = !_showMap;
            });
          },
        ),
        PopupMenuButton<double>(
          icon: const Icon(Icons.tune_rounded),
          onSelected: (rayon) {
            setState(() {
              _rayonKm = rayon;
            });
            _chargerPrestatairesProches();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 2.0, child: Text('2 km')),
            const PopupMenuItem(value: 5.0, child: Text('5 km')),
            const PopupMenuItem(value: 10.0, child: Text('10 km')),
            const PopupMenuItem(value: 20.0, child: Text('20 km')),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Couleurs.primaire.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Couleurs.primaire),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recherche des prestataires près de vous...',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Localisation indisponible',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _chargerPrestatairesProches,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Couleurs.primaire,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_prestatairesProches.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _showMap ? _buildMapView() : _buildListView(),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_searching_rounded,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Aucun prestataire trouvé',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Aucun prestataire n\'est disponible dans un rayon de ${_rayonKm.toInt()} km.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _rayonKm = _rayonKm < 20 ? _rayonKm + 5 : 2;
                  });
                  _chargerPrestatairesProches();
                },
                icon: const Icon(Icons.zoom_out_map_rounded),
                label: Text(
                  'Élargir à ${(_rayonKm < 20 ? _rayonKm + 5 : 2).toInt()} km',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Couleurs.primaire,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: _chargerPrestatairesProches,
          color: Couleurs.primaire,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header avec statistiques
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Couleurs.primaire.withOpacity(0.1),
                        Couleurs.secondaire.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Couleurs.primaire.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Couleurs.primaire,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_prestatairesProches.length} prestataire${_prestatairesProches.length > 1 ? 's' : ''} trouvé${_prestatairesProches.length > 1 ? 's' : ''}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Couleurs.primaire,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dans un rayon de ${_rayonKm.toInt()} km',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Liste des prestataires
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final prestataireAvecDistance = _prestatairesProches[index];
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: _PrestataireProcheCarte(
                                prestataireAvecDistance:
                                    prestataireAvecDistance,
                                onTap: () => _ouvrirDetailPrestataire(
                                  prestataireAvecDistance.prestataire,
                                ),
                                onDirections: () => _ouvrirDirections(
                                  prestataireAvecDistance.prestataire,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }, childCount: _prestatairesProches.length),
                ),
              ),

              // Espacement final
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _currentPosition != null
                        ? LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )
                        : const LatLng(
                            12.3714,
                            -1.5197,
                          ), // Ouagadougou par défaut
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: [
                        // Marqueur pour la position actuelle
                        if (_currentPosition != null)
                          Marker(
                            point: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        // Marqueurs pour les prestataires
                        ..._prestatairesProches
                            .map((prestataireAvecDistance) {
                              final prestataire =
                                  prestataireAvecDistance.prestataire;
                              if (prestataire.latitude != null &&
                                  prestataire.longitude != null) {
                                return Marker(
                                  point: LatLng(
                                    prestataire.latitude!,
                                    prestataire.longitude!,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _ouvrirDetailPrestataire(prestataire),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: prestataire.estPremium
                                            ? Couleurs.primaire
                                            : Couleurs.secondaire,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        prestataire.estPremium
                                            ? Icons.star
                                            : Icons.person_pin,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return null;
                            })
                            .where((marker) => marker != null)
                            .cast<Marker>(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prestataires trouvés (${_prestatairesProches.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _prestatairesProches.length,
                      itemBuilder: (context, index) {
                        final prestataireAvecDistance =
                            _prestatairesProches[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: CartePrestataire(
                            prestataire: prestataireAvecDistance.prestataire,
                            distanceEnKm: prestataireAvecDistance.distance,
                            estCompact: true,
                            onTap: () => _ouvrirDetailPrestataire(
                              prestataireAvecDistance.prestataire,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_isLoading || _errorMessage != null) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: _chargerPrestatairesProches,
      backgroundColor: Couleurs.primaire,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Actualiser'),
    );
  }

  void _ouvrirDetailPrestataire(Prestataire prestataire) {
    // Navigation vers le détail du prestataire
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => DetailPrestataireView(prestataire: prestataire),
    //   ),
    // );
  }

  void _ouvrirDirections(Prestataire prestataire) async {
    if (_currentPosition != null &&
        prestataire.latitude != null &&
        prestataire.longitude != null) {
      final url =
          'https://www.google.com/maps/dir/'
          '${_currentPosition!.latitude},${_currentPosition!.longitude}/'
          '${prestataire.latitude},${prestataire.longitude}';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }
}

class _PrestataireProcheCarte extends StatelessWidget {
  final PrestataireAvecDistance prestataireAvecDistance;
  final VoidCallback onTap;
  final VoidCallback onDirections;

  const _PrestataireProcheCarte({
    required this.prestataireAvecDistance,
    required this.onTap,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    final prestataire = prestataireAvecDistance.prestataire;
    final distance = prestataireAvecDistance.distance;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Couleurs.primaire,
                      child: Text(
                        prestataire.nom.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prestataire.nom,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            prestataire.categories.isNotEmpty
                                ? prestataire.categories.first
                                : 'Service non spécifié',
                            style: TextStyle(
                              color: Couleurs.primaire,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Couleurs.primaire.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Couleurs.primaire,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${distance.toStringAsFixed(1)} km',
                            style: TextStyle(
                              color: Couleurs.primaire,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (prestataire.description.isNotEmpty)
                  Text(
                    prestataire.description,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    if (prestataire.noteMoyenne > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              prestataire.noteMoyenne.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Spacer(),

                    OutlinedButton.icon(
                      onPressed: onDirections,
                      icon: const Icon(Icons.directions_rounded, size: 16),
                      label: const Text('Itinéraire'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Couleurs.primaire,
                        side: BorderSide(color: Couleurs.primaire),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Couleurs.primaire,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Voir'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Classe pour associer un prestataire à sa distance
class PrestataireAvecDistance {
  final Prestataire prestataire;
  final double distance;

  PrestataireAvecDistance({required this.prestataire, required this.distance});
}
