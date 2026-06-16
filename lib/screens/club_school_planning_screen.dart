import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/course_provider_complete.dart';
import '../models/session_schedule_model.dart';
import 'create_course_screen.dart';
import 'course_details_screen.dart';

class ClubSchoolPlanningScreen extends StatefulWidget {
  const ClubSchoolPlanningScreen({super.key});

  @override
  State<ClubSchoolPlanningScreen> createState() => _ClubSchoolPlanningScreenState();
}

class _ClubSchoolPlanningScreenState extends State<ClubSchoolPlanningScreen> {
  static const int START_HOUR = 8;
  static const int END_HOUR = 20;
  static const int TOTAL_HOURS = END_HOUR - START_HOUR;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ScheduleProvider>().loadWeeklySchedule();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    final schedule = provider.weeklySchedule;
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme, provider, isDesktop),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildScheduleGrid(schedule, theme, screenSize, isDesktop),
      floatingActionButton: _buildFAB(theme),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, ScheduleProvider provider, bool isDesktop) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        isDesktop ? 'Planning Club & School' : 'Planning',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
          fontSize: isDesktop ? 24 : 20,
        ),
      ),
      actions: [
        if (isDesktop)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(theme, 'Tous', true),
                const SizedBox(width: 8),
                _buildFilterChip(theme, 'Cours', false),
                const SizedBox(width: 8),
                _buildFilterChip(theme, 'Ateliers', false),
              ],
            ),
          ),
        IconButton(
          icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
          onPressed: () => provider.loadWeeklySchedule(),
        ),
        IconButton(
          icon: Icon(Icons.filter_list, color: theme.colorScheme.primary),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildFilterChip(ThemeData theme, String label, bool selected) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) {},
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildFAB(ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: () {},
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      icon: const Icon(Icons.add),
      label: const Text('Nouvelle séance'),
      elevation: 4,
    );
  }

  Widget _buildScheduleGrid(
      Map<DayOfWeek, List<SessionSchedule>> schedule,
      ThemeData theme,
      Size screenSize,
      bool isDesktop,
      ) {
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 900;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcul des dimensions adaptatives
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Dimensions pour desktop
        double dayWidth, hourHeight, headerHeight;
        bool showVerticalDays = isMobile || isTablet;

        if (isDesktop) {
          // Desktop : Occupe toute la largeur
          dayWidth = (availableWidth - 60) / 7; // -60 pour l'espace des heures
          hourHeight = (availableHeight - 100) / TOTAL_HOURS;
          hourHeight = hourHeight.clamp(40.0, 80.0);
          headerHeight = 60.0;
        } else if (isTablet) {
          // Tablette : Largeur adaptative
          dayWidth = (availableWidth - 40) / 5; // 5 jours affichés à la fois
          hourHeight = 65.0;
          headerHeight = 50.0;
        } else {
          // Mobile : Optimisé pour petit écran
          dayWidth = (availableWidth - 30) / 4; // 4 jours affichés
          hourHeight = 55.0;
          headerHeight = 45.0;
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 16.0 : 8.0),
              child: Card(
                elevation: isDesktop ? 4 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: showVerticalDays
                        ? _buildMobileLayout(
                      schedule,
                      theme,
                      dayWidth,
                      hourHeight,
                      headerHeight,
                      isDesktop,
                      availableWidth,
                    )
                        : _buildDesktopLayout(
                      schedule,
                      theme,
                      dayWidth,
                      hourHeight,
                      headerHeight,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // LAYOUT DESKTOP - Grille horizontale classique avec sessions superposées
  Widget _buildDesktopLayout(
      Map<DayOfWeek, List<SessionSchedule>> schedule,
      ThemeData theme,
      double dayWidth,
      double hourHeight,
      double headerHeight,
      ) {
    final days = DayOfWeek.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec les jours
        _buildHeaderRow(days, theme, dayWidth, headerHeight, false),

        // Utilisation d'un Stack pour permettre aux sessions de dépasser les cellules
        Stack(
          children: [
            // 1. Grille de fond (Heures et lignes)
            Column(
              children: List.generate(TOTAL_HOURS, (hourIndex) {
                final hour = START_HOUR + hourIndex;
                return _buildHourRow(
                  hour,
                  days,
                  {}, // On passe une map vide pour la grille de fond
                  theme,
                  dayWidth,
                  hourHeight,
                  false,
                );
              }),
            ),

            // 2. Calque des sessions (Overlay)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(left: 60), // Alignement avec la colonne des heures
                child: Row(
                  children: days.map((day) {
                    final daySessions = schedule[day] ?? [];
                    return SizedBox(
                      width: dayWidth,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: daySessions.map((session) {
                          return _buildPositionedSession(
                            session,
                            theme,
                            dayWidth,
                            hourHeight,
                            daySessions,
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Positionnement précis d'une session sur la grille
  Widget _buildPositionedSession(
      SessionSchedule session,
      ThemeData theme,
      double dayWidth,
      double hourHeight,
      List<SessionSchedule> daySessions,
      ) {
    // Calcul de la position top par rapport au début de la grille
    final startMinutes = (session.timeSlot.start.hour - START_HOUR) * 60 + session.timeSlot.start.minute;
    final top = (startMinutes / 60.0) * hourHeight;

    // Calcul de la hauteur totale selon la durée
    final durationMinutes = (session.timeSlot.end.hour * 60 + session.timeSlot.end.minute) -
        (session.timeSlot.start.hour * 60 + session.timeSlot.start.minute);
    final height = (durationMinutes / 60.0) * hourHeight;

    final isContinuing = _isSessionContinuing(session, daySessions);

    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: height,
      child: GestureDetector(
        onTap: () => _showSessionDetails(session),
        child: _buildSessionBar(
          session,
          theme,
          dayWidth,
          height,
          isContinuing,
          false,
        ),
      ),
    );
  }

  // LAYOUT MOBILE - Jours en vertical
  Widget _buildMobileLayout(
      Map<DayOfWeek, List<SessionSchedule>> schedule,
      ThemeData theme,
      double dayWidth,
      double hourHeight,
      double headerHeight,
      bool isDesktop,
      double availableWidth,
      ) {
    final days = DayOfWeek.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: days.map((day) {
        final daySessions = schedule[day] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du jour
            Container(
              width: availableWidth,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getDayIcon(day),
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    day.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${daySessions.length} séances',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sessions du jour
            Container(
              width: availableWidth,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: daySessions.isEmpty
                    ? [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Aucune séance',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  )
                ]
                    : daySessions.map((session) => GestureDetector(
                  onTap: () => _showSessionDetails(session),
                  child: _buildMobileSessionCard(
                    session,
                    theme,
                    daySessions,
                    hourHeight,
                  ),
                )).toList(),
              ),
            ),

            // Séparateur entre jours
            if (day != days.last)
              Divider(
                height: 8,
                thickness: 2,
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
          ],
        );
      }).toList(),
    );
  }

  IconData _getDayIcon(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.monday:
        return FontAwesomeIcons.calendar.data;

      case DayOfWeek.tuesday:
        return FontAwesomeIcons.calendar.data;
      case DayOfWeek.wednesday:
        return FontAwesomeIcons.calendar.data;
      case DayOfWeek.thursday:
        return FontAwesomeIcons.calendar.data;
      case DayOfWeek.friday:
        return FontAwesomeIcons.calendar.data;
      case DayOfWeek.saturday:
        return FontAwesomeIcons.calendar.data;
      case DayOfWeek.sunday:
        return FontAwesomeIcons.calendar.data;
    }
  }

  Widget _buildMobileSessionCard(
      SessionSchedule session,
      ThemeData theme,
      List<SessionSchedule> daySessions,
      double hourHeight,
      ) {
    final colorIndex = session.courseId.hashCode.abs() % 5;
    final List<Color> colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.pink,
    ];
    final baseColor = colors[colorIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withValues(alpha: 0.15),
            baseColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Horaire
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  _formatTimeOfDay(session.timeSlot.start),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: baseColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '→',
                  style: TextStyle(color: baseColor.withValues(alpha: 0.5), fontSize: 10),
                ),
                Text(
                  _formatTimeOfDay(session.timeSlot.end),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: baseColor.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Détails du cours
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.courseTitle ?? "Cours ${session.courseId.substring(0, 8)}",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (session.roomName != null)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        session.roomName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                if (session.coachId != null)
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        session.coachId!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Indicateur de durée
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${session.timeSlot.end.hour - session.timeSlot.start.hour}h',
              style: theme.textTheme.labelSmall?.copyWith(
                color: baseColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Composants partagés pour le layout desktop
  Widget _buildHeaderRow(
      List<DayOfWeek> days,
      ThemeData theme,
      double dayWidth,
      double height,
      bool isMobile,
      ) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Coin vide pour alignement
          Container(
            width: 60,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
          ),
          // Jours de la semaine
          ...days.map((day) => Container(
            width: dayWidth,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.displayName.split(' ')[0],
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                    fontSize: 14,
                  ),
                ),
                Text(
                  day.displayName.split(' ').sublist(1).join(' '),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHourRow(
      int hour,
      List<DayOfWeek> days,
      Map<DayOfWeek, List<SessionSchedule>> schedule,
      ThemeData theme,
      double dayWidth,
      double height,
      bool isMobile,
      ) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Affichage de l'heure
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Cellules de fond pour chaque jour
          ...days.map((day) {
            return _buildDayCell(
              hour,
              [],
              [],
              theme,
              dayWidth,
              height,
              isMobile,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayCell(
      int hour,
      List<SessionSchedule> daySessions,
      List<SessionSchedule> hourSessions,
      ThemeData theme,
      double width,
      double height,
      bool isMobile,
      ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: hour % 2 == 0
            ? theme.colorScheme.surface
            : theme.colorScheme.surface.withValues(alpha: 0.02),
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
    );
  }

  bool _isSessionContinuing(SessionSchedule current, List<SessionSchedule> allSessions) {
    return allSessions.any((s) =>
    s.courseId == current.courseId &&
        s.timeSlot.start.hour == current.timeSlot.start.hour + 1 &&
        s.timeSlot.start.minute == current.timeSlot.start.minute
    );
  }

  Widget _buildSessionBar(
      SessionSchedule session,
      ThemeData theme,
      double width,
      double height,
      bool isContinuing,
      bool isMobile,
      ) {
    final colorIndex = session.courseId.hashCode.abs() % 5;
    final List<Color> colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.pink,
    ];
    final baseColor = colors[colorIndex];

    return Container(
      width: width - 8,
      height: height - 2,
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withValues(alpha: 0.85),
            baseColor.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: isContinuing
            ? const BorderRadius.vertical(
                top: Radius.circular(8),
                bottom: Radius.circular(2),
              )
            : BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 2 : 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: height < 30 ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Text(
              session.courseTitle ?? "Cours",
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: isMobile ? 8 : 11,
                height: 1.2,
              ),
              maxLines: height < 40 ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (height > 40 && !isMobile && session.roomName != null)
              Text(
                session.roomName!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  void _showSessionDetails(SessionSchedule session) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(session.courseTitle ?? 'Détails de la séance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem(Icons.access_time, 'Horaire', '${_formatTimeOfDay(session.timeSlot.start)} - ${_formatTimeOfDay(session.timeSlot.end)}'),
            if (session.roomName != null)
              _buildDetailItem(Icons.room, 'Salle', session.roomName!),
            if (session.coachId != null)
              _buildDetailItem(Icons.person, 'Coach', session.coachId!),
            _buildDetailItem(Icons.calendar_today, 'Jour', session.dayOfWeek.displayName),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final courseProvider = context.read<CourseProvider>();
              
              // On ferme le dialogue d'abord
              navigator.pop();
              
              await courseProvider.loadCourseById(session.courseId);
              
              if (courseProvider.selectedCourse != null && mounted) {
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseDetailsScreen(course: courseProvider.selectedCourse!),
                  ),
                );
              }
            },
            icon: const Icon(Icons.info_outline),
            label: const Text('Détails'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final courseProvider = context.read<CourseProvider>();
              
              navigator.pop();
              
              await courseProvider.loadCourseById(session.courseId);
              
              if (courseProvider.selectedCourse != null && mounted) {
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateCourseScreen(courseToEdit: courseProvider.selectedCourse),
                  ),
                );
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Modifier'),
          ),
          IconButton(
            onPressed: () => _confirmDelete(session),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(SessionSchedule session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Voulez-vous vraiment supprimer cette séance ou ce cours ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Fermer confirm
              Navigator.pop(context); // Fermer détails
              
              final courseProvider = context.read<CourseProvider>();
              bool success;
              
              if (session.id.startsWith('course-')) {
                // C'est un cours avec planning intégré
                success = await courseProvider.deleteCourse(session.courseId);
              } else {
                // C'est une session individuelle
                success = await courseProvider.deleteSchedule(session.id);
              }

              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Supprimé avec succès')),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text('$label : ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
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