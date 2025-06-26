import 'package:faso_services/services/localisation_service.dart';
import '../../services/base_donnees_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../configs/themes.dart';
import '../../configs/constants.dart';
import '../../viewmodels/recherche_viewmodel.dart';
import '../../widgets/carte_prestataire.dart';
import '../../widgets/indicateur_chargement.dart';

class RechercheView extends StatefulWidget {
  const RechercheView({super.key});

  @override
  State<RechercheView> createState() => _RechercheViewState();
}

class _RechercheViewState extends State<RechercheView>
    with AutomaticKeepAliveClientMixin {
  String _searchQuery = "";
  String _selectedCategory = "Tous";

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider(
      create: (_) =>
          RechercheViewModel(BaseDonneesService(), LocalisationService()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recherche'),
          backgroundColor: Couleurs.primaire,
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryFilter(),
            Expanded(
              child: Consumer<RechercheViewModel>(
                builder: (context, viewModel, _) {
                  if (viewModel.isLoading) {
                    return _buildLoadingState();
                  }

                  if (viewModel.prestataires.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildSearchResults(viewModel);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Consumer<RechercheViewModel>(
      builder: (context, viewModel, _) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Que recherchez-vous ?',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Couleurs.primaire.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: Couleurs.primaire,
                  size: 20,
                ),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey[600],
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            _searchQuery = "";
                            viewModel.rechercherPrestataires(
                              "",
                              _selectedCategory,
                            );
                          });
                        },
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: Colors.grey[400],
                        size: 18,
                      ),
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                viewModel.rechercherPrestataires(
                  _searchQuery,
                  _selectedCategory,
                );
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<RechercheViewModel>(
      builder: (context, viewModel, _) {
        return Container(
          height: 45,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: Constants.categories.length + 1,
            itemBuilder: (context, index) {
              final category = index == 0
                  ? "Tous"
                  : Constants.categories[index - 1];
              final isSelected = category == _selectedCategory;

              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                        viewModel.rechercherPrestataires(
                          _searchQuery,
                          category,
                        );
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  Couleurs.primaire,
                                  Couleurs.primaire.withOpacity(0.8),
                                ],
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: Couleurs.primaire.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(RechercheViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.prestataires.length,
      itemBuilder: (context, index) {
        final prestataire = viewModel.prestataires[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
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
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IndicateurChargement(),
          SizedBox(height: 16),
          Text('Recherche en cours...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Couleurs.texteSecondaire.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat trouvé',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(color: Couleurs.texteSecondaire),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez d\'autres mots-clés',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = "";
                _selectedCategory = "Tous";
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réinitialiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Couleurs.primaire,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
