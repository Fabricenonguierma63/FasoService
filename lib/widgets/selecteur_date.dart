import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../configs/themes.dart';
import '../configs/constants.dart';

class SelecteurDate extends StatefulWidget {
  final DateTime? dateInitiale;
  final DateTime? dateMinimale;
  final DateTime? dateMaximale;
  final Function(DateTime) onDateChanged;
  final String labelText;
  final String? hintText;
  final bool afficherHeure;
  final TimeOfDay? heureInitiale;
  final Function(TimeOfDay)? onTimeChanged;

  const SelecteurDate({
    super.key,
    this.dateInitiale,
    this.dateMinimale,
    this.dateMaximale,
    required this.onDateChanged,
    required this.labelText,
    this.hintText,
    this.afficherHeure = false,
    this.heureInitiale,
    this.onTimeChanged,
  });

  @override
  State<SelecteurDate> createState() => _SelecteurDateState();
}

class _SelecteurDateState extends State<SelecteurDate> {
  late DateTime _dateSelectionnee;
  late TimeOfDay _heureSelectionnee;
  final TextEditingController _controllerDate = TextEditingController();
  final TextEditingController _controllerHeure = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateSelectionnee = widget.dateInitiale ?? DateTime.now();
    _heureSelectionnee = widget.heureInitiale ?? TimeOfDay.now();
    _mettreAJourTextController();
  }

  void _mettreAJourTextController() {
    // Format de la date selon les constantes
    _controllerDate.text = DateFormat(
      Constants.formatDate,
    ).format(_dateSelectionnee);

    if (widget.afficherHeure) {
      final String heureFormatee = _heureSelectionnee.format(context);
      _controllerHeure.text = heureFormatee;
    }
  }

  Future<void> _selectionnerDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateSelectionnee,
      firstDate: widget.dateMinimale ?? DateTime.now(),
      lastDate:
          widget.dateMaximale ?? DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Couleurs.primaire,
              onPrimary: Couleurs.blanc,
              onSurface: Couleurs.texte,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Couleurs.secondaire),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _dateSelectionnee) {
      setState(() {
        _dateSelectionnee = pickedDate;
        _mettreAJourTextController();
      });
      widget.onDateChanged(_dateSelectionnee);
    }
  }

  Future<void> _selectionnerHeure(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _heureSelectionnee,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Couleurs.primaire,
              onPrimary: Couleurs.blanc,
              onSurface: Couleurs.texte,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Couleurs.secondaire),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && pickedTime != _heureSelectionnee) {
      setState(() {
        _heureSelectionnee = pickedTime;
        _mettreAJourTextController();
      });
      if (widget.onTimeChanged != null) {
        widget.onTimeChanged!(_heureSelectionnee);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Couleurs.texte,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: widget.afficherHeure ? 3 : 1,
              child: TextField(
                controller: _controllerDate,
                readOnly: true,
                onTap: () => _selectionnerDate(context),
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Sélectionner une date',
                  prefixIcon: const Icon(
                    Icons.calendar_today,
                    color: Couleurs.secondaire,
                  ),
                  suffixIcon: const Icon(
                    Icons.arrow_drop_down,
                    color: Couleurs.texteSecondaire,
                  ),
                ),
              ),
            ),
            if (widget.afficherHeure) ...[
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _controllerHeure,
                  readOnly: true,
                  onTap: () => _selectionnerHeure(context),
                  decoration: InputDecoration(
                    hintText: 'Heure',
                    prefixIcon: const Icon(
                      Icons.access_time,
                      color: Couleurs.secondaire,
                    ),
                    suffixIcon: const Icon(
                      Icons.arrow_drop_down,
                      color: Couleurs.texteSecondaire,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controllerDate.dispose();
    _controllerHeure.dispose();
    super.dispose();
  }
}
