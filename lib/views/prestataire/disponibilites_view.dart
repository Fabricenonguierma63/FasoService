import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:developer' as dev;
import 'package:intl/intl.dart';
import '../../models/time_slot.dart';
import 'package:provider/provider.dart';
import '../../configs/themes.dart';
import '../../services/base_donnees_service.dart';
import '../../viewmodels/prestataire_viewmodel.dart';
import 'dart:ui';

class DisponibilitesView extends StatefulWidget {
  const DisponibilitesView({super.key});

  @override
  State<DisponibilitesView> createState() => _DisponibilitesViewState();
}

class _DisponibilitesViewState extends State<DisponibilitesView>
    with TickerProviderStateMixin {
  final BaseDonneesService _bdService = BaseDonneesService();
  late PrestataireViewModel _prestataireViewModel;

  // Calendrier et variables de dates
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  // Disponibilités
  late Map<DateTime, List<TimeSlot>> _disponibilites;
  late Map<DateTime, bool> _joursDisponibles;

  // Chargement
  bool _chargement = true;
  bool _donneesInitialisees = false;

  // Animations
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _disponibilites = {};
    _joursDisponibles = {};

    // Initialisation des animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.bounceOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prestataireViewModel = Provider.of<PrestataireViewModel>(context);
    // Appeler _initialiserDonnees() seulement si les données n'ont pas encore été chargées
    if (!_donneesInitialisees) {
      _donneesInitialisees = true;
      _initialiserDonnees();
    }
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

        // Démarrer les animations
        _fadeController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        _slideController.forward();
        await Future.delayed(const Duration(milliseconds: 100));
        _scaleController.forward();
      } else {
        _showErrorSnackBar('Erreur: Prestataire non trouvé');
        setState(() {
          _chargement = false;
        });
      }
    } catch (e) {
      dev.log('Erreur lors du chargement des disponibilités: $e');
      _showErrorSnackBar('Erreur lors du chargement des disponibilités');
      setState(() {
        _chargement = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _enregistrerDisponibilites(
    DateTime jour,
    List<TimeSlot> creneaux,
  ) async {
    try {
      final prestataire = _prestataireViewModel.prestataire;

      if (prestataire != null) {
        setState(() {
          _chargement = true;
        });

        await _bdService.setDisponibilites(prestataire.id, jour, creneaux);

        setState(() {
          final jourKey = DateTime(jour.year, jour.month, jour.day);
          _disponibilites[jourKey] = creneaux;
          _joursDisponibles[jourKey] = creneaux.isNotEmpty;
          _chargement = false;
        });

        _showSuccessSnackBar('Disponibilités enregistrées avec succès');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'enregistrement des disponibilités: $e');
      }
      _showErrorSnackBar('Erreur lors de l\'enregistrement des disponibilités');
      setState(() {
        _chargement = false;
      });
    }
  }

  void _ajouterCreneau() {
    final jourKey = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    List<TimeSlot> creneauxDuJour = _disponibilites[jourKey] ?? [];

    TimeSlot nouveauCreneau = TimeSlot(
      debut: const TimeOfDay(hour: 8, minute: 0),
      fin: const TimeOfDay(hour: 9, minute: 0),
    );

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return TimeSlotDialog(
          timeSlot: nouveauCreneau,
          onSave: (TimeSlot creneau) {
            creneauxDuJour.add(creneau);
            creneauxDuJour.sort((a, b) {
              int aMinutes = a.debut.hour * 60 + a.debut.minute;
              int bMinutes = b.debut.hour * 60 + b.debut.minute;
              return aMinutes.compareTo(bMinutes);
            });
            _enregistrerDisponibilites(jourKey, creneauxDuJour);
          },
        );
      },
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
      TimeSlot creneauExistant = creneauxDuJour[index];

      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.7),
        builder: (BuildContext context) {
          return TimeSlotDialog(
            timeSlot: creneauExistant,
            onSave: (TimeSlot creneauModifie) {
              creneauxDuJour[index] = creneauModifie;
              creneauxDuJour.sort((a, b) {
                int aMinutes = a.debut.hour * 60 + a.debut.minute;
                int bMinutes = b.debut.hour * 60 + b.debut.minute;
                return aMinutes.compareTo(bMinutes);
              });
              _enregistrerDisponibilites(jourKey, creneauxDuJour);
            },
          );
        },
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
      // Animation de suppression
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              const Text('Confirmation'),
            ],
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer ce créneau ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                creneauxDuJour.removeAt(index);
                _enregistrerDisponibilites(jourKey, creneauxDuJour);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
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
        _enregistrerDisponibilites(jourKey, [
          TimeSlot(
            debut: const TimeOfDay(hour: 8, minute: 0),
            fin: const TimeOfDay(hour: 17, minute: 0),
          ),
        ]);
      } else {
        _joursDisponibles[jourKey] = true;
      }
    } else {
      _enregistrerDisponibilites(jourKey, []);
      _joursDisponibles[jourKey] = false;
    }
  }

  Widget _buildGradientAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Couleurs.primaire,
              Couleurs.primaire.withOpacity(0.8),
              Couleurs.secondaire.withOpacity(0.6),
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          title: Text(
            'Mes Disponibilités',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                  color: Colors.black.withOpacity(0.3),
                ),
              ],
            ),
          ),
          centerTitle: true,
        ),
      ),
    );
  }

  Widget _buildModernCalendar() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Couleurs.primaire,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: Couleurs.primaire,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Couleurs.primaire,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: Colors.grey.shade600),
              selectedDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Couleurs.primaire, Couleurs.secondaire],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Couleurs.primaire.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              todayDecoration: BoxDecoration(
                color: Couleurs.primaire.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
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
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Couleurs.secondaire, Colors.green.shade400],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Couleurs.secondaire.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
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
    );
  }

  Widget _buildAvailabilitySection() {
    final jourKey = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final creneauxJourSelectionne = _disponibilites[jourKey] ?? [];
    final estJourDisponible = _joursDisponibles[jourKey] ?? false;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Couleurs.primaire.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.calendar_today, color: Couleurs.primaire),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disponibilité',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'EEEE dd MMMM yyyy',
                            'fr_FR',
                          ).format(_selectedDay),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 1.2,
                    child: Switch(
                      value: estJourDisponible,
                      onChanged: _changerDisponibiliteJour,
                      activeColor: Couleurs.primaire,
                      activeTrackColor: Couleurs.primaire.withOpacity(0.3),
                    ),
                  ),
                ],
              ),

              if (estJourDisponible) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Couleurs.secondaire,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Créneaux horaires',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (creneauxJourSelectionne.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Colors.grey.shade400,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aucun créneau défini',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),

                ...List.generate(creneauxJourSelectionne.length, (index) {
                  final creneau = creneauxJourSelectionne[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Couleurs.primaire.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.schedule,
                          color: Couleurs.primaire,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${_formatTimeOfDay(creneau.debut)} - ${_formatTimeOfDay(creneau.fin)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Durée: ${_calculateDuration(creneau.debut, creneau.fin)}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit_rounded,
                              color: Couleurs.secondaire,
                            ),
                            onPressed: () => _modifierCreneau(index),
                            style: IconButton.styleFrom(
                              backgroundColor: Couleurs.secondaire.withOpacity(
                                0.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(
                              Icons.delete_rounded,
                              color: Colors.red.shade600,
                            ),
                            onPressed: () => _supprimerCreneau(index),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _ajouterCreneau,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        'Ajouter un créneau',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Couleurs.secondaire,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _calculateDuration(TimeOfDay debut, TimeOfDay fin) {
    final debutMinutes = debut.hour * 60 + debut.minute;
    final finMinutes = fin.hour * 60 + fin.minute;
    final durationMinutes = finMinutes - debutMinutes;

    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _chargement
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Couleurs.primaire.withOpacity(0.1), Colors.white],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircularProgressIndicator(
                        color: Couleurs.primaire,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Chargement de vos disponibilités...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                _buildGradientAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildModernCalendar(),
                      _buildAvailabilitySection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// Dialog modernisé pour ajouter/modifier un créneau horaire
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

class TimeSlotDialogState extends State<TimeSlotDialog>
    with SingleTickerProviderStateMixin {
  late TimeOfDay _debut;
  late TimeOfDay _fin;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _debut = widget.timeSlot.debut;
    _fin = widget.timeSlot.fin;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isDebut) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isDebut ? _debut : _fin,
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Couleurs.primaire,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.grey.shade800,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header avec gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Couleurs.primaire, Couleurs.secondaire],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Créneau horaire',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenu
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Sélection heure de début
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Couleurs.primaire.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Couleurs.primaire,
                              size: 20,
                            ),
                          ),
                          title: const Text(
                            'Heure de début',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            _formatTimeOfDay(_debut),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Couleurs.primaire,
                            ),
                          ),
                          onTap: () => _selectTime(context, true),
                          trailing: Icon(
                            Icons.keyboard_arrow_right,
                            color: Couleurs.primaire,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Sélection heure de fin
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Couleurs.secondaire.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.stop_rounded,
                              color: Couleurs.secondaire,
                              size: 20,
                            ),
                          ),
                          title: const Text(
                            'Heure de fin',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            _formatTimeOfDay(_fin),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Couleurs.secondaire,
                            ),
                          ),
                          onTap: () => _selectTime(context, false),
                          trailing: Icon(
                            Icons.keyboard_arrow_right,
                            color: Couleurs.secondaire,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Durée calculée
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade50,
                              Colors.blue.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: Colors.purple.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Durée: ${_calculateDuration(_debut, _fin)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final debutMinutes =
                                _debut.hour * 60 + _debut.minute;
                            final finMinutes = _fin.hour * 60 + _fin.minute;

                            if (finMinutes <= debutMinutes) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'L\'heure de fin doit être après l\'heure de début',
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Enregistrer',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _calculateDuration(TimeOfDay debut, TimeOfDay fin) {
    final debutMinutes = debut.hour * 60 + debut.minute;
    final finMinutes = fin.hour * 60 + fin.minute;
    final durationMinutes = finMinutes - debutMinutes;

    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }
}
