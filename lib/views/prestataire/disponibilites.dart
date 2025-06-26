import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/time_slot.dart';
import '../../configs/themes.dart';
import '../../services/base_donnees_service.dart';
import '../../viewmodels/prestataire_viewmodel.dart';

class DisponibilitesView extends StatefulWidget {
  const DisponibilitesView({super.key});

  @override
  State<DisponibilitesView> createState() => _DisponibilitesViewState();
}

class _DisponibilitesViewState extends State<DisponibilitesView>
    with TickerProviderStateMixin {
  final BaseDonneesService _bdService = BaseDonneesService();
  late PrestataireViewModel _prestataireViewModel;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Calendrier et variables de dates
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  // Disponibilités
  late Map<DateTime, List<TimeSlot>> _disponibilites;
  late Map<DateTime, bool> _joursDisponibles;

  // Chargement et états
  bool _chargement = true;
  bool _sauvegarde = false;

  // Templates de créneaux rapides
  final List<Map<String, dynamic>> _templatesCreneaux = [
    {
      'nom': 'Matinée',
      'creneaux': [
        TimeSlot(
          debut: TimeOfDay(hour: 8, minute: 0),
          fin: TimeOfDay(hour: 12, minute: 0),
        ),
      ],
    },
    {
      'nom': 'Après-midi',
      'creneaux': [
        TimeSlot(
          debut: TimeOfDay(hour: 14, minute: 0),
          fin: TimeOfDay(hour: 18, minute: 0),
        ),
      ],
    },
    {
      'nom': 'Journée complète',
      'creneaux': [
        TimeSlot(
          debut: TimeOfDay(hour: 8, minute: 0),
          fin: TimeOfDay(hour: 12, minute: 0),
        ),
        TimeSlot(
          debut: TimeOfDay(hour: 14, minute: 0),
          fin: TimeOfDay(hour: 18, minute: 0),
        ),
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _disponibilites = {};
    _joursDisponibles = {};

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialiserDonnees();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prestataireViewModel = Provider.of<PrestataireViewModel>(context);
  }

  Future<void> _initialiserDonnees() async {
    setState(() {
      _chargement = true;
    });

    try {
      final prestataire = _prestataireViewModel.prestataire;

      if (prestataire != null) {
        final disponibilites = await _bdService.getDisponibilites(
          prestataire.id,
        );

        setState(() {
          _disponibilites = disponibilites;
          _disponibilites.forEach((date, slots) {
            final jour = DateTime(date.year, date.month, date.day);
            _joursDisponibles[jour] = slots.isNotEmpty;
          });
          _chargement = false;
        });

        _animationController.forward();
      } else {
        _afficherErreur('Prestataire non trouvé');
        setState(() => _chargement = false);
      }
    } catch (e) {
      if (kDebugMode) print('Erreur lors du chargement des disponibilités: $e');
      _afficherErreur('Erreur lors du chargement des disponibilités');
      setState(() => _chargement = false);
    }
  }

  Future<void> _enregistrerDisponibilites(
    DateTime jour,
    List<TimeSlot> creneaux,
  ) async {
    if (_sauvegarde) return; // Éviter les doubles sauvegardes

    try {
      final prestataire = _prestataireViewModel.prestataire;
      if (prestataire == null) return;

      setState(() => _sauvegarde = true);

      await _bdService.setDisponibilites(prestataire.id, jour, creneaux);

      setState(() {
        final jourKey = DateTime(jour.year, jour.month, jour.day);
        _disponibilites[jourKey] = creneaux;
        _joursDisponibles[jourKey] = creneaux.isNotEmpty;
        _sauvegarde = false;
      });

      _afficherSucces('Disponibilités enregistrées');
    } catch (e) {
      if (kDebugMode) print('Erreur lors de l\'enregistrement: $e');
      _afficherErreur('Erreur lors de l\'enregistrement');
      setState(() => _sauvegarde = false);
    }
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Couleurs.erreur,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _afficherSucces(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _appliquerTemplate(Map<String, dynamic> template) {
    final jourKey = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final creneaux = List<TimeSlot>.from(template['creneaux']);
    _enregistrerDisponibilites(jourKey, creneaux);
  }

  void _ajouterCreneau() {
    final jourKey = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    List<TimeSlot> creneauxDuJour = _disponibilites[jourKey] ?? [];

    // Proposer une heure de début intelligente
    TimeOfDay heureDebut = const TimeOfDay(hour: 8, minute: 0);
    if (creneauxDuJour.isNotEmpty) {
      final dernierCreneau = creneauxDuJour.last;
      heureDebut = TimeOfDay(
        hour: dernierCreneau.fin.hour,
        minute: dernierCreneau.fin.minute,
      );
    }

    TimeSlot nouveauCreneau = TimeSlot(
      debut: heureDebut,
      fin: TimeOfDay(hour: heureDebut.hour + 1, minute: heureDebut.minute),
    );

    showDialog(
      context: context,
      builder: (context) => TimeSlotDialog(
        timeSlot: nouveauCreneau,
        onSave: (creneau) {
          if (_validerCreneau(creneau, creneauxDuJour)) {
            creneauxDuJour.add(creneau);
            creneauxDuJour.sort((a, b) => _comparerCreneaux(a, b));
            _enregistrerDisponibilites(jourKey, creneauxDuJour);
          }
        },
      ),
    );
  }

  void _modifierCreneau(int index) {
    final jourKey = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    List<TimeSlot> creneauxDuJour = _disponibilites[jourKey] ?? [];

    if (index >= 0 && index < creneauxDuJour.length) {
      showDialog(
        context: context,
        builder: (context) => TimeSlotDialog(
          timeSlot: creneauxDuJour[index],
          onSave: (creneauModifie) {
            List<TimeSlot> autresCreneaux = List.from(creneauxDuJour)
              ..removeAt(index);
            if (_validerCreneau(creneauModifie, autresCreneaux)) {
              creneauxDuJour[index] = creneauModifie;
              creneauxDuJour.sort((a, b) => _comparerCreneaux(a, b));
              _enregistrerDisponibilites(jourKey, creneauxDuJour);
            }
          },
        ),
      );
    }
  }

  void _supprimerCreneau(int index) {
    final jourKey = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    List<TimeSlot> creneauxDuJour = List.from(_disponibilites[jourKey] ?? []);

    if (index >= 0 && index < creneauxDuJour.length) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer ce créneau ?\n'
            '${_formatTimeOfDay(creneauxDuJour[index].debut)} - '
            '${_formatTimeOfDay(creneauxDuJour[index].fin)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                creneauxDuJour.removeAt(index);
                _enregistrerDisponibilites(jourKey, creneauxDuJour);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Couleurs.erreur),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );
    }
  }

  bool _validerCreneau(TimeSlot nouveau, List<TimeSlot> creneauxExistants) {
    final debutMinutes = nouveau.debut.hour * 60 + nouveau.debut.minute;
    final finMinutes = nouveau.fin.hour * 60 + nouveau.fin.minute;

    if (finMinutes <= debutMinutes) {
      _afficherErreur('L\'heure de fin doit être après l\'heure de début');
      return false;
    }

    // Vérifier les chevauchements
    for (final creneau in creneauxExistants) {
      final creneauDebutMin = creneau.debut.hour * 60 + creneau.debut.minute;
      final creneauFinMin = creneau.fin.hour * 60 + creneau.fin.minute;

      if ((debutMinutes < creneauFinMin && finMinutes > creneauDebutMin)) {
        _afficherErreur('Ce créneau chevauche avec un créneau existant');
        return false;
      }
    }

    return true;
  }

  int _comparerCreneaux(TimeSlot a, TimeSlot b) {
    final aMinutes = a.debut.hour * 60 + a.debut.minute;
    final bMinutes = b.debut.hour * 60 + b.debut.minute;
    return aMinutes.compareTo(bMinutes);
  }

  void _changerDisponibiliteJour(bool disponible) {
    final jourKey = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );

    if (disponible) {
      if (!_disponibilites.containsKey(jourKey) ||
          (_disponibilites[jourKey] ?? []).isEmpty) {
        // Afficher les templates rapides
        _afficherTemplatesRapides();
      }
    } else {
      _enregistrerDisponibilites(jourKey, []);
    }
  }

  void _afficherTemplatesRapides() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Créneaux rapides',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._templatesCreneaux.map(
              (template) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Couleurs.primaire.withOpacity(0.1),
                  child: const Icon(Icons.schedule, color: Couleurs.primaire),
                ),
                title: Text(template['nom']),
                subtitle: Text(_getTemplateDescription(template['creneaux'])),
                onTap: () {
                  Navigator.pop(context);
                  _appliquerTemplate(template);
                },
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Couleurs.secondaire.withOpacity(0.1),
                child: const Icon(Icons.add, color: Couleurs.secondaire),
              ),
              title: const Text('Créer un créneau personnalisé'),
              onTap: () {
                Navigator.pop(context);
                _ajouterCreneau();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getTemplateDescription(List<TimeSlot> creneaux) {
    return creneaux
        .map((c) => '${_formatTimeOfDay(c.debut)}-${_formatTimeOfDay(c.fin)}')
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final jourKey = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final creneauxJourSelectionne = _disponibilites[jourKey] ?? [];
    final estJourDisponible = _joursDisponibles[jourKey] ?? false;
    final estAujourdhui = isSameDay(_selectedDay, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Disponibilités'),
        actions: [
          if (_sauvegarde)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _chargement
          ? const Center(
              child: CircularProgressIndicator(color: Couleurs.primaire),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Calendrier amélioré
                  Card(
                    margin: const EdgeInsets.all(8.0),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Mois',
                          CalendarFormat.week: 'Semaine',
                        },
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onFormatChanged: (format) {
                          setState(() => _calendarFormat = format);
                        },
                        calendarStyle: CalendarStyle(
                          selectedDecoration: const BoxDecoration(
                            color: Couleurs.primaire,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Couleurs.primaire.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          outsideDaysVisible: false,
                          weekendTextStyle: TextStyle(color: Colors.grey[600]),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: true,
                          titleCentered: true,
                          formatButtonDecoration: BoxDecoration(
                            color: Couleurs.secondaire,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          formatButtonTextStyle: TextStyle(color: Colors.white),
                        ),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            final estDispo =
                                _joursDisponibles[DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                )] ??
                                false;
                            if (estDispo) {
                              return Positioned(
                                bottom: 1,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Couleurs.secondaire,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),

                  // Section du jour sélectionné
                  Expanded(
                    child: Card(
                      margin: const EdgeInsets.all(8.0),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // En-tête avec date et switch
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        estAujourdhui
                                            ? 'Aujourd\'hui'
                                            : DateFormat(
                                                'EEEE dd MMMM yyyy',
                                                'fr',
                                              ).format(_selectedDay),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                      ),
                                      if (estAujourdhui)
                                        Text(
                                          DateFormat(
                                            'dd MMMM yyyy',
                                            'fr',
                                          ).format(_selectedDay),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                                Transform.scale(
                                  scale: 1.2,
                                  child: Switch.adaptive(
                                    value: estJourDisponible,
                                    onChanged: _changerDisponibiliteJour,
                                    activeColor: Couleurs.primaire,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            if (estJourDisponible) ...[
                              // En-tête des créneaux
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Créneaux horaires (${creneauxJourSelectionne.length})',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _ajouterCreneau,
                                    icon: const Icon(Icons.add_circle),
                                    color: Couleurs.secondaire,
                                    iconSize: 28,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Liste des créneaux
                              Expanded(
                                child: creneauxJourSelectionne.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              size: 64,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Aucun créneau défini',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ElevatedButton.icon(
                                              onPressed: _ajouterCreneau,
                                              icon: const Icon(Icons.add),
                                              label: const Text(
                                                'Ajouter un créneau',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Couleurs.secondaire,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount:
                                            creneauxJourSelectionne.length,
                                        itemBuilder: (context, index) {
                                          final creneau =
                                              creneauxJourSelectionne[index];
                                          return Card(
                                            margin: const EdgeInsets.only(
                                              bottom: 8.0,
                                            ),
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor: Couleurs
                                                    .primaire
                                                    .withOpacity(0.1),
                                                child: Text(
                                                  '${index + 1}',
                                                  style: const TextStyle(
                                                    color: Couleurs.primaire,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              title: Text(
                                                '${_formatTimeOfDay(creneau.debut)} - ${_formatTimeOfDay(creneau.fin)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: Text(
                                                _getDureeTexte(creneau),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit_outlined,
                                                    ),
                                                    color: Couleurs.secondaire,
                                                    onPressed: () =>
                                                        _modifierCreneau(index),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                    ),
                                                    color: Couleurs.erreur,
                                                    onPressed: () =>
                                                        _supprimerCreneau(
                                                          index,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ] else ...[
                              // Message quand le jour n'est pas disponible
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.event_busy,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Jour non disponible',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Activez la disponibilité pour définir des créneaux',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getDureeTexte(TimeSlot creneau) {
    final debutMinutes = creneau.debut.hour * 60 + creneau.debut.minute;
    final finMinutes = creneau.fin.hour * 60 + creneau.fin.minute;
    final dureeMinutes = finMinutes - debutMinutes;

    if (dureeMinutes >= 60) {
      final heures = dureeMinutes ~/ 60;
      final minutes = dureeMinutes % 60;
      if (minutes == 0) {
        return '${heures}h';
      } else {
        return '${heures}h${minutes.toString().padLeft(2, '0')}';
      }
    } else {
      return '${dureeMinutes}min';
    }
  }
}

// Dialog modernisé pour les créneaux
class TimeSlotDialog extends StatefulWidget {
  final TimeSlot timeSlot;
  final Function(TimeSlot) onSave;

  const TimeSlotDialog({
    super.key,
    required this.timeSlot,
    required this.onSave,
  });

  @override
  TimeSlotDialogState createState() => TimeSlotDialogState();
}

class TimeSlotDialogState extends State<TimeSlotDialog> {
  late TimeOfDay _debut;
  late TimeOfDay _fin;

  @override
  void initState() {
    super.initState();
    _debut = widget.timeSlot.debut;
    _fin = widget.timeSlot.fin;
  }

  Future<void> _selectTime(BuildContext context, bool isDebut) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isDebut ? _debut : _fin,
      initialEntryMode: TimePickerEntryMode.input,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Couleurs.primaire,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Couleurs.primaire),
              ),
              dayPeriodBorderSide: const BorderSide(color: Couleurs.primaire),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isDebut) {
          _debut = picked;
          final debutMinutes = _debut.hour * 60 + _debut.minute;
          final finMinutes = _fin.hour * 60 + _fin.minute;
          if (debutMinutes >= finMinutes) {
            _fin = TimeOfDay(
              hour: (_debut.hour + 1) % 24,
              minute: _debut.minute,
            );
          }
        } else {
          _fin = picked;
          final debutMinutes = _debut.hour * 60 + _debut.minute;
          final finMinutes = _fin.hour * 60 + _fin.minute;
          if (finMinutes <= debutMinutes) {
            _debut = TimeOfDay(
              hour: (_fin.hour - 1) >= 0 ? (_fin.hour - 1) : 23,
              minute: _fin.minute,
            );
          }
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getDuree() {
    final debutMinutes = _debut.hour * 60 + _debut.minute;
    final finMinutes = _fin.hour * 60 + _fin.minute;
    final dureeMinutes = finMinutes - debutMinutes;

    if (dureeMinutes >= 60) {
      final heures = dureeMinutes ~/ 60;
      final minutes = dureeMinutes % 60;
      if (minutes == 0) {
        return '${heures}h';
      } else {
        return '${heures}h${minutes.toString().padLeft(2, '0')}';
      }
    } else {
      return '${dureeMinutes}min';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Couleurs.primaire.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.schedule, color: Couleurs.primaire),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Définir un créneau',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sélection des heures
            Row(
              children: [
                // Heure de début
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Début',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(context, true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Couleurs.primaire),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Couleurs.primaire,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTimeOfDay(_debut),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Couleurs.primaire,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Séparateur
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: const Icon(Icons.arrow_forward, color: Colors.grey),
                ),

                const SizedBox(width: 16),

                // Heure de fin
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fin',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(context, false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Couleurs.secondaire),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Couleurs.secondaire,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTimeOfDay(_fin),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Couleurs.secondaire,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Affichage de la durée
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Durée: ${_getDuree()}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final debutMinutes = _debut.hour * 60 + _debut.minute;
                      final finMinutes = _fin.hour * 60 + _fin.minute;

                      if (finMinutes <= debutMinutes) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'L\'heure de fin doit être après l\'heure de début',
                            ),
                            backgroundColor: Couleurs.erreur,
                          ),
                        );
                        return;
                      }

                      final creneau = TimeSlot(debut: _debut, fin: _fin);
                      widget.onSave(creneau);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Couleurs.primaire,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Enregistrer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
