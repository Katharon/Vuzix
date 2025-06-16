import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class VuzixCarouselItem {
  final String title;
  final IconData icon;
  final Color? color;
  final void Function()? onSelected;

  VuzixCarouselItem({
    required this.title,
    required this.icon,
    this.color,
    this.onSelected,
  });

  Widget build(BuildContext context,
          {bool isSelected = false,
          bool showUnselectedOutline = false,
          double unselectedIconFactor = 0.6}) =>
      Padding(
        padding: const EdgeInsets.all(4),
        child: GestureDetector(
          onTap: onSelected,
          child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(builder: (context, constraint) {
              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3)
                      : showUnselectedOutline
                          ? Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1)
                          : null,
                  borderRadius: BorderRadius.circular(isSelected ? 10 : 8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: color,
                      size: constraint.maxWidth *
                          0.5 *
                          (isSelected ? 1.0 : unselectedIconFactor),
                    ),
                    Expanded(
                      child: Center(
                        child: AutoSizeText(
                          title,
                          minFontSize: (isSelected ? 18 : 12),
                          maxFontSize: 50,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: isSelected
                              ? Theme.of(context).textTheme.headlineMedium
                              : Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      );
}
