// 1. CRÉER UNE NOUVELLE VUE : services_view.dart
import 'package:flutter/material.dart';
import '../../configs/themes.dart';
import '../../configs/constants.dart';

class ServicesView extends StatelessWidget {
  const ServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Nos Services'),
        backgroundColor: const Color.fromARGB(255, 253, 144, 1),
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header avec statistiques
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Couleurs.primaire, Couleurs.secondaire],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.miscellaneous_services_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tous nos services',
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${Constants.categories.length} catégories disponibles',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Grille des services
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(
                        opacity: value,
                        child: _ServiceCard(
                          titre: Constants.categories[index],
                          icon: _getCategoryIcon(Constants.categories[index]),
                          gradient: _getCategoryGradient(index),
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              '/recherche',
                              arguments: {
                                'categorie': Constants.categories[index],
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              }, childCount: Constants.categories.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
            ),
          ),

          // Espacement final
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
      [Colors.teal.shade400, Colors.cyan.shade500],
      [Colors.pink.shade400, Colors.purple.shade500],
      [Colors.indigo.shade400, Colors.blue.shade500],
      [Colors.lime.shade400, Colors.green.shade500],
    ];

    final gradient = gradients[index % gradients.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradient,
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String titre;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.titre,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Stack(
          children: [
            // Formes décoratives
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              left: -10,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Contenu
            Padding(
              padding: const EdgeInsets.all(20),
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
                  const SizedBox(height: 16),
                  Text(
                    titre,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Voir les pros',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
