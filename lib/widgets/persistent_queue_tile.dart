/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Needed for scrollbar computations.
const double kPersistentQueueTileHeight = kPersistentQueueTileArtSize + _tileVerticalPadding * 2;
const double _tileVerticalPadding = 8.0;
const double _horizontalPadding = 16.0;
const double _gridArtSize = 220.0;
const double _gridArtAssetScale = 1.2;
const double _gridCurrentIndicatorScale = 1.7;

class PersistentQueueTile<T extends PersistentQueue> extends SelectableWidget<SelectionEntry> {
  const PersistentQueueTile({
    Key? key,
    required this.queue,
    this.trailing,
    this.current,
    this.onTap,
    this.small = false,
    this.grid = false,
    this.gridArtSize = _gridArtSize,
    this.gridArtAssetScale = _gridArtAssetScale,
    this.gridCurrentIndicatorScale = _gridCurrentIndicatorScale,
    this.gridShowYear = false,
    double? horizontalPadding,
  }) : assert(!grid || !small),
       horizontalPadding = horizontalPadding ?? (small ? kSongTileHorizontalPadding : _horizontalPadding),
       index = null,
       super(key: key);

  const PersistentQueueTile.selectable({
    Key? key,
    required this.queue,
    required int this.index,
    required SelectionController<SelectionEntry>? selectionController,
    bool selected = false,
    this.trailing,
    this.current,
    this.onTap,
    this.small = false,
    this.grid = false,
    this.gridArtSize = _gridArtSize,
    this.gridArtAssetScale = _gridArtAssetScale,
    this.gridCurrentIndicatorScale = _gridCurrentIndicatorScale,
    this.gridShowYear = false,
    double? horizontalPadding,
  }) : assert(selectionController is SelectionController<SelectionEntry<Content>> ||
              selectionController is SelectionController<SelectionEntry<T>>),
       assert(!grid || !small),
       horizontalPadding = horizontalPadding ?? (small ? kSongTileHorizontalPadding : _horizontalPadding),
       super.selectable(
         key: key,
         selected: selected,
         selectionController: selectionController,
       );

  final T queue;
  final int? index;

  /// Widget to be rendered at the end of the tile.
  final Widget? trailing;

  /// Whether this queue is currently playing, if yes, enables animated
  /// [CurrentIndicator] over the ablum art.
  /// 
  /// If not specified, by default uses [ContentUtils.persistentQueueIsCurrent].
  final bool? current;
  final VoidCallback? onTap;

  /// Creates a small variant of the tile with the sizes of [SelectableTile].
  final bool small;

  /// When `true`, will create a tile suitable to be shown in grid.
  /// The [small] must be `false` when this is `true`.
  final bool grid;

  /// The size of the art when [grid] is `true`.
  final double gridArtSize;
  
  /// Value passed to [ContentArt.assetScale] when [grid] is `true`.
  final double gridArtAssetScale;

  /// Value passed to [ContentArt.currentIndicatorScale] when [grid] is `true`.
  final double gridCurrentIndicatorScale;

  /// If true, for [Album]s near the artist, the ablum year will be shown.
  final bool gridShowYear;

  /// Tile horizontal padding. Ignored whne [grid] is `true`.
  final double horizontalPadding;

  @override
  SelectionEntry<T> toSelectionEntry() => SelectionEntry<T>(
    index: index,
    data: queue,
  );

  @override
  _PersistentQueueTileState<T> createState() => _PersistentQueueTileState();
}

class _PersistentQueueTileState<T extends PersistentQueue> extends SelectableState<PersistentQueueTile<T>> {
  void _handleTap() {
    super.handleTap(() {
      widget.onTap?.call();
      HomeRouter.instance.goto(HomeRoutes.factory.persistentQueue<T>(widget.queue));
    });
  }

  bool get current {
    if (widget.current != null)
      return widget.current!;
    return ContentUtils.persistentQueueIsCurrent(widget.queue);
  }

  Widget _buildInfo() {
    final List<Widget> children = [
      Text(
        widget.queue.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ThemeControl.theme.textTheme.headline6,
      ),
    ];
    final queue = widget.queue;
    if (queue is Album) {
      final artist = widget.gridShowYear
        ? queue.albumDotName(getl10n(context))
        : queue.artist;
      children.add(ArtistWidget(
        artist: artist,
        textStyle: const TextStyle(fontSize: 14.0, height: 1.0),
      ));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildTile() {
    final source = ContentArtSource.persistentQueue(widget.queue);

    final Widget child;
    if (widget.grid) {
      child = SizedBox(
        width: widget.gridArtSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ContentArt(
              size: widget.gridArtSize,
              highRes: true,
              currentIndicatorScale: widget.gridCurrentIndicatorScale,
              assetScale: widget.gridArtAssetScale,
              source: source,
              current: current,
            ),
            _buildInfo(),
          ],
        ),
      );
    } else {
      child = Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.horizontalPadding,
          vertical: _tileVerticalPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: widget.small
                ? ContentArt.songTile(
                    source: source,
                    current: current,
                  )
                : ContentArt.persistentQueueTile(
                    source: source,
                    current: current,
                  ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: _buildInfo(),
              ),
            ),
            if (widget.trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: widget.trailing,
              ),
          ],
        ),
      );
    }

    if (widget.grid) {
      return Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: CustomBoxy(
              delegate: _BoxyDelegate(() => Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleTap,
                  splashColor: Constants.Theme.glowSplashColor.auto,
                  onLongPress: toggleSelection,
                  splashFactory: _InkRippleFactory(artSize: widget.gridArtSize),
                ),
              )),
              children: [
                LayoutId(id: #tile, child: child),
              ],
            ),
          ),
        ],
      );
    }
    return InkWell(
      onTap: _handleTap,
      onLongPress: toggleSelection,
      splashFactory: NFListTileInkRipple.splashFactory,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!selectable)
      return _buildTile();

    final artSize = widget.grid ? widget.gridArtSize : kPersistentQueueTileArtSize;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildTile(),
        if (animation.status != AnimationStatus.dismissed)
          Positioned(
            left: artSize + (widget.grid ? -20.0 : 2.0),
            top: artSize - (widget.grid ? 20.0 : 7.0),
            child: SelectionCheckmark(
              size: widget.grid ? 28.0 : 21.0,
              animation: animation,
            ),
          ),
      ],
    );
  }
}


class _BoxyDelegate extends BoxyDelegate {
  _BoxyDelegate(this.builder); 
  final ValueGetter<Widget> builder;

  @override
  Size layout() {
    final tile = getChild(#tile);
    final tileSize = tile.layout(constraints);

    final ink = inflate(builder(), id: #ink);
    ink.layout(constraints.tighten(
      width: tileSize.width,
      height: tileSize.height,
    ));

    return Size(
      tileSize.width,
      tileSize.height,
    );
  }
}


class _InkRippleFactory extends InteractiveInkFeatureFactory {
  const _InkRippleFactory({required this.artSize});

  final double artSize;

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) {
    return NFListTileInkRipple(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      containedInkWell: containedInkWell,
      rectCallback: () => Offset.zero & Size(artSize, artSize),
      borderRadius: const BorderRadius.all(Radius.circular(kArtBorderRadius)),
      customBorder: customBorder,
      radius: radius,
      onRemoved: onRemoved,
      textDirection: textDirection,
    );
  }
}