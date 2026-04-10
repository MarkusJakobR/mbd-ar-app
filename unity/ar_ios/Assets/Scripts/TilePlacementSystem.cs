using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;
using System.Collections.Generic;

public class TilePlacementSystem : MonoBehaviour
{
    [SerializeField] private ARRaycastManager raycastManager;
    [SerializeField] private ARPlaneManager planeManager;
    [SerializeField] private TileData currentTileData;
    [SerializeField] private GameObject tilePrefab; // Single tile prefab
    [SerializeField] private Material groutMaterial;
    
    private ARPlane selectedPlane;
    private GameObject tileGrid;
    private List<GameObject> spawnedTiles = new List<GameObject>();
    private int totalTileCount = 0;
    
    static readonly List<ARRaycastHit> rayHits = new List<ARRaycastHit>();

    void Update()
    {
        HandlePlaneSelection();
    }

    void HandlePlaneSelection()
    {
        if (Input.touchCount > 0)
        {
            Touch touch = Input.GetTouch(0);
            if (touch.phase == TouchPhase.Began)
            {
                if (raycastManager.Raycast(touch.position, rayHits, TrackableType.PlaneWithinPolygon))
                {
                    var hitPlane = planeManager.GetPlane(rayHits[0].trackableId);
                    if (hitPlane != null && IsHorizontalPlane(hitPlane))
                    {
                        SelectPlane(hitPlane);
                    }
                }
            }
        }
        
        // Mouse fallback for editor
        if (Input.GetMouseButtonDown(0))
        {
            if (raycastManager.Raycast(Input.mousePosition, rayHits, TrackableType.PlaneWithinPolygon))
            {
                var hitPlane = planeManager.GetPlane(rayHits[0].trackableId);
                if (hitPlane != null && IsHorizontalPlane(hitPlane))
                {
                    SelectPlane(hitPlane);
                }
            }
        }
    }

    bool IsHorizontalPlane(ARPlane plane)
    {
        return plane.alignment == PlaneAlignment.HorizontalUp || 
               plane.alignment == PlaneAlignment.HorizontalDown;
    }

    void SelectPlane(ARPlane plane)
    {
        if (selectedPlane == plane && tileGrid != null) return; // Already selected
        
        ClearTiles();
        selectedPlane = plane;
        GenerateTileGrid(plane);
    }

    void GenerateTileGrid(ARPlane plane)
    {
        if (currentTileData == null)
        {
            Debug.LogError("No tile data assigned!");
            return;
        }

        tileGrid = new GameObject($"TileGrid_{plane.trackableId}");
        tileGrid.transform.position = plane.center;
        tileGrid.transform.rotation = plane.transform.rotation;

        // Get plane boundary points
        Vector2[] boundary = GetPlaneBoundary(plane);
        if (boundary.Length == 0)
        {
            Debug.LogWarning("Plane has no boundary");
            return;
        }

        // Calculate bounding box
        Bounds bounds = CalculateBounds(boundary);
        
        // Calculate tile dimensions including grout
        float tileWidth = currentTileData.width + currentTileData.groutWidth;
        float tileHeight = currentTileData.height + currentTileData.groutWidth;

        // Calculate grid dimensions
        int tilesX = Mathf.CeilToInt(bounds.size.x / tileWidth);
        int tilesZ = Mathf.CeilToInt(bounds.size.y / tileHeight);

        totalTileCount = 0;

        // Generate tiles
        for (int x = 0; x < tilesX; x++)
        {
            for (int z = 0; z < tilesZ; z++)
            {
                Vector2 tilePos2D = new Vector2(
                    bounds.min.x + (x * tileWidth) + (tileWidth / 2),
                    bounds.min.y + (z * tileHeight) + (tileHeight / 2)
                );

                // Check if tile center is within plane boundary
                if (IsPointInPolygon(tilePos2D, boundary))
                {
                    CreateTile(tilePos2D, x, z);
                    totalTileCount++;
                }
            }
        }

        Debug.Log($"Generated {totalTileCount} tiles on plane {plane.trackableId}");
        
        // Notify Flutter about tile count
        NotifyTileCount(totalTileCount);
    }

    void CreateTile(Vector2 position2D, int gridX, int gridZ)
    {
        Vector3 worldPos = tileGrid.transform.TransformPoint(new Vector3(position2D.x, 0.001f, position2D.y));
        
        GameObject tile = Instantiate(tilePrefab, worldPos, tileGrid.transform.rotation, tileGrid.transform);
        tile.name = $"Tile_{gridX}_{gridZ}";
        
        // Set tile scale to match real dimensions
        tile.transform.localScale = new Vector3(
            currentTileData.width,
            currentTileData.thickness,
            currentTileData.height
        );

        // Apply material
        var renderer = tile.GetComponent<Renderer>();
        if (renderer != null)
        {
            renderer.material = currentTileData.tileMaterial;
        }

        spawnedTiles.Add(tile);
    }

    Vector2[] GetPlaneBoundary(ARPlane plane)
    {
        if (plane.boundary.Length == 0)
        {
            // Fallback: create rectangular boundary from plane size
            float halfWidth = plane.size.x / 2;
            float halfHeight = plane.size.y / 2;
            return new Vector2[]
            {
                new Vector2(-halfWidth, -halfHeight),
                new Vector2(halfWidth, -halfHeight),
                new Vector2(halfWidth, halfHeight),
                new Vector2(-halfWidth, halfHeight)
            };
        }

        Vector2[] boundary = new Vector2[plane.boundary.Length];
        for (int i = 0; i < plane.boundary.Length; i++)
        {
            boundary[i] = plane.boundary[i];
        }
        return boundary;
    }

    Bounds CalculateBounds(Vector2[] points)
    {
        Vector2 min = points[0];
        Vector2 max = points[0];

        foreach (var point in points)
        {
            min = Vector2.Min(min, point);
            max = Vector2.Max(max, point);
        }

        Vector2 center = (min + max) / 2;
        Vector2 size = max - min;
        
        return new Bounds(new Vector3(center.x, 0, center.y), new Vector3(size.x, 0, size.y));
    }

    // Ray casting algorithm for point-in-polygon test
    bool IsPointInPolygon(Vector2 point, Vector2[] polygon)
    {
        bool inside = false;
        int j = polygon.Length - 1;
        
        for (int i = 0; i < polygon.Length; j = i++)
        {
            if (((polygon[i].y > point.y) != (polygon[j].y > point.y)) &&
                (point.x < (polygon[j].x - polygon[i].x) * (point.y - polygon[i].y) / 
                (polygon[j].y - polygon[i].y) + polygon[i].x))
            {
                inside = !inside;
            }
        }
        
        return inside;
    }

    public void ClearTiles()
    {
        foreach (var tile in spawnedTiles)
        {
            if (tile != null) Destroy(tile);
        }
        spawnedTiles.Clear();
        
        if (tileGrid != null)
        {
            Destroy(tileGrid);
            tileGrid = null;
        }
        
        selectedPlane = null;
        totalTileCount = 0;
    }

    public void SetTileData(TileData newTileData)
    {
        currentTileData = newTileData;
        
        // Regenerate if plane already selected
        if (selectedPlane != null)
        {
            ClearTiles();
            GenerateTileGrid(selectedPlane);
        }
    }

    void NotifyTileCount(int count)
    {
        // Send to Flutter
        var arManager = FindObjectOfType<ARManager>();
        arManager?.NotifyTileCount(count, currentTileData?.tileName ?? "Unknown");
    }

    public int GetTileCount() => totalTileCount;
    
    public float GetTotalArea()
    {
        return totalTileCount * (currentTileData.width * currentTileData.height);
    }
}
