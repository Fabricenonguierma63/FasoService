import 'package:flutter/material.dart';
import '../configs/themes.dart';
import '../configs/constants.dart';

class BarreRecherche extends StatefulWidget {
  final String? hintText;
  final Function(String)? onSearch;
  final Function()? onFilterTap;
  final String? initialValue;
  final bool autofocus;
  final bool showFilterButton;
  final bool showCategories;
  final VoidCallback? onTap; // ✅ Nouveau paramètre ajouté
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool isFocused;

  const BarreRecherche({
    super.key,
    this.hintText = "Rechercher un service...",
    this.onSearch,
    this.onFilterTap,
    this.initialValue,
    this.autofocus = false,
    this.showFilterButton = true,
    this.showCategories = true,
    this.onTap, // ✅ Ajout ici
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.isFocused = false,
  });

  @override
  State<BarreRecherche> createState() => _BarreRechercheState();
}

class _BarreRechercheState extends State<BarreRecherche> {
  late TextEditingController _controller;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSearch() {
    if (widget.onSearch != null) {
      widget.onSearch!(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Couleurs.blanc,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icône de recherche
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Icon(Icons.search, color: Couleurs.texteSecondaire),
              ),

              // Champ de recherche
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: widget.isFocused,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted ?? (value) => _handleSearch(),

                  textInputAction: TextInputAction.search,
                ),
              ),

              // Bouton pour effacer le texte
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Couleurs.texteSecondaire,
                  ),
                  onPressed: () {
                    _controller.clear();
                    if (widget.onClear != null) widget.onClear!();
                    if (widget.onSearch != null) widget.onSearch!('');
                  },
                ),

              // Bouton de filtre
              if (widget.showFilterButton)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed: widget.onFilterTap,
                    icon: const Icon(
                      Icons.filter_list,
                      color: Couleurs.primaire,
                    ),
                    tooltip: 'Filtrer les résultats',
                  ),
                ),
            ],
          ),
        ),

        // Liste horizontale de catégories
        if (widget.showCategories) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: Constants.categories.length,
              itemBuilder: (context, index) {
                final category = Constants.categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (isSelected) {
                          _selectedCategory = null;
                        } else {
                          _selectedCategory = category;
                        }

                        if (widget.onSearch != null) {
                          widget.onSearch!(_controller.text);
                        }
                      });
                    },
                    backgroundColor: Couleurs.blanc,
                    selectedColor: Couleurs.primaire.withOpacity(0.2),
                    checkmarkColor: Couleurs.primaire,
                    labelStyle: TextStyle(
                      color: isSelected ? Couleurs.primaire : Couleurs.texte,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// Widget de filtre étendu qui pourrait être appelé par onFilterTap
class FiltreAvance extends StatefulWidget {
  final Function(Map<String, dynamic>)? onApplyFilters;
  final Map<String, dynamic>? initialFilters;

  const FiltreAvance({super.key, this.onApplyFilters, this.initialFilters});

  @override
  State<FiltreAvance> createState() => _FiltreAvanceState();
}

class _FiltreAvanceState extends State<FiltreAvance> {
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters =
        widget.initialFilters ??
        {
          'rayon': 10.0,
          'noteMinimale': 0.0,
          'prixMax': 10000.0,
          'premiumUniquement': false,
          'disponiblesToday': false,
          'categories': <String>[],
        };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Filtres de recherche',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Filtre de rayon
          Text('Rayon de recherche: ${_filters['rayon'].round()} km'),
          Slider(
            value: _filters['rayon'],
            min: 1.0,
            max: 50.0,
            divisions: 49,
            activeColor: Couleurs.primaire,
            label: '${_filters['rayon'].round()} km',
            onChanged: (value) {
              setState(() {
                _filters['rayon'] = value;
              });
            },
          ),

          // Note minimale
          Text('Note minimale: ${_filters['noteMinimale'].round()} étoiles'),
          Slider(
            value: _filters['noteMinimale'],
            min: 0.0,
            max: 5.0,
            divisions: 5,
            activeColor: Couleurs.primaire,
            label: '${_filters['noteMinimale'].round()} étoiles',
            onChanged: (value) {
              setState(() {
                _filters['noteMinimale'] = value;
              });
            },
          ),

          // Prix maximum
          Text('Prix maximum: ${_filters['prixMax'].round()} FCFA'),
          Slider(
            value: _filters['prixMax'],
            min: 1000.0,
            max: 50000.0,
            divisions: 49,
            activeColor: Couleurs.primaire,
            label: '${_filters['prixMax'].round()} FCFA',
            onChanged: (value) {
              setState(() {
                _filters['prixMax'] = value;
              });
            },
          ),

          // Switches
          CheckboxListTile(
            title: const Text('Prestataires premium uniquement'),
            value: _filters['premiumUniquement'],
            activeColor: Couleurs.primaire,
            onChanged: (value) {
              setState(() {
                _filters['premiumUniquement'] = value ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),

          CheckboxListTile(
            title: const Text('Disponibles aujourd\'hui uniquement'),
            value: _filters['disponiblesToday'],
            activeColor: Couleurs.primaire,
            onChanged: (value) {
              setState(() {
                _filters['disponiblesToday'] = value ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),

          const SizedBox(height: 16),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  // Réinitialiser les filtres
                  setState(() {
                    _filters = {
                      'rayon': 10.0,
                      'noteMinimale': 0.0,
                      'prixMax': 10000.0,
                      'premiumUniquement': false,
                      'disponiblesToday': false,
                      'categories': <String>[],
                    };
                  });
                },
                child: const Text('Réinitialiser'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (widget.onApplyFilters != null) {
                    widget.onApplyFilters!(_filters);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Appliquer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
