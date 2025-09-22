import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talenttrack/models/user_model.dart';
import 'package:talenttrack/services/auth_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserModel? currentUser;
  List<UserModel> leaderboardUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboardData();
  }

  Future<void> _loadLeaderboardData() async {
    try {
      final user = await AuthService.getCurrentUser();
      setState(() {
        currentUser = user;
        leaderboardUsers = List.from(AuthService.demoUsers)
          ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

        // Add current user if not in demo users
        if (user != null && !leaderboardUsers.any((u) => u.id == user.id)) {
          leaderboardUsers.add(user);
          leaderboardUsers.sort((a, b) => b.totalScore.compareTo(a.totalScore));
        }
      });
    } catch (e) {
      debugPrint('Error loading leaderboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: const Text(
              'Leaderboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            floating: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Overall'),
                Tab(text: 'This Month'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLeaderboard(leaderboardUsers),
            _buildLeaderboard(leaderboardUsers), // Same data for demo
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard(List<UserModel> users) {
    if (users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Top 3 Podium with enhanced styling
        Container(
          height: 240,
          margin: const EdgeInsets.all(24),
          child: _buildPodium(users.take(3).toList()),
        ),

        // Rest of the leaderboard with improved spacing
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
            itemCount: users.length > 3 ? users.length - 3 : 0,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final user = users[index + 3];
              final rank = index + 4;
              final isCurrentUser = currentUser?.id == user.id;

              return Container(
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCurrentUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                    width: isCurrentUser ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                          Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            user.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isCurrentUser
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${user.badges.length} badges earned',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${user.totalScore}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(
                delay: Duration(milliseconds: index * 80),
                duration: 500.ms,
              ).slideX(begin: 0.3).then().shimmer(
                duration: 800.ms,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPodium(List<UserModel> topUsers) {
    if (topUsers.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background decoration
          Container(
            height: 20,
            margin: const EdgeInsets.only(bottom: 80),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Podium platforms with equal spacing
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd place
              if (topUsers.length > 1)
                Expanded(
                  child: _buildPodiumPlace(
                    topUsers[1],
                    2,
                    height: 140,
                    color: const Color(0xFFC0C0C0), // Silver
                  ).animate().slideY(begin: 1, duration: 800.ms, delay: 300.ms)
                      .then().shimmer(duration: 1000.ms, color: Colors.white.withValues(alpha: 0.5)),
                ),

              const SizedBox(width: 16),

              // 1st place
              Expanded(
                child: _buildPodiumPlace(
                  topUsers[0],
                  1,
                  height: 180,
                  color: const Color(0xFFFFD700), // Gold
                ).animate().slideY(begin: 1, duration: 800.ms)
                    .then().scale(duration: 500.ms, curve: Curves.easeInOut)
                    .then().shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.6)),
              ),

              const SizedBox(width: 16),

              // 3rd place
              if (topUsers.length > 2)
                Expanded(
                  child: _buildPodiumPlace(
                    topUsers[2],
                    3,
                    height: 120,
                    color: const Color(0xFFCD7F32), // Bronze
                  ).animate().slideY(begin: 1, duration: 800.ms, delay: 600.ms)
                      .then().shimmer(duration: 800.ms, color: Colors.white.withValues(alpha: 0.4)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(UserModel user, int place, {required double height, required Color color}) {
    final isCurrentUser = currentUser?.id == user.id;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Crown/Medal icon
        if (place == 1)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Icon(
              Icons.emoji_events_rounded,
              color: color,
              size: 32,
            ),
          )
        else
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Icon(
              place == 2 ? Icons.military_tech_rounded : Icons.workspace_premium_rounded,
              color: color,
              size: 28,
            ),
          ),

        // User avatar and info
        Column(
          children: [
            Container(
              width: place == 1 ? 70 : 60,
              height: place == 1 ? 70 : 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: place == 1 ? 28 : 24,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              user.name.split(' ')[0],
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                fontSize: place == 1 ? 16 : 14,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${user.totalScore}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Enhanced podium platform
        Container(
          width: place == 1 ? 100 : 85,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color,
                color.withValues(alpha: 0.8),
                color.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shine effect
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
              ),

              // Place number
              Center(
                child: Text(
                  '$place',
                  style: TextStyle(
                    fontSize: place == 1 ? 40 : 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}