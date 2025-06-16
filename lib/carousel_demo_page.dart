import 'package:flutter/material.dart';

import 'ui/carousel/vuzix_carousel.dart';
import 'ui/carousel/vuzix_carousel_item.dart';
import 'ui/snackbar.dart';

class CarouselDemoPage extends StatelessWidget {
  const CarouselDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: null,
      // AppBar(
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //   title: Text('Flutter Vuzix Demo - Carousel'),
      // ),
      body: Column(
        children: [
          VuzixCarousel(items: [
            VuzixCarouselItem(
                title: "Home",
                icon: Icons.home,
                onSelected: () {
                  showSnackBar(
                    "Home selected",
                  );
                }),
            VuzixCarouselItem(
                title: "Work",
                icon: Icons.work,
                color: Colors.red,
                onSelected: () {
                  showSnackBar(
                    "no work for me",
                  );
                }),
            VuzixCarouselItem(
                title: "Phone",
                icon: Icons.phone,
                onSelected: () {
                  showSnackBar(
                    "ring ring",
                  );
                }),
            VuzixCarouselItem(
                title:
                    "Embarrassingly long text that goes over multiple lines if not broken or ellipsized correctly",
                icon: Icons.emoji_food_beverage_rounded,
                onSelected: () {
                  showSnackBar(
                    "Phone selected",
                  );
                }),
            VuzixCarouselItem(
                title: "Chat",
                icon: Icons.chat,
                color: Colors.blue,
                onSelected: () {
                  showSnackBar(
                    "Chat selected",
                  );
                }),
            VuzixCarouselItem(
                title: "Settings",
                icon: Icons.settings,
                onSelected: () {
                  showSnackBar(
                    "Settings selected",
                  );
                }),
            VuzixCarouselItem(
                title: "Reset device now",
                icon: Icons.reset_tv,
                color: Colors.amber,
                onSelected: () {
                  showSnackBar(
                    "...",
                  );
                }),
          ]),
        ],
      ),
    );
  }
}
