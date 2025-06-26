// views/client/donner_avis_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../configs/themes.dart';
import '../../configs/constants.dart';
import '../../models/reservation.dart';
import '../../models/service.dart';
import '../../models/prestataire.dart';
import '../../viewmodels/avis_viewmodel.dart';
import '../../widgets/indicateur_chargement.dart';

class DonnerAvisView extends StatefulWidget {
  const DonnerAvisView({super.key});

  @override
  State<DonnerAvisView> createState() => _DonnerAvisViewState();
}

class _DonnerAvisViewState extends State<DonnerAvisView> {
  final _formKey = GlobalKey<FormState>();
  final _commentaireController = TextEditingController();
  int _noteSelectionnee = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  void _soumettreAvis(
    Reservation reservation,
    Service service,
    Prestataire prestataire,
  ) async {
    if (_formKey.currentState!.validate() && _noteSelectionnee > 0) {
      setState(() {
        _isLoading = true;
      });

      final avisViewModel = Provider.of<AvisViewModel>(context, listen: false);

      try {
        // ✅ Ajout d'un timeout pour l'UI
        final success = await avisViewModel
            .creerAvis(
              prestataireId: prestataire.id,
              serviceId: service.id,
              reservationId: reservation.id,
              note: _noteSelectionnee,
              commentaire: _commentaireController.text.trim(),
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw Exception('L\'opération a pris trop de temps');
              },
            );

        setState(() {
          _isLoading = false;
        });

        // Reste du code...
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final Reservation reservation = arguments['reservation'];
    final Service service = arguments['service'];
    final Prestataire prestataire = arguments['prestataire'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Donner mon avis',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: IndicateurChargement())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carte du service et prestataire
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.titre,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundImage:
                                      prestataire.photoProfil != null
                                      ? NetworkImage(prestataire.photoProfil!)
                                      : const AssetImage(
                                              Constants.imageProfilDefaut,
                                            )
                                            as ImageProvider,
                                  backgroundColor: Colors.orange.withAlpha(26),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prestataire.nomComplet,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        prestataire.categories.join(', '),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Section notation
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Votre note',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _noteSelectionnee = index + 1;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Icon(
                                      index < _noteSelectionnee
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 40,
                                      color: Colors.amber,
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                _noteSelectionnee == 0
                                    ? 'Tapez sur les étoiles pour noter'
                                    : _getNoteText(_noteSelectionnee),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section commentaire
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Votre commentaire',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _commentaireController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText:
                                    'Partagez votre expérience avec ce prestataire...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.orange,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez saisir un commentaire';
                                }
                                if (value.trim().length < 10) {
                                  return 'Le commentaire doit contenir au moins 10 caractères';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Bouton de soumission
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            _soumettreAvis(reservation, service, prestataire),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Envoyer mon avis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getNoteText(int note) {
    switch (note) {
      case 1:
        return 'Très insatisfait';
      case 2:
        return 'Insatisfait';
      case 3:
        return 'Correct';
      case 4:
        return 'Satisfait';
      case 5:
        return 'Très satisfait';
      default:
        return '';
    }
  }
}
