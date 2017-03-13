// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'drag_direction.dart';
import 'line_segment.dart';
import 'panel_drag_targets.dart';

const double _kDirectionMinSpeed = 100.0;
const Duration _kMinLockDuration = const Duration(milliseconds: 500);

/// Once a drag target is chosen, this is the distance a draggable must travel
/// before new drag targets are considered.
const double _kStickyDistance = 40.0;

typedef DateTime TimestampEmitter();

/// Manages the metadata associated with a dragged candidate in
/// [PanelDragTargets].
class CandidateInfo {
  /// Should be overridden in testing only.
  final TimestampEmitter timestampEmitter;

  final Duration minLockDuration;

  /// When a 'closest target' is chosen, the [Point] of the candidate becomes
  /// the lock point for that target.  A new 'closest target' will not be chosen
  /// until the candidate travels the [_kStickyDistance] away from that lock
  /// point.
  Point _lockPoint;
  LineSegment _closestTarget;
  DateTime _timestamp;
  VelocityTracker _velocityTracker;
  DragDirection _lastDragDirection = DragDirection.none;

  CandidateInfo({
    @required Point initialLockPoint,
    this.timestampEmitter: defaultTimestampEmitter,
    this.minLockDuration: _kMinLockDuration,
  })
      : _lockPoint = initialLockPoint {
    assert(initialLockPoint != null);
    assert(timestampEmitter != null);
    assert(minLockDuration != null);
  }

  LineSegment get closestTarget => _closestTarget;

  /// Updates the candidate's velocity with [point].
  void updateVelocity(Point point) {
    if (_velocityTracker == null) {
      _velocityTracker = new VelocityTracker();
    }
    _velocityTracker.addPosition(
      new Duration(milliseconds: timestampEmitter().millisecondsSinceEpoch),
      point,
    );
  }

  // The candidate can lock to line closest to the candidate if the candidate:
  // 1) is new, or
  // 2) is old, and
  //    a) the closest line to the candidate has changed,
  //    b) we've moved past the sticky distance from the candidate's lock
  //       point, and
  //    c) the candidate's closest line hasn't changed recently.
  bool canLock(LineSegment closestTarget, Point storyClusterPoint) =>
      _hasNewPotentialTarget(closestTarget) &&
      _hasMovedPastThreshold(storyClusterPoint) &&
      _hasNotChangedRecently();

  /// Locks the candidate to [closestTarget] at the given [lockPoint].
  void lock(Point lockPoint, LineSegment closestTarget) {
    _timestamp = timestampEmitter();
    _lockPoint = lockPoint;
    _closestTarget = closestTarget;
  }

  /// Gets the direction the candidate is being dragged in.  This is based on
  /// the velocity candidate is being and has been dragged.
  DragDirection get dragDirection {
    DragDirection currentDragDirection = _dragDirectionFromVelocity;
    if (currentDragDirection != DragDirection.none) {
      _lastDragDirection = currentDragDirection;
    }
    return _lastDragDirection;
  }

  DragDirection get _dragDirectionFromVelocity {
    Velocity velocity = _velocityTracker?.getVelocity();
    if (velocity == null) {
      return DragDirection.none;
    } else if (velocity.pixelsPerSecond.dx.abs() >
        velocity.pixelsPerSecond.dy.abs()) {
      if (velocity.pixelsPerSecond.dx > _kDirectionMinSpeed) {
        return DragDirection.right;
      } else if (velocity.pixelsPerSecond.dx < -_kDirectionMinSpeed) {
        return DragDirection.left;
      } else {
        return DragDirection.none;
      }
    } else {
      if (velocity.pixelsPerSecond.dy > _kDirectionMinSpeed) {
        return DragDirection.down;
      } else if (velocity.pixelsPerSecond.dy < -_kDirectionMinSpeed) {
        return DragDirection.up;
      } else {
        return DragDirection.none;
      }
    }
  }

  bool _hasNewPotentialTarget(LineSegment closestLine) =>
      closestLine != null &&
      (_closestTarget == null || (_closestTarget.name != closestLine.name));

  bool _hasMovedPastThreshold(Point storyClusterPoint) =>
      (_lockPoint - storyClusterPoint).distance > _kStickyDistance;

  bool _hasNotChangedRecently() =>
      _timestamp == null ||
      timestampEmitter().subtract(minLockDuration).isAfter(_timestamp);

  /// Turns a [CandidateInfo] into a [Point] using the candidate's lock point.
  static Point toPoint(CandidateInfo candidateInfo) => candidateInfo._lockPoint;

  static DateTime defaultTimestampEmitter() => new DateTime.now();
}
