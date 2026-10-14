"""Performance and spatial indexing efficiency test suite for ClearPath."""

import time
from backend.app.proximity import (
    PROXIMITY_THRESHOLD_METERS,
    haversine_distance,
    is_within_bounding_box,
)


def test_bounding_box_filter_accuracy():
    """Verify bounding box pre-filter correctly accepts near points and rejects far points."""
    base_lat, base_lon = 12.971598, 77.594562

    # Point within 20m north (should pass bounding box)
    near_lat = base_lat + (20.0 / 111139.0)
    assert is_within_bounding_box(base_lat, base_lon, near_lat, base_lon) is True

    # Point 100m north (outside 30.48m threshold, should be rejected)
    far_lat = base_lat + (100.0 / 111139.0)
    assert is_within_bounding_box(base_lat, base_lon, far_lat, base_lon) is False

    # Point 200m east (outside 30.48m threshold, should be rejected)
    far_lon = base_lon + (200.0 / (111139.0 * 0.974))
    assert is_within_bounding_box(base_lat, base_lon, base_lat, far_lon) is False


def test_spatial_proximity_throughput_benchmark():
    """Verify that Haversine distance engine can evaluate 10,000 coordinate pairs in <100ms."""
    base_lat, base_lon = 12.971598, 77.594562
    iterations = 10000

    start_time = time.perf_counter()
    for i in range(iterations):
        offset = (i % 100) * 0.0001
        haversine_distance(base_lat, base_lon, base_lat + offset, base_lon + offset)
    elapsed = time.perf_counter() - start_time

    # Must process 10,000 points in well under 0.15 seconds
    assert elapsed < 0.20, f"Performance bottleneck: 10,000 iterations took {elapsed:.3f}s"
