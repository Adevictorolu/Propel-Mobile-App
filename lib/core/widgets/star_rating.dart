import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double iconSize;
  final bool isInteractive;
  final void Function(double)? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.iconSize = 18,
    this.isInteractive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData iconData;
        Color color;

        if (rating >= starValue) {
          iconData = Icons.star;
          color = const Color(0xFFF59E0B); // Amber
        } else if (rating >= starValue - 0.5) {
          iconData = Icons.star_half;
          color = const Color(0xFFF59E0B);
        } else {
          iconData = Icons.star_border;
          color = Colors.grey.shade400;
        }

        Widget star = Icon(iconData, size: iconSize, color: color);

        if (isInteractive && onRatingChanged != null) {
          return IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(width: iconSize + 4, height: iconSize + 4),
            icon: star,
            onPressed: () => onRatingChanged!(starValue.toDouble()),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: star,
        );
      }),
    );
  }
}
