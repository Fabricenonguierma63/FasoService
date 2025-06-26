import 'package:faso_services/views/prestataire/disponibilites.dart';
import 'package:faso_services/views/prestataire/gestion_services_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../configs/themes.dart';
import '../../configs/constants.dart';
import '../../models/reservation.dart';
import '../../models/service.dart';
import '../../viewmodels/prestataire_viewmodel.dart';
import '../../viewmodels/reservation_viewmodel.dart';

class TableauBordView extends StatefulWidget {
  const TableauBordView({super.key});

  @override
  State<TableauBordView> createState() => _TableauBordViewState();
}

class _TableauBordViewState extends State<TableauBordView>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _isLoading = true;
  final dateFormat = DateFormat(Constants.formatDate);
  late AnimationController _greetingAnimationController;
  late Animation<double> _greetingAnimation;
  late AnimationController _cardAnimationController;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _chargerDonnees();
  }

  void _initAnimations() {
    _greetingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _greetingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _greetingAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _greetingAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardAnimationController.forward();
    });
  }

  Future<void> _chargerDonnees() async {
    setState(() {
      _isLoading = true;
    });

    final prestataireViewModel = Provider.of<PrestataireViewModel>(
      context,
      listen: false,
    );
    await prestataireViewModel.chargerMesServices();

    if (!mounted) return;
    final reservationViewModel = Provider.of<ReservationViewModel>(
      context,
      listen: false,
    );
    await reservationViewModel.chargerReservationsPrestataire();

    setState(() {
      _isLoading = false;
    });
  }

  String _getSalutation() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Bonjour ! ☀️";
    if (hour < 17) return "Bon après-midi ! 🌤️";
    return "Bonsoir ! 🌙";
  }

  @override
  void dispose() {
    _pageController.dispose();
    _greetingAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profil');
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: [
          _isLoading ? _buildLoadingView() : _buildDashboardContent(),
          const GestionServicesView(),
          const DisponibilitesView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.jumpToPage(index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tableau',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.design_services),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Disponibilités',
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(color: Couleurs.primaire),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _chargerDonnees,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernGreeting(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatisticsCards(),
                  const SizedBox(height: 24),
                  _buildChartSection(),
                  const SizedBox(height: 24),
                  _buildRecentReservations(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernGreeting() {
    return AnimatedBuilder(
      animation: _greetingAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _greetingAnimation.value,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Couleurs.primaire,
                  Couleurs.primaire.withOpacity(0.8),
                  Couleurs.accent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Couleurs.primaire.withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSalutation(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Couleurs.blanc,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Prêt à gérer vos services aujourd'hui ?",
                  style: TextStyle(
                    fontSize: 16,
                    color: Couleurs.blanc.withOpacity(0.9),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Couleurs.blanc.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: Couleurs.blanc,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Performance",
                            style: TextStyle(
                              color: Couleurs.blanc.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Couleurs.blanc.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Couleurs.blanc,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Excellence",
                            style: TextStyle(
                              color: Couleurs.blanc.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
        );
      },
    );
  }

  Widget _buildStatisticsCards() {
    final reservationViewModel = Provider.of<ReservationViewModel>(context);
    final prestataireViewModel = Provider.of<PrestataireViewModel>(context);

    final totalReservations = reservationViewModel.reservationsRecues.length;
    final reservationsEnAttente = reservationViewModel.reservationsRecues
        .where((r) => r.statut == StatutReservation.enAttente)
        .length;
    final totalServices = prestataireViewModel.mesServices?.length ?? 0;

    double revenuTotal =
        reservationViewModel.reservationsRecues
            .where(
              (r) =>
                  r.statut == StatutReservation.confirmee ||
                  r.statut == StatutReservation.terminee,
            )
            .fold(0, (sum, r) => sum! + r.montant) ??
        0;

    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardAnimation.value)),
          child: Opacity(
            opacity: _cardAnimation.value,
            child: Column(
              children: [
                Row(
                  children: [
                    _buildEnhancedStatCard(
                      title: 'Réservations',
                      value: totalReservations.toString(),
                      icon: Icons.calendar_month,
                      color: Couleurs.primaire,
                      gradient: [Couleurs.primaire, Couleurs.accent],
                    ),
                    const SizedBox(width: 16),
                    _buildEnhancedStatCard(
                      title: 'En attente',
                      value: reservationsEnAttente.toString(),
                      icon: Icons.pending_actions,
                      color: Colors.amber,
                      gradient: [Colors.amber, Colors.amber.shade300],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildEnhancedStatCard(
                      title: 'Services',
                      value: totalServices.toString(),
                      icon: Icons.home_repair_service,
                      color: Couleurs.secondaire,
                      gradient: [
                        Couleurs.secondaire,
                        Couleurs.secondaire.withOpacity(0.7),
                      ],
                    ),
                    const SizedBox(width: 16),
                    _buildEnhancedStatCard(
                      title: 'Revenus',
                      value: '${revenuTotal.toInt()} FCFA',
                      icon: Icons.payments,
                      color: Colors.green,
                      gradient: [Colors.green, Colors.green.shade300],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Couleurs.blanc, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.trending_up, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: Couleurs.texteSecondaire,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    final reservationViewModel = Provider.of<ReservationViewModel>(context);

    if (reservationViewModel.reservationsRecues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Couleurs.texteSecondaire.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée disponible',
              style: TextStyle(
                color: Couleurs.texteSecondaire,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    int enAttente = 0;
    int confirmees = 0;
    int terminees = 0;
    int annulees = 0;

    for (var r in reservationViewModel.reservationsRecues) {
      switch (r.statut) {
        case StatutReservation.enAttente:
          enAttente++;
          break;
        case StatutReservation.confirmee:
          confirmees++;
          break;
        case StatutReservation.terminee:
          terminees++;
          break;
        case StatutReservation.annulee:
          annulees++;
          break;
      }
    }

    final data = [enAttente, confirmees, terminees, annulees];
    final labels = ['En attente', 'Confirmées', 'Terminées', 'Annulées'];
    final colors = [
      Colors.amber,
      Couleurs.primaire,
      Couleurs.secondaire,
      Couleurs.erreur,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Couleurs.primaire.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics,
                    color: Couleurs.primaire,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Analyse des réservations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.isNotEmpty
                      ? data
                                .map((e) => e.toDouble())
                                .reduce((a, b) => a > b ? a : b) +
                            1
                      : 1,
                  barGroups: List.generate(data.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data[index].toDouble(),
                          width: 20,
                          color: colors[index],
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [
                              colors[index],
                              colors[index].withOpacity(0.7),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[value.toInt()],
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReservations() {
    final reservationViewModel = Provider.of<ReservationViewModel>(context);
    final reservations = reservationViewModel.reservationsRecues;

    final recentReservations = reservations.length > 5
        ? reservations.sublist(0, 5)
        : reservations;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Couleurs.secondaire.withAlpha(
                            25,
                          ), // 0.1 * 255 ≈ 25
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.history,
                          color: Couleurs.secondaire,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Flexible(
                        child: Text(
                          'Réservations récentes',
                          overflow: TextOverflow
                              .ellipsis, // pour éviter tout débordement
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/demandes');
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Voir tout'),
                  style: TextButton.styleFrom(
                    foregroundColor: Couleurs.primaire,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            recentReservations.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 48,
                            color: Couleurs.texteSecondaire.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune réservation pour le moment',
                            style: TextStyle(
                              color: Couleurs.texteSecondaire,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentReservations.length,
                    itemBuilder: (context, index) {
                      final reservation = recentReservations[index];
                      return FutureBuilder<Service?>(
                        future: reservationViewModel
                            .obtenirServicePourReservation(
                              reservation.serviceId,
                            ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Couleurs.primaire,
                                  ),
                                  SizedBox(width: 16),
                                  Text('Chargement...'),
                                ],
                              ),
                            );
                          }

                          final service = snapshot.data;
                          // ignore: unused_local_variable
                          final dateFormattee = dateFormat.format(
                            reservation.dateService,
                          );

                          Color statutColor;
                          IconData statutIcon;

                          switch (reservation.statut) {
                            case StatutReservation.enAttente:
                              statutColor = Colors.amber;
                              statutIcon = Icons.pending_actions;
                              break;
                            case StatutReservation.confirmee:
                              statutColor = Couleurs.primaire;
                              statutIcon = Icons.check_circle;
                              break;
                            case StatutReservation.terminee:
                              statutColor = Couleurs.secondaire;
                              statutIcon = Icons.done_all;
                              break;
                            case StatutReservation.annulee:
                              statutColor = Couleurs.erreur;
                              statutIcon = Icons.cancel;
                              break;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statutColor.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: statutColor.withOpacity(0.1),
                                  spreadRadius: 0,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                service?.titre ?? 'Service inconnu',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),

                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      statutColor,
                                      statutColor.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  statutIcon,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              trailing:
                                  reservation.statut ==
                                      StatutReservation.enAttente
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Couleurs.succes.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.check,
                                              color: Couleurs.succes,
                                            ),
                                            onPressed: () {
                                              _confirmerReservation(
                                                reservation.id,
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Couleurs.erreur.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: Couleurs.erreur,
                                            ),
                                            onPressed: () {
                                              _annulerReservation(
                                                reservation.id,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                              onTap: () {
                                Navigator.pushNamed(context, '/demandes');
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmerReservation(String reservationId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Couleurs.succes.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: Couleurs.succes),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirmer la réservation',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ],
        ),
        content: const Text(
          'Voulez-vous confirmer cette réservation ?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Couleurs.succes,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final reservationViewModel = Provider.of<ReservationViewModel>(
                context,
                listen: false,
              );

              await reservationViewModel.mettreAJourStatutReservation(
                reservationId,
                StatutReservation.confirmee,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Réservation confirmée'),
                    ],
                  ),
                  backgroundColor: Couleurs.succes,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _annulerReservation(String reservationId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Couleurs.erreur.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cancel, color: Couleurs.erreur),
            ),
            const SizedBox(width: 12),
            const Text(
              'Annuler la réservation',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ],
        ),
        content: const Text(
          'Voulez-vous annuler cette réservation ?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Revenir'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Couleurs.erreur,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final reservationViewModel = Provider.of<ReservationViewModel>(
                context,
                listen: false,
              );

              await reservationViewModel.mettreAJourStatutReservation(
                reservationId,
                StatutReservation.annulee,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Réservation annulée'),
                    ],
                  ),
                  backgroundColor: Couleurs.erreur,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}
