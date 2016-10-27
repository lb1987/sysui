// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'simulation_builder.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_widget.dart';
import 'story_list_layout.dart';
import 'story_list_render_block.dart';
import 'story_list_render_block_parent_data.dart';
import 'story_manager.dart';

/// In multicolumn mode, the distance the right column will be offset up.
const double _kRightBump = 64.0;

const double _kStoryInlineTitleHeight = 20.0;

typedef void OnStoryClusterFocusCompleted(StoryCluster storyCluster);

class StoryList extends StatelessWidget {
  final ScrollListener onScroll;
  final VoidCallback onStoryClusterFocusStarted;
  final OnStoryClusterFocusCompleted onStoryClusterFocusCompleted;
  final double bottomPadding;
  final Size parentSize;
  final double quickSettingsHeightBump;
  final bool multiColumn;
  final Key scrollableKey;

  StoryList({
    Key key,
    this.scrollableKey,
    this.bottomPadding,
    this.onScroll,
    this.onStoryClusterFocusStarted,
    this.onStoryClusterFocusCompleted,
    this.parentSize,
    this.quickSettingsHeightBump,
    this.multiColumn: false,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    StoryManager storyManager = InheritedStoryManager.of(
      context,
      rebuildOnChange: true,
    );

    // IMPORTANT:  In order for activation of inactive stories from suggestions
    // to work we must have them in the widget tree.
    List<Widget> stackChildren = new List.from(
      storyManager.inactiveStoryClusters.map(
        (StoryCluster storyCluster) => new Offstage(
              offstage: true,
              child: new SimulationBuilder(
                key: storyCluster.focusSimulationKey,
                builder: (BuildContext context, double progress) =>
                    _createStoryCluster(
                      storyManager.activeSortedStoryClusters,
                      storyCluster,
                      0.0,
                    ),
              ),
            ),
      ),
    );

    stackChildren.add(
      new StoryListBlock(
        scrollableKey: scrollableKey,
        bottomPadding: bottomPadding,
        onScroll: onScroll,
        parentSize: parentSize,
        listHeight: storyManager.listHeight,
        children: new List<Widget>.generate(
          storyManager.activeSortedStoryClusters.length,
          (int index) => _createFocusableStoryCluster(
                storyManager.activeSortedStoryClusters,
                storyManager.activeSortedStoryClusters[index],
              ),
        ),
      ),
    );

    return new Stack(children: stackChildren);
  }

  Widget _createFocusableStoryCluster(
    List<StoryCluster> storyClusters,
    StoryCluster storyCluster,
  ) =>
      new SimulationBuilder(
        key: storyCluster.focusSimulationKey,
        onSimulationChanged: (double progress, bool isDone) {
          if (progress == 1.0 && isDone) {
            onStoryClusterFocusCompleted?.call(storyCluster);
          }
        },
        builder: (BuildContext context, double progress) => new StoryListChild(
              storyLayout: storyCluster.storyLayout,
              focusProgress: progress,
              child: _createStoryCluster(storyClusters, storyCluster, progress),
            ),
      );

  Widget _createStoryCluster(
    List<StoryCluster> storyClusters,
    StoryCluster storyCluster,
    double progress,
  ) =>
      new StoryClusterWidget(
          focusProgress: progress,
          fullSize: parentSize,
          storyCluster: storyCluster,
          multiColumn: multiColumn,
          onGainFocus: () {
            bool storyClusterInFocus = false;
            storyClusters.forEach((StoryCluster s) {
              if (_inFocus(s)) {
                storyClusterInFocus = true;
              }
            });

            if (!storyClusterInFocus) {
              // Bring tapped story into focus.
              storyCluster.focusSimulationKey.currentState?.forward();
              storyCluster.stories.forEach((Story story) {
                story.storyBarKey.currentState?.maximize();
              });

              onStoryClusterFocusStarted?.call();
            }
          });

  bool _inFocus(StoryCluster s) =>
      (s.focusSimulationKey.currentState?.progress ?? 0.0) > 0.0;
}

class StoryListBlock extends Block {
  final Size parentSize;
  final double bottomPadding;
  final double listHeight;
  StoryListBlock({
    Key key,
    List<Widget> children,
    this.bottomPadding,
    ScrollListener onScroll,
    Key scrollableKey,
    this.parentSize,
    this.listHeight,
  })
      : super(
          key: key,
          children: children,
          scrollDirection: Axis.vertical,
          scrollAnchor: ViewportAnchor.end,
          onScroll: onScroll,
          scrollableKey: scrollableKey,
        ) {
    assert(children != null);
    assert(!children.any((Widget child) => child == null));
  }

  @override
  Widget build(BuildContext context) => new ScrollableViewport(
        scrollableKey: scrollableKey,
        initialScrollOffset: initialScrollOffset,
        scrollDirection: scrollDirection,
        scrollAnchor: scrollAnchor,
        onScrollStart: onScrollStart,
        onScroll: onScroll,
        onScrollEnd: onScrollEnd,
        child: new StoryListBlockBody(
          children: children,
          parentSize: parentSize,
          listHeight: listHeight,
          scrollOffset: (scrollableKey as GlobalKey<ScrollableState>)
                  .currentState
                  ?.scrollOffset ??
              0.0,
          bottomPadding: bottomPadding,
        ),
      );
}

class StoryListBlockBody extends BlockBody {
  final Size parentSize;
  final double scrollOffset;
  final double bottomPadding;
  final double listHeight;
  StoryListBlockBody({
    Key key,
    List<Widget> children,
    this.parentSize,
    this.scrollOffset,
    this.bottomPadding,
    this.listHeight,
  })
      : super(key: key, mainAxis: Axis.vertical, children: children);

  @override
  StoryListRenderBlock createRenderObject(BuildContext context) =>
      new StoryListRenderBlock(
        parentSize: parentSize,
        scrollOffset: scrollOffset,
        bottomPadding: bottomPadding,
        listHeight: listHeight,
      );

  @override
  void updateRenderObject(
      BuildContext context, StoryListRenderBlock renderObject) {
    renderObject.mainAxis = mainAxis;
    renderObject.parentSize = parentSize;
    renderObject.scrollOffset = scrollOffset;
    renderObject.bottomPadding = bottomPadding;
    renderObject.listHeight = listHeight;
  }
}

class StoryListChild extends ParentDataWidget<StoryListBlockBody> {
  final StoryLayout storyLayout;
  final double focusProgress;
  StoryListChild({
    Widget child,
    this.storyLayout,
    this.focusProgress,
  })
      : super(child: child);

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is StoryListRenderBlockParentData);
    final StoryListRenderBlockParentData parentData = renderObject.parentData;
    parentData.storyLayout = storyLayout;
    parentData.focusProgress = focusProgress;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('storyLayout: $storyLayout, focusProgress: $focusProgress');
  }
}
