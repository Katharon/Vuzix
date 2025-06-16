import 'package:carousel_slider/carousel_slider.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../input/device.dart';
import '../../input/input_event.dart';
import '../../main.dart';
import 'vuzix_carousel_item.dart';

class VuzixCarousel extends StatefulWidget {
  final List<VuzixCarouselItem> items;
  final CarouselItemsToShow? overrideItemsToShow;
  final bool showUnselectedOutline;

  /// we have two options to build this.
  /// using the carousel_slider package which provides animation,
  /// or using a simple row widget, without animation
  final bool buildWithCarouselPackage;

  const VuzixCarousel(
      {super.key,
      required this.items,
      this.overrideItemsToShow,
      this.showUnselectedOutline = false,
      this.buildWithCarouselPackage = true});

  @override
  State<VuzixCarousel> createState() => _VuzixCarouselState();
}

class _VuzixCarouselState extends State<VuzixCarousel> {
  int _selectedIndex = 0;

  final CarouselSliderController _controller = CarouselSliderController();

  @override
  void initState() {
    super.initState();

    inputHandler.keys.listen((event) {
      setState(() {
        switch (event) {
          case InputEvent.forward:
          case InputEvent.frontButton:
            _selectedIndex = (_selectedIndex + 1) % widget.items.length;
            break;
          case InputEvent.backward:
          case InputEvent.middleButton:
            _selectedIndex = (_selectedIndex - 1) % widget.items.length;
            break;
          case InputEvent.tap:
            widget.items[_selectedIndex].onSelected?.call();
            break;
          default:
            break;
        }
      });

      // when using the carousel package, we need to animate to the new index
      // otherwise we just rebuild the row widget with new _selectedIndex
      if (widget.buildWithCarouselPackage)
        _controller.animateToPage(_selectedIndex);
    });
  }

  @override
  Widget build(BuildContext context) => widget.buildWithCarouselPackage
      ? _buildWithCarousel(context)
      : _buildWithRow(context);

  int get _itemsToShow =>
      (widget.overrideItemsToShow ?? inputHandler.itemsToShow) ==
              CarouselItemsToShow.three
          ? 3
          : 5;

  double get _unselectedIconFactor =>
      (widget.overrideItemsToShow ?? inputHandler.itemsToShow) ==
              CarouselItemsToShow.three
          ? 0.7
          : 0.8;

  Widget _buildWithCarousel(BuildContext context) => Expanded(
        child: Center(
          child: CarouselSlider(
              carouselController: _controller,
              items: _buildItemsForCarousel(context),
              options: CarouselOptions(
                enlargeCenterPage: true,
                enlargeFactor: 0.2,
                enlargeStrategy: CenterPageEnlargeStrategy.scale,
                viewportFraction: (1 / _itemsToShow) *
                    0.99, // 0.99 because of https://github.com/serenader2014/flutter_carousel_slider/issues/419#issuecomment-2460944294
                aspectRatio: _itemsToShow.toDouble(),
                enableInfiniteScroll: true,
                scrollDirection: Axis.horizontal,
              )),
        ),
      );

  List<Widget> _buildItemsForCarousel(BuildContext context) => widget.items
      .mapIndexed(
        (index, item) => item.build(context,
            isSelected: index == _selectedIndex,
            unselectedIconFactor: _unselectedIconFactor,
            showUnselectedOutline: widget.showUnselectedOutline),
      )
      .toList();

  Widget _buildWithRow(BuildContext context) => Expanded(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _buildItemsForRow(context)),
      );

  List<Widget> _buildItemsForRow(BuildContext context) => [
        if (_itemsToShow == 5)
          Flexible(
            flex: 1,
            child: widget.items[(_selectedIndex - 2) % widget.items.length]
                .build(context,
                    unselectedIconFactor: _unselectedIconFactor,
                    showUnselectedOutline: widget.showUnselectedOutline),
          ),
        Flexible(
          flex: 1,
          child: widget.items[(_selectedIndex - 1) % widget.items.length].build(
              context,
              unselectedIconFactor: _unselectedIconFactor,
              showUnselectedOutline: widget.showUnselectedOutline),
        ),
        Flexible(
            flex: 2,
            child:
                widget.items[_selectedIndex].build(context, isSelected: true)),
        Flexible(
          flex: 1,
          child: widget.items[(_selectedIndex + 1) % widget.items.length].build(
              context,
              unselectedIconFactor: _unselectedIconFactor,
              showUnselectedOutline: widget.showUnselectedOutline),
        ),
        if (_itemsToShow == 5)
          Flexible(
            flex: 1,
            child: widget.items[(_selectedIndex + 2) % widget.items.length]
                .build(context,
                    unselectedIconFactor: _unselectedIconFactor,
                    showUnselectedOutline: widget.showUnselectedOutline),
          ),
      ];
}
