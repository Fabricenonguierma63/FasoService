import 'package:faso_services/services/base_donnees_service.dart';
import 'package:faso_services/services/localisation_service.dart';
import 'package:faso_services/views/client/mes_reservations_view.dart';
import 'package:faso_services/views/client/prestataire_proche_view.dart';
import 'package:faso_services/views/commun/profil_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../client/services_view.dart';
import '../../configs/themes.dart';
import '../../configs/constants.dart';
import '../../viewmodels/accueil_viewmodel.dart';
import '../../widgets/carte_prestataire.dart';
import '../../widgets/barre_recherche.dart';
import 'recherche_view.dart';

class AccueilView extends StatefulWidget {
  const AccueilView({super.key});

  @override
  State<AccueilView> createState() => _AccueilViewState();
}

class _AccueilViewState extends State<AccueilView>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: const _AccueilContent(),
          ),
          const RechercheView(),
          const MesReservationsView(),
          const ProfilView(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(25, 0, 0, 0), // 0.1 * 255 = 25.5 ≈ 25
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Couleurs.primaire,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: 'Recherche',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded),
              label: 'Réservations',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class _AccueilContent extends StatelessWidget {
  const _AccueilContent();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return ChangeNotifierProvider(
      create: (context) {
        final baseDonnees = Provider.of<BaseDonneesService>(
          context,
          listen: false,
        );
        final localisation = Provider.of<LocalisationService>(
          context,
          listen: false,
        );
        return AccueilViewModel(baseDonnees, localisation);
      },
      child: Consumer<AccueilViewModel>(
        builder: (context, viewModel, _) {
          return RefreshIndicator(
            onRefresh: () async {
              // Logique de rafraîchissement
            },
            color: Couleurs.primaire,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header moderne avec dégradé
                SliverAppBar(
                  expandedHeight: 280,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: Couleurs.primaire,
                  automaticallyImplyLeading:
                      false, // Cette ligne supprime la flèche de retour
                  flexibleSpace: FlexibleSpaceBar(
                    background: _HeaderSection(
                      size: size,
                      textTheme: textTheme,
                    ),
                  ),
                ),

                // Section mieux notés
                SliverToBoxAdapter(
                  child: _TopRatedSection(textTheme: textTheme),
                ),

                // Catégories avec design moderne
                SliverToBoxAdapter(
                  child: _CategoriesSection(textTheme: textTheme),
                ),

                // Services populaires
                SliverToBoxAdapter(
                  child: _PopularServicesSection(textTheme: textTheme),
                ),

                // Section près de vous
                SliverToBoxAdapter(child: _NearbySection(textTheme: textTheme)),

                // Liste des prestataires avec shimmer loading
                viewModel.isLoading
                    ? SliverToBoxAdapter(child: _ShimmerLoadingList())
                    : SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: (viewModel.prestataires ?? []).isEmpty
                            ? SliverToBoxAdapter(child: _EmptyState())
                            : SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final prestataire =
                                      viewModel.prestataires[index];
                                  return TweenAnimationBuilder<double>(
                                    duration: Duration(
                                      milliseconds: 300 + (index * 100),
                                    ),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: Opacity(
                                          opacity: value,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 16.0,
                                            ),
                                            child: CartePrestataire(
                                              prestataire: prestataire,
                                              onTap: () {
                                                Navigator.pushNamed(
                                                  context,
                                                  '/detail_prestataire',
                                                  arguments: prestataire,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }, childCount: viewModel.prestataires.length),
                              ),
                      ),

                // Espacement final
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final Size size;
  final TextTheme textTheme;

  const _HeaderSection({required this.size, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Couleurs.primaire,
            Couleurs.secondaire,
            Couleurs.primaire.withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Formes décoratives
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // Contenu principal
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salutation avec animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(-20 * (1 - value), 0),
                      child: Opacity(
                        opacity: value,
                        child: Row(
                          children: [
                            Icon(
                              Icons.waving_hand,
                              color: Colors.orange.shade300,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Salut !',
                              style: textTheme.headlineMedium?.copyWith(
                                color: Couleurs.blanc,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                Text(
                  'Trouvez le service parfait\nprès de chez vous',
                  style: textTheme.titleLarge?.copyWith(
                    color: Couleurs.blanc,
                    fontWeight: FontWeight.w300,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 24),

                // Barre de recherche moderne
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: BarreRecherche(
                    onTap: () {
                      Navigator.pushNamed(context, '/recherche');
                    },
                    showCategories: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopRatedSection extends StatelessWidget {
  final TextTheme textTheme;

  const _TopRatedSection({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    // Données simulées - à remplacer par vos vraies données
    final topRatedProviders = [
      {
        'name': 'Marie Ouédraogo',
        'service': 'Coiffure',
        'rating': 4.9,
        'reviews': 127,
        'image':
            'assets/images/provider1.jpg', // Remplacez par vos vraies images
        'specialty': 'Tresses & Défrisage',
        'price': '5 000 FCFA',
      },
      {
        'name': 'Ibrahim Sawadogo',
        'service': 'Électricité',
        'rating': 4.8,
        'reviews': 89,
        'image': 'assets/images/provider2.jpg',
        'specialty': 'Installation & Réparation',
        'price': '8 000 FCFA',
      },
      {
        'name': 'Fatou Traoré',
        'service': 'Couture',
        'rating': 4.9,
        'reviews': 156,
        'image': 'assets/images/provider3.jpg',
        'specialty': 'Mode Traditionnelle',
        'price': '12 000 FCFA',
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.amber.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mieux notés',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    'Les prestataires les plus appréciés',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: topRatedProviders.length,
              itemBuilder: (context, index) {
                final provider = topRatedProviders[index];
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 500 + (index * 200)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(20 * (1 - value), 0),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white, Colors.grey.shade50],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
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
                                    // Avatar avec initiales si pas d'image
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Couleurs.primaire,
                                            Couleurs.secondaire,
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          provider['name']
                                              .toString()
                                              .split(' ')
                                              .map((e) => e[0])
                                              .join('')
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            provider['name'] as String,
                                            style: textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            provider['service'] as String,
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Couleurs.primaire,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Rating et avis
                                Row(
                                  children: [
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
                                            provider['rating'].toString(),
                                            style: TextStyle(
                                              color: Colors.amber.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${provider['reviews']} avis)',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Spécialité
                                Text(
                                  provider['specialty'] as String,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                const Spacer(),

                                // Prix et bouton
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'À partir de',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: Colors.grey.shade500,
                                            fontSize: 10,
                                          ),
                                        ),
                                        Text(
                                          provider['price'] as String,
                                          style: textTheme.titleSmall?.copyWith(
                                            color: Couleurs.primaire,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Couleurs.primaire,
                                            Couleurs.secondaire,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Couleurs.primaire
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/detail_prestataire',
                                              arguments:
                                                  provider, // Passez les données du prestataire
                                            );
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            child: Text(
                                              'Voir',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  final TextTheme textTheme;

  const _CategoriesSection({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nos services',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ServicesView(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Voir tout'),
                style: TextButton.styleFrom(foregroundColor: Couleurs.primaire),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: Constants.categories.length,
              itemBuilder: (context, index) {
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(
                        opacity: value,
                        child: _ModernCategorieCard(
                          titre: Constants.categories[index],
                          icon: _getCategoryIcon(Constants.categories[index]),
                          gradient: _getCategoryGradient(index),
                          onTap: () {
                            // Navigation avec catégorie
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Coiffure':
        return Icons.content_cut_rounded;
      case 'Couture':
        return Icons.healing_rounded;
      case 'Électricité':
        return Icons.electrical_services_rounded;
      case 'Plomberie':
        return Icons.plumbing_rounded;
      case 'Mécanique':
        return Icons.car_repair_rounded;
      case 'Menuiserie':
        return Icons.carpenter_rounded;
      case 'Informatique':
        return Icons.computer_rounded;
      case 'Nettoyage':
        return Icons.cleaning_services_rounded;
      case 'Jardinage':
        return Icons.yard_rounded;
      case 'Peinture':
        return Icons.format_paint_rounded;
      case 'Cuisine':
        return Icons.restaurant_rounded;
      default:
        return Icons.miscellaneous_services_rounded;
    }
  }

  LinearGradient _getCategoryGradient(int index) {
    final gradients = [
      [Colors.orange.shade400, Colors.deepOrange.shade500],
      [Colors.blue.shade400, Colors.indigo.shade500],
      [Colors.green.shade400, Colors.teal.shade500],
      [Colors.purple.shade400, Colors.deepPurple.shade500],
      [Colors.red.shade400, Colors.pink.shade500],
      [Colors.amber.shade400, Colors.orange.shade500],
    ];

    final gradient = gradients[index % gradients.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradient,
    );
  }
}

class _ModernCategorieCard extends StatelessWidget {
  final String titre;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ModernCategorieCard({
    required this.titre,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              titre,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularServicesSection extends StatelessWidget {
  final TextTheme textTheme;

  const _PopularServicesSection({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    final popularServices = [
      {
        'title': 'Coiffure à domicile',
        'subtitle': '24 prestataires',
        'icon': Icons.content_cut_rounded,
      },
      {
        'title': 'Réparation électrique',
        'subtitle': '18 prestataires',
        'icon': Icons.electrical_services_rounded,
      },
      {
        'title': 'Couture express',
        'subtitle': '31 prestataires',
        'icon': Icons.healing_rounded,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services populaires',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...popularServices.map(
            (service) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Couleurs.primaire.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      service['icon'] as IconData,
                      color: Couleurs.primaire,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['title'] as String,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service['subtitle'] as String,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbySection extends StatelessWidget {
  final TextTheme textTheme;

  const _NearbySection({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Couleurs.primaire.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: Couleurs.primaire,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Près de vous',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grâce à la localisation',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrestatairesProchesView(),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Voir tout'),
            style: TextButton.styleFrom(foregroundColor: Couleurs.primaire),
          ),
        ],
      ),
    );
  }
}

class _ShimmerLoadingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.3, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucun prestataire disponible',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Revenez plus tard ou élargissez votre zone de recherche',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
