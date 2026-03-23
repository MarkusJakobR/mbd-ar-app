using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;
using System.Collections.Generic;

public class TilePlacer : MonoBehaviour
{
    public GameObject tilePrefab;
    public ARPlaneManager planeManager;
    public float tileSize = 0.5f; // 50cm tiles
    public float heightOffset = 0.01f; // Lift tiles slightly above floor (1cm)

    private Dictionary<ARPlane, List<GameObject>> planeTiles = new Dictionary<ARPlane, List<GameObject>>();

    void Start()
    {
        // Subscribe to plane detection events
        planeManager.planesChanged += OnPlanesChanged;
    }

    void OnDestroy()
    {
        planeManager.planesChanged -= OnPlanesChanged;
    }

    void OnPlanesChanged(ARPlanesChangedEventArgs args)
    {
        // Handle new planes
        foreach (ARPlane plane in args.added)
        {
            if (plane.alignment == PlaneAlignment.HorizontalUp)
            {
                TilePlane(plane);
            }
        }

        // Handle updated planes (expanded detection)
        foreach (ARPlane plane in args.updated)
        {
            if (plane.alignment == PlaneAlignment.HorizontalUp)
            {
                // Remove old tiles
                ClearPlaneTiles(plane);
                // Re-tile with new size
                TilePlane(plane);
            }
        }

        // Handle removed planes
        foreach (ARPlane plane in args.removed)
        {
            ClearPlaneTiles(plane);
        }
    }

    void TilePlane(ARPlane plane)
    {
        // Get plane bounds
        Vector2 planeSize = plane.size;
        Vector3 planeCenter = plane.center;

        // Calculate number of tiles needed
        int tilesX = Mathf.CeilToInt(planeSize.x / tileSize);
        int tilesZ = Mathf.CeilToInt(planeSize.y / tileSize); // Note: plane.size.y is Z in world space

        // Calculate starting position (bottom-left corner of plane)
        Vector3 startPos = planeCenter - new Vector3(planeSize.x / 2f, 0, planeSize.y / 2f);

        List<GameObject> tiles = new List<GameObject>();

        // Place tiles in grid
        for (int x = 0; x < tilesX; x++)
        {
            for (int z = 0; z < tilesZ; z++)
            {
                // Calculate tile position
                Vector3 localPosition = new Vector3(
                    x * tileSize + tileSize / 2f,
                    heightOffset, // Slightly above plane to prevent z-fighting
                    z * tileSize + tileSize / 2f
                );

                Vector3 worldPosition = plane.transform.TransformPoint(startPos + localPosition);

                // Instantiate tile
                GameObject tile = Instantiate(tilePrefab, worldPosition, Quaternion.identity);

                // Make tile child of plane (so it moves with plane tracking)
                tile.transform.SetParent(plane.transform);

                // Ensure tile is flat
                tile.transform.localRotation = Quaternion.identity;

                tiles.Add(tile);
            }
        }

        // Store tiles for this plane
        planeTiles[plane] = tiles;

        Debug.Log($"Tiled plane with {tiles.Count} tiles ({tilesX}x{tilesZ})");
    }

    void ClearPlaneTiles(ARPlane plane)
    {
        if (planeTiles.ContainsKey(plane))
        {
            // Destroy all tiles for this plane
            foreach (GameObject tile in planeTiles[plane])
            {
                if (tile != null)
                {
                    Destroy(tile);
                }
            }
            planeTiles.Remove(plane);
        }
    }
}
