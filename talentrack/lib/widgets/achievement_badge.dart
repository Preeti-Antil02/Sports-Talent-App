import 'package:flutter/material.dart';

class AchievementBadge extends StatelessWidget {
  final String title;
  final String imageUrl;
  final bool isEarned;

  const AchievementBadge({
    super.key,
    required this.title,
    required this.imageUrl,
    this.isEarned = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isEarned
                  ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber,
                  Colors.orange,
                ],
              )
                  : null,
              color: isEarned ? null : Colors.grey.withValues(alpha: 0.3),
              boxShadow: isEarned
                  ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
                  : null,
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: Stack(
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: 64,
                      height: 64,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 64,
                          height: 64,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.military_tech_rounded,
                            size: 32,
                            color: isEarned
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                        );
                      },
                      color: isEarned ? null : Colors.grey.withValues(alpha: 0.5),
                      colorBlendMode: isEarned ? null : BlendMode.saturation,
                    ),
                    if (!isEarned)
                      Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey.withValues(alpha: 0.7),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isEarned
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}