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
        if (Input.touchCount == 1)
        {
            Touch touch = Input.GetTouch(0);

            if (touch.phase == TouchPhase.Began)
            {
                TryPlaceCornerPoint(touch.position);
            }
        }

        // Mouse for editor
        if (Input.GetMouseButtonDown(0) && raycastManager != null)
        {
            TryPlaceCornerPoint(Input.mousePosition);
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
        Debug.Log($"Corner points count: {cornerPoints.Count}");

        List<Vector3> sortedPoints = SortPointsClockwise(cornerPoints);

        Bounds bounds = CalculateBounds(sortedPoints);
        Vector3 center = bounds.center;
        Vector2 size = new Vector2(bounds.size.x, bounds.size.z);

        Debug.Log($"Bounding box - Center: {center}, Size: {size.x:F2}m x {size.y:F2}m");

        // Create a flat, axis-aligned quad
        tilePlane = new GameObject("TilePlane");
        tilePlane.transform.position = center;
        tilePlane.transform.rotation = Quaternion.identity;

        MeshFilter meshFilter = tilePlane.AddComponent<MeshFilter>();
        MeshRenderer meshRenderer = tilePlane.AddComponent<MeshRenderer>();

        // Create mesh
        Mesh mesh = CreateFlatQuad(size);
        meshFilter.mesh = mesh;

        Debug.Log($"Mesh created - Vertices: {mesh.vertexCount}, Triangles: {mesh.triangles.Length / 3}");

        tileMaterial = CreateTileMaterial(size);
        meshRenderer.material = tileMaterial;

        // DEBUG: Check material
        Debug.Log($"Material created: {tileMaterial.name}");
        Debug.Log($"Material shader: {tileMaterial.shader.name}");
        Debug.Log($"Material base texture: {tileMaterial.GetTexture("_BaseMap")}");
        Debug.Log($"Material tiling: {tileMaterial.mainTextureScale}");

        // DEBUG: Check renderer
        Debug.Log($"Renderer enabled: {meshRenderer.enabled}");
        Debug.Log($"Renderer bounds: {meshRenderer.bounds}");

        // tilePlane.transform.position = new Vector3(0, 0.05f, 0);
        tilePlane.transform.position = center + Vector3.up * 0.001f; // 50cm above center

        Debug.Log($"Final tile plane position: {tilePlane.transform.position}");

        // Calculate tile count
        CalculateAndReportTileCount(size);

        Debug.Log("=== TILE AREA CREATION COMPLETE ===");
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

    Mesh CreateFlatQuad(Vector2 size)
    {
        Mesh mesh = new Mesh();

        float halfWidth = size.x / 2f;
        float halfHeight = size.y / 2f;

        // Simple rectangle vertices
        Vector3[] vertices = new Vector3[]
        {
        new Vector3(-halfWidth, 0, -halfHeight),
        new Vector3(halfWidth, 0, -halfHeight),
        new Vector3(halfWidth, 0, halfHeight),
        new Vector3(-halfWidth, 0, halfHeight)
        };

        Vector2[] uvs = new Vector2[]
        {
        new Vector2(0, 0),
        new Vector2(1, 0),
        new Vector2(1, 1),
        new Vector2(0, 1)
        };

        int[] triangles = new int[]
        {
        0, 1, 2,
        0, 2, 3
        };

        mesh.vertices = vertices;
        mesh.uv = uvs;
        mesh.triangles = triangles;
        mesh.RecalculateNormals();
        mesh.RecalculateBounds();

        return mesh;
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

    Mesh CreateQuadMeshFromPoints(List<Vector3> points)
    {
        Mesh mesh = new Mesh();

        // Use the 4 corner points as vertices
        Vector3[] vertices = new Vector3[4]
        {
            points[0],
            points[1],
            points[2],
            points[3]
        };

        // Calculate UVs based on world positions
        Vector2[] uvs = CalculateUVs(points);

        // Triangles (two triangles make a quad)
        int[] triangles = new int[6]
        {
            0, 2, 1,  // First triangle
            0, 3, 2   // Second triangle
        };

        mesh.vertices = vertices;
        mesh.uv = uvs;
        mesh.triangles = triangles;
        mesh.RecalculateNormals();

        return mesh;
    }

    Vector2[] CalculateUVs(List<Vector3> points)
    {
        // Calculate the bounding rectangle to map UVs properly
        Vector2[] uvs = new Vector2[4];

        // Simple UV mapping: corners map to 0,0  1,0  1,1  0,1
        uvs[0] = new Vector2(0, 0);
        uvs[1] = new Vector2(1, 0);
        uvs[2] = new Vector2(1, 1);
        uvs[3] = new Vector2(0, 1);

        return uvs;
    }

    Vector2 CalculateAreaDimensions(List<Vector3> points)
    {
        // Calculate width and height from the points
        float width = Vector3.Distance(points[0], points[1]);
        float height = Vector3.Distance(points[1], points[2]);

        return new Vector2(width, height);
    }

    Material CreateTileMaterial(Vector2 areaDimensions)
    {
        Debug.Log($"Creating tile material for area: {areaDimensions.x:F2}m x {areaDimensions.y:F2}m");

        Material material = new Material(Shader.Find("Universal Render Pipeline/Lit"));

        material.SetFloat("_Cull", 0); // 0 = Off (double-sided), 1 = Front, 2 = Back
        material.doubleSidedGI = true;

        if (tileTexture == null)
        {
            tileTexture = CreateTileTexture();
            Debug.Log($"Tile texture created: {tileTexture.width}x{tileTexture.height}");
        }

        material.SetTexture("_BaseMap", tileTexture);
        material.SetColor("_BaseColor", Color.white); // Full brightness

        // Calculate tiling
        float tilingX = areaDimensions.x / tileWidth;
        float tilingZ = areaDimensions.y / tileHeight;
        material.mainTextureScale = new Vector2(tilingX, tilingZ);

        Debug.Log($"Tile material created: {tilingX:F1} x {tilingZ:F1} tiles");

        return material;
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

        // Destroy tile quad
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
