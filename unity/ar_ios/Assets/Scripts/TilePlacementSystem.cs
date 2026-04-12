using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;
using System.Collections.Generic;
using System.Linq;

public class TilePlacementSystem : MonoBehaviour
{
    [Header("AR Components")]
    [SerializeField] private ARRaycastManager raycastManager;

    [Header("Tile Settings")]
    [SerializeField] private float tileWidth = 0.6f;
    [SerializeField] private float tileHeight = 0.6f;
    [SerializeField] private Color tileColor = new Color(0.9f, 0.9f, 0.85f);
    [SerializeField] private Color groutColor = new Color(0.6f, 0.6f, 0.6f);

    [Header("Visual Settings")]
    [SerializeField] private GameObject cornerMarkerPrefab; // Small sphere
    [SerializeField] private Material lineMaterial; // For boundary lines
    [SerializeField] private Color markerColor = Color.yellow;
    [SerializeField] private float markerSize = 0.05f; // 5cm sphere

    private List<Vector3> cornerPoints = new List<Vector3>(); // World positions
    private List<GameObject> cornerMarkers = new List<GameObject>();
    private List<LineRenderer> boundaryLines = new List<LineRenderer>();
    private GameObject tilePlane;
    private Material tileMaterial;
    private Texture2D tileTexture;

    static readonly List<ARRaycastHit> rayHits = new List<ARRaycastHit>();

    void Update()
    {
        HandleTouchInput();

        // Editor testing: Press T to add test points
        if (Application.isEditor && Input.GetKeyDown(KeyCode.T))
        {
            AddTestPoint();
        }

        if (Input.GetKeyDown(KeyCode.C))
        {
            ClearAll();
        }
    }

    void HandleTouchInput()
    {
        if (Application.isMobilePlatform)
        {
            if (Input.touchCount == 1)
            {
                Touch touch = Input.GetTouch(0);

                if (touch.phase == TouchPhase.Began)
                {
                    TryPlaceCornerPoint(touch.position);
                }
            }
        }
        else
        {
            // Mouse for editor
            if (Input.GetMouseButtonDown(0) && raycastManager != null)
            {
                TryPlaceCornerPoint(Input.mousePosition);
            }
        }
    }

    void TryPlaceCornerPoint(Vector2 screenPosition)
    {
        if (raycastManager == null)
        {
            Debug.LogWarning("AR Raycast Manager not assigned");
            return;
        }

        // Already have 4 points, can't add more
        if (cornerPoints.Count >= 4)
        {
            Debug.Log("Already have 4 corners. Press Reset to start over.");
            return;
        }

        // Raycast to find floor
        if (raycastManager.Raycast(screenPosition, rayHits, TrackableType.PlaneWithinPolygon))
        {
            Vector3 hitPosition = rayHits[0].pose.position;
            AddCornerPoint(hitPosition);
        }
    }

    void AddCornerPoint(Vector3 worldPosition)
    {
        cornerPoints.Add(worldPosition);

        // Create visual marker
        GameObject marker = CreateCornerMarker(worldPosition);
        cornerMarkers.Add(marker);

        Debug.Log($"Added corner point {cornerPoints.Count}: {worldPosition}");

        // Draw boundary line from previous point
        if (cornerPoints.Count > 1)
        {
            DrawBoundaryLine(cornerPoints[cornerPoints.Count - 2], worldPosition);
        }

        // If we have 4 points, close the shape and create tiles
        if (cornerPoints.Count == 4)
        {
            // Close the rectangle by connecting point 4 back to point 1
            DrawBoundaryLine(cornerPoints[3], cornerPoints[0]);
            CreateTileArea();
        }
    }

    GameObject CreateCornerMarker(Vector3 position)
    {
        GameObject marker;

        if (cornerMarkerPrefab != null)
        {
            marker = Instantiate(cornerMarkerPrefab, position, Quaternion.identity);
        }
        else
        {
            // Create a simple sphere
            marker = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            marker.transform.position = position;
            marker.transform.localScale = Vector3.one * markerSize;

            var renderer = marker.GetComponent<Renderer>();
            renderer.material = new Material(Shader.Find("Universal Render Pipeline/Lit"));
            renderer.material.color = markerColor;
        }

        marker.name = $"CornerMarker_{cornerPoints.Count}";
        return marker;
    }

    void DrawBoundaryLine(Vector3 start, Vector3 end)
    {
        GameObject lineObj = new GameObject($"BoundaryLine_{boundaryLines.Count}");
        LineRenderer line = lineObj.AddComponent<LineRenderer>();

        // Configure line
        line.startWidth = 0.01f; // 1cm thick line
        line.endWidth = 0.01f;
        line.positionCount = 2;
        line.SetPosition(0, start + Vector3.up * 0.005f); // Slightly above floor
        line.SetPosition(1, end + Vector3.up * 0.005f);

        // Material
        if (lineMaterial != null)
        {
            line.material = lineMaterial;
        }
        else
        {
            line.material = new Material(Shader.Find("Universal Render Pipeline/Lit"));
            line.material.color = markerColor;
        }

        boundaryLines.Add(line);
    }

    void CreateTileArea()
    {
        Debug.Log("=== CREATING TILE AREA ===");

        List<Vector3> sortedPoints = SortPointsClockwise(cornerPoints);
        Bounds bounds = CalculateBounds(sortedPoints);
        Vector3 center = bounds.center;
        Vector2 size = new Vector2(bounds.size.x, bounds.size.z);

        Debug.Log($"Bounding box - Center: {center}, Size: {size.x:F2}m x {size.y:F2}m");

        tilePlane = new GameObject("TilePlane");
        tilePlane.transform.position = Vector3.zero; // Position is baked into vertices
        tilePlane.transform.rotation = Quaternion.identity;

        MeshFilter meshFilter = tilePlane.AddComponent<MeshFilter>();
        MeshRenderer meshRenderer = tilePlane.AddComponent<MeshRenderer>();

        // Create a mesh with only the tiles inside the quad boundary
        Mesh mesh = CreateClippedTileMesh(bounds, sortedPoints);
        meshFilter.mesh = mesh;

        tileMaterial = CreateClippedTileMaterial(size, sortedPoints);
        meshRenderer.material = tileMaterial;

        CalculateAndReportTileCount(size);

        Debug.Log("=== TILE AREA CREATION COMPLETE ===");
    }

    Material CreateClippedTileMaterial(Vector2 areaDimensions, List<Vector3> quadPoints)
    {
        // Use the custom shader
        Shader clipShader = Shader.Find("Custom/TileClipShader");

        if (clipShader == null)
        {
            Debug.LogError("TileClipShader not found! Make sure you created the shader file.");
            clipShader = Shader.Find("Universal Render Pipeline/Lit");
        }

        Material material = new Material(clipShader);
        material.name = "ClippedTileMaterial";

        if (tileTexture == null)
        {
            tileTexture = CreateTileTexture();
        }

        material.SetTexture("_BaseMap", tileTexture);
        material.SetColor("_BaseColor", Color.white);

        // Pass the quad corner points to the shader
        material.SetVector("_QuadPoint0", quadPoints[0]);
        material.SetVector("_QuadPoint1", quadPoints[1]);
        material.SetVector("_QuadPoint2", quadPoints[2]);
        material.SetVector("_QuadPoint3", quadPoints[3]);

        // Calculate tiling for accurate tile sizes
        float tilingX = areaDimensions.x / tileWidth;
        float tilingZ = areaDimensions.y / tileHeight;
        material.mainTextureScale = new Vector2(tilingX, tilingZ);

        Debug.Log($"Clipped material created with quad boundaries, tiling: {tilingX:F2} x {tilingZ:F2}");

        return material;
    }

    Mesh CreateClippedTileMesh(Bounds bounds, List<Vector3> quadPoints)
    {
        Mesh mesh = new Mesh();
        mesh.name = "ClippedTileMesh";

        // Calculate how many tiles fit (with extra padding to cover edges)
        int tilesX = Mathf.CeilToInt(bounds.size.x / tileWidth) + 2; // +2 for padding
        int tilesZ = Mathf.CeilToInt(bounds.size.z / tileHeight) + 2;

        Debug.Log($"Grid size: {tilesX} x {tilesZ} tiles");

        List<Vector3> vertices = new List<Vector3>();
        List<Vector2> uvs = new List<Vector2>();
        List<int> triangles = new List<int>();

        // Start from slightly before the bounds to ensure coverage
        float startX = bounds.min.x - tileWidth;
        float startZ = bounds.min.z - tileHeight;
        float y = bounds.center.y;

        int vertexIndex = 0;

        // Create all tiles, even if they partially overlap the quad
        for (int ix = 0; ix < tilesX; ix++)
        {
            for (int iz = 0; iz < tilesZ; iz++)
            {
                float x0 = startX + (ix * tileWidth);
                float x1 = x0 + tileWidth;
                float z0 = startZ + (iz * tileHeight);
                float z1 = z0 + tileHeight;

                // Check if ANY corner of the tile is inside the quad
                // OR if the tile overlaps the quad boundary
                Vector3[] tileCorners = new Vector3[]
                {
                new Vector3(x0, y, z0),
                new Vector3(x1, y, z0),
                new Vector3(x1, y, z1),
                new Vector3(x0, y, z1)
                };

                // Check if tile intersects with quad
                bool includeThisTile = false;

                // Check if any tile corner is inside the quad
                foreach (var corner in tileCorners)
                {
                    if (IsPointInsideQuad(corner, quadPoints))
                    {
                        includeThisTile = true;
                        break;
                    }
                }

                // Also check if any quad corner is inside the tile bounds
                if (!includeThisTile)
                {
                    foreach (var quadPoint in quadPoints)
                    {
                        if (quadPoint.x >= x0 && quadPoint.x <= x1 &&
                            quadPoint.z >= z0 && quadPoint.z <= z1)
                        {
                            includeThisTile = true;
                            break;
                        }
                    }
                }

                if (includeThisTile)
                {
                    // Add this tile
                    vertices.Add(new Vector3(x0, y, z0));
                    vertices.Add(new Vector3(x1, y, z0));
                    vertices.Add(new Vector3(x1, y, z1));
                    vertices.Add(new Vector3(x0, y, z1));

                    uvs.Add(new Vector2(0, 0));
                    uvs.Add(new Vector2(1, 0));
                    uvs.Add(new Vector2(1, 1));
                    uvs.Add(new Vector2(0, 1));

                    triangles.Add(vertexIndex + 0);
                    triangles.Add(vertexIndex + 1);
                    triangles.Add(vertexIndex + 2);

                    triangles.Add(vertexIndex + 0);
                    triangles.Add(vertexIndex + 2);
                    triangles.Add(vertexIndex + 3);

                    vertexIndex += 4;
                }
            }
        }

        mesh.vertices = vertices.ToArray();
        mesh.uv = uvs.ToArray();
        mesh.triangles = triangles.ToArray();
        mesh.RecalculateNormals();
        mesh.RecalculateBounds();

        Debug.Log($"Created mesh with {vertices.Count / 4} tiles");

        return mesh;
    }

    bool IsPointInsideQuad(Vector3 point, List<Vector3> quadPoints)
    {
        // Use ray casting algorithm for point-in-polygon test (in XZ plane)
        Vector2 p = new Vector2(point.x, point.z);
        Vector2[] poly = new Vector2[4]
        {
        new Vector2(quadPoints[0].x, quadPoints[0].z),
        new Vector2(quadPoints[1].x, quadPoints[1].z),
        new Vector2(quadPoints[2].x, quadPoints[2].z),
        new Vector2(quadPoints[3].x, quadPoints[3].z)
        };

        bool inside = false;
        int j = 3;

        for (int i = 0; i < 4; j = i++)
        {
            if (((poly[i].y > p.y) != (poly[j].y > p.y)) &&
                (p.x < (poly[j].x - poly[i].x) * (p.y - poly[i].y) / (poly[j].y - poly[i].y) + poly[i].x))
            {
                inside = !inside;
            }
        }

        return inside;
    }

    Bounds CalculateBounds(List<Vector3> points)
    {
        Vector3 min = points[0];
        Vector3 max = points[0];

        foreach (var p in points)
        {
            min = Vector3.Min(min, p);
            max = Vector3.Max(max, p);
        }

        Vector3 center = (min + max) / 2f;
        Vector3 size = max - min;

        return new Bounds(center, size);
    }

    List<Vector3> SortPointsClockwise(List<Vector3> points)
    {
        // Step 1: Find the center point (centroid)
        Vector3 center = Vector3.zero;
        foreach (var p in points)
        {
            center += p;
        }
        center /= points.Count;

        // Step 2: Sort points by angle around the center
        var sorted = points.OrderBy(p =>
        {
            // Calculate angle from center to point (in the XZ plane, since Y is up)
            Vector3 direction = p - center;
            return Mathf.Atan2(direction.z, direction.x);
        }).ToList();

        Debug.Log("Points sorted in clockwise order:");
        for (int i = 0; i < sorted.Count; i++)
        {
            Debug.Log($"  Point {i}: {sorted[i]}");
        }

        return sorted;
    }

    Texture2D CreateTileTexture()
    {
        Debug.Log("Creating tile texture...");

        int texSize = 128;
        Texture2D tex = new Texture2D(texSize, texSize);

        int groutPixels = 2;

        for (int y = 0; y < texSize; y++)
        {
            for (int x = 0; x < texSize; x++)
            {
                if (x < groutPixels || y < groutPixels)
                {
                    tex.SetPixel(x, y, groutColor);
                }
                else
                {
                    tex.SetPixel(x, y, tileColor);
                }
            }
        }

        tex.Apply();
        tex.filterMode = FilterMode.Bilinear;
        tex.wrapMode = TextureWrapMode.Repeat;

        Debug.Log("Tile texture created and applied");

        return tex;
    }

    void CalculateAndReportTileCount(Vector2 areaDimensions)
    {
        int tilesX = Mathf.RoundToInt(areaDimensions.x / tileWidth);
        int tilesZ = Mathf.RoundToInt(areaDimensions.y / tileHeight);
        int totalTiles = tilesX * tilesZ;

        float totalArea = areaDimensions.x * areaDimensions.y;

        Debug.Log($"Area: {areaDimensions.x:F2}m x {areaDimensions.y:F2}m = {totalArea:F2}m²");
        Debug.Log($"Tiles: {tilesX} x {tilesZ} = {totalTiles} tiles");

        var arManager = FindObjectOfType<ARManager>();
        arManager?.NotifyTileCount(totalTiles, $"{tileWidth}x{tileHeight}m");
    }

    public void ClearAll()
    {
        // Clear corner points
        cornerPoints.Clear();

        // Destroy markers
        foreach (var marker in cornerMarkers)
        {
            if (marker != null) Destroy(marker);
        }
        cornerMarkers.Clear();

        // Destroy boundary lines
        foreach (var line in boundaryLines)
        {
            if (line != null) Destroy(line.gameObject);
        }
        boundaryLines.Clear();

        if (tilePlane != null)
        {
            Destroy(tilePlane);
            tilePlane = null;
        }

        if (tileMaterial != null)
        {
            Destroy(tileMaterial);
            tileMaterial = null;
        }

        Debug.Log("All points and tiles cleared");
    }

    // Editor testing
    void AddTestPoint()
    {
        // Add test points in a square pattern
        Vector3[] testPoints = new Vector3[]
        {
            new Vector3(0, 0, 0),
            new Vector3(2, 0, 0),
            new Vector3(2, 0, 2),
            new Vector3(0, 0, 2.5f)
        };

        if (cornerPoints.Count < 4)
        {
            AddCornerPoint(testPoints[cornerPoints.Count]);
        }
    }
}
