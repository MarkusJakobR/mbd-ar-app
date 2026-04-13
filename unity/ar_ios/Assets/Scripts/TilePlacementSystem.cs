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

    [Header("Crosshair Settings")]
    [SerializeField] private float crosshairRadius = 0.1f; // 10cm
    [SerializeField] private Color crosshairColor = Color.white;

    [Header("Shader Reference")]
    [SerializeField] private Material tileClipMaterialReference;

    private List<Vector3> cornerPoints = new List<Vector3>(); // World positions
    private List<GameObject> cornerMarkers = new List<GameObject>();
    private List<LineRenderer> boundaryLines = new List<LineRenderer>();
    private GameObject tilePlane;
    private Material tileMaterial;
    private Texture2D tileTexture;
    private float currentRotation = 0f;
    private float degrees;
    private bool _rotatingClockwise = false;
    private bool _rotatingCounter = false;
    private float _offsetX = 0f;
    private float _offsetZ = 0f;
    private bool _isDraggingTile = false;
    private Vector2 _lastDragPosition;
    private float _previousPinchAngle;
    private GameObject _crosshairRoot;
    private GameObject _crosshairSphere;
    private LineRenderer _crosshairRing;
    private Vector3 _crosshairWorldPoint;
    private bool _crosshairVisible = false;
    private bool _isTileMode = false;

    static readonly List<ARRaycastHit> rayHits = new List<ARRaycastHit>();

    void Start()
    {
        CreateCrosshair();
    }

    void Update()
    {
        HandleTouchInput();
        UpdateCrosshair();
        if (tilePlane != null)
        {
            HandleTileTouch();
        }

        // Editor testing: Press T to add test points
        if (Application.isEditor && Input.GetKeyDown(KeyCode.T))
        {
            AddTestPoint();
        }

        if (Input.GetKeyDown(KeyCode.C))
        {
            ClearAll();
        }

        // Press R to rotate tiles (for testing)
        if (Input.GetKey(KeyCode.R) && tilePlane != null)
        {
            degrees = 30f * Time.deltaTime;
            RotateTiles(degrees); // Rotate by 45 degrees
        }

        if (_rotatingClockwise)
        {
            Debug.Log("Rotating tile clockwise");
            degrees = 30f * Time.deltaTime;
            RotateTiles(degrees);
        }

        if (_rotatingCounter)
        {
            Debug.Log("Rotating tile counter clockwise");
            degrees = -30f * Time.deltaTime;
            RotateTiles(degrees);
        }

        float offsetSpeed = 0.5f * Time.deltaTime;
        if (Input.GetKey(KeyCode.UpArrow)) MoveTileOffset(0, offsetSpeed);
        if (Input.GetKey(KeyCode.DownArrow)) MoveTileOffset(0, -offsetSpeed);
        if (Input.GetKey(KeyCode.LeftArrow)) MoveTileOffset(-offsetSpeed, 0);
        if (Input.GetKey(KeyCode.RightArrow)) MoveTileOffset(offsetSpeed, 0);

    }

    void HandleTileTouch()
    {
        if (tileMaterial == null) return;

        if (Input.touchCount == 1)
        {
            Touch touch = Input.GetTouch(0);

            if (touch.phase == TouchPhase.Began)
            {
                _isDraggingTile = true;
                _lastDragPosition = touch.position;
            }
            else if (touch.phase == TouchPhase.Moved && _isDraggingTile)
            {
                // How much did the finger move in screen space
                Vector2 delta = touch.position - _lastDragPosition;
                _lastDragPosition = touch.position;

                // Convert screen delta to world units
                // Screen pixels to meters — adjust sensitivity as needed
                float sensitivity = 0.001f;
                MoveTileOffset(delta.x * sensitivity, delta.y * sensitivity);
            }
            else if (touch.phase == TouchPhase.Ended)
            {
                _isDraggingTile = false;
            }
        }
        else if (Input.touchCount == 2)
        {
            Touch t0 = Input.GetTouch(0);
            Touch t1 = Input.GetTouch(1);

            float currentAngle = Mathf.Atan2(
                t1.position.y - t0.position.y,
                t1.position.x - t0.position.x
            ) * Mathf.Rad2Deg;

            if (t1.phase == TouchPhase.Began)
            {
                // Capture baseline when second finger lands
                _previousPinchAngle = currentAngle;
            }
            else if (t0.phase == TouchPhase.Moved || t1.phase == TouchPhase.Moved)
            {
                float delta = currentAngle - _previousPinchAngle;
                RotateTiles(delta);
                _previousPinchAngle = currentAngle;
            }
        }
    }

    // remove this function later
    void HandleTouchInput()
    {
        if (Application.isMobilePlatform)
        {
            if (Input.touchCount == 1)
            {
                Touch touch = Input.GetTouch(0);

                if (touch.phase == TouchPhase.Began)
                {
                    // TryPlaceCornerPoint(touch.position);
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

    public void SetTileMode(bool active)
    {
        _isTileMode = active;

        if (!active && _crosshairRoot != null)
        {
            _crosshairRoot.SetActive(false);
        }
    }

    void CreateCrosshair()
    {
        // Root object that we move every frame
        _crosshairRoot = new GameObject("CrosshairRoot");

        // --- Ring with a cut ---
        GameObject ringObj = new GameObject("CrosshairRing");
        ringObj.transform.SetParent(_crosshairRoot.transform);

        _crosshairRing = ringObj.AddComponent<LineRenderer>();
        _crosshairRing.startWidth = 0.005f; // 5mm thick
        _crosshairRing.endWidth = 0.005f;
        _crosshairRing.useWorldSpace = false; // local space so it moves with root
        _crosshairRing.loop = false;

        Material ringMat = new Material(Shader.Find("Universal Render Pipeline/Lit"));
        ringMat.color = crosshairColor;
        _crosshairRing.material = ringMat;

        // Build circle points with a cut at the top (skip ~30 degrees)
        int totalPoints = 60;
        int cutStartIndex = 0;   // cut starts at 0 degrees
        int cutEndIndex = 5;     // cut spans ~30 degrees (5 out of 60 points)
        int pointCount = totalPoints - (cutEndIndex - cutStartIndex);
        _crosshairRing.positionCount = pointCount;

        int idx = 0;
        for (int i = cutEndIndex; i < totalPoints + cutStartIndex; i++)
        {
            float angle = (i / (float)totalPoints) * Mathf.PI * 2f;
            float x = Mathf.Cos(angle) * crosshairRadius;
            float z = Mathf.Sin(angle) * crosshairRadius;
            _crosshairRing.SetPosition(idx, new Vector3(x, 0, z));
            idx++;
        }

        // --- Center sphere ---
        _crosshairSphere = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        _crosshairSphere.transform.SetParent(_crosshairRoot.transform);
        _crosshairSphere.transform.localPosition = Vector3.zero;
        _crosshairSphere.transform.localScale = Vector3.one * 0.02f; // 2cm sphere

        // Remove collider so it doesnt interfere with raycasts
        Destroy(_crosshairSphere.GetComponent<Collider>());

        Material sphereMat = new Material(Shader.Find("Universal Render Pipeline/Lit"));
        sphereMat.color = crosshairColor;
        _crosshairSphere.GetComponent<Renderer>().material = sphereMat;

        // Start hidden
        _crosshairRoot.SetActive(false);
    }

    void UpdateCrosshair()
    {
        if (!_isTileMode)
        {
            _crosshairRoot.SetActive(false);
            return;
        }
        // Hide crosshair once 4 points are placed
        if (cornerPoints.Count >= 4)
        {
            _crosshairRoot.SetActive(false);
            return;
        }

        Vector2 screenCenter = new Vector2(Screen.width / 2f, Screen.height / 2f);

        if (raycastManager.Raycast(screenCenter, rayHits, TrackableType.PlaneWithinPolygon))
        {
            Pose hitPose = rayHits[0].pose;
            _crosshairWorldPoint = hitPose.position;

            // Snap position and align ring to plane normal
            _crosshairRoot.transform.position = _crosshairWorldPoint;
            _crosshairRoot.transform.rotation = hitPose.rotation;

            // Slightly above floor to avoid z-fighting
            _crosshairRoot.transform.position += Vector3.up * 0.002f;

            if (!_crosshairRoot.activeSelf)
                _crosshairRoot.SetActive(true);
        }
        else
        {
            // No plane detected — hide it
            if (_crosshairRoot.activeSelf)
                _crosshairRoot.SetActive(false);
        }
    }

    public void ConfirmCrosshairPoint()
    {
        if (cornerPoints.Count >= 4) return;
        if (!_crosshairRoot.activeSelf) return; // no plane detected, ignore

        AddCornerPoint(_crosshairWorldPoint);
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
        Bounds bounds = CalculateTightBounds(sortedPoints);
        Vector3 center = bounds.center;
        Vector2 size = new Vector2(bounds.size.x, bounds.size.z);

        Debug.Log($"Bounding box - Center: {center}, Size: {size.x:F2}m x {size.y:F2}m");

        tilePlane = new GameObject("TilePlane");
        tilePlane.transform.position = center;
        tilePlane.transform.rotation = Quaternion.identity;

        MeshFilter meshFilter = tilePlane.AddComponent<MeshFilter>();
        MeshRenderer meshRenderer = tilePlane.AddComponent<MeshRenderer>();

        // Create a mesh with only the tiles inside the quad boundary
        Mesh mesh = CreateFlatQuad(size);
        meshFilter.mesh = mesh;

        tileMaterial = CreateClippedTileMaterial(size, sortedPoints, center);
        meshRenderer.material = tileMaterial;

        CalculateAndReportTileCount(size);

        Debug.Log("=== TILE AREA CREATION COMPLETE ===");
    }

    Bounds CalculateTightBounds(List<Vector3> points)
    {
        // Calculate the minimum axis-aligned bounding box
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
        mesh.name = "TileQuadMesh";

        float halfWidth = size.x / 2f;
        float halfHeight = size.y / 2f;

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

    Material CreateClippedTileMaterial(Vector2 areaDimensions, List<Vector3> quadPoints, Vector3 center)
    {
        Shader clipShader = null;

        if (tileClipMaterialReference != null)
        {
            clipShader = tileClipMaterialReference.shader;
        }
        else
        {
            clipShader = Shader.Find("Custom/TileClipShader");
        }

        if (clipShader == null)
        {
            Debug.LogError("TileClipShader not found!");
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

        // Set quad boundary points for clipping
        material.SetVector("_QuadPoint0", new Vector4(quadPoints[0].x, quadPoints[0].y, quadPoints[0].z, 0));
        material.SetVector("_QuadPoint1", new Vector4(quadPoints[1].x, quadPoints[1].y, quadPoints[1].z, 0));
        material.SetVector("_QuadPoint2", new Vector4(quadPoints[2].x, quadPoints[2].y, quadPoints[2].z, 0));
        material.SetVector("_QuadPoint3", new Vector4(quadPoints[3].x, quadPoints[3].y, quadPoints[3].z, 0));

        // Calculate tiling for accurate tile sizes
        float tilingX = areaDimensions.x / tileWidth;
        float tilingZ = areaDimensions.y / tileHeight;
        material.SetTextureScale("_BaseMap", new Vector2(tilingX, tilingZ));

        material.SetFloat("_CenterX", center.x);
        material.SetFloat("_CenterZ", center.z);

        // Apply current rotation
        ApplyRotationToMaterial(material, currentRotation);

        Debug.Log($"Material created, tiling: {tilingX:F2} x {tilingZ:F2}, rotation: {currentRotation}°");

        return material;
    }

    public void StartRotatingTile(bool clockwise)
    {
        if (clockwise)
        {
            _rotatingClockwise = true;
        }
        else
        {
            _rotatingCounter = true;
        }
    }

    public void RotateTiles(float degrees)
    {
        if (tileMaterial == null)
        {
            Debug.LogWarning("No tile material to rotate");
            return;
        }

        currentRotation += degrees;
        currentRotation = currentRotation % 360f; // Keep between 0-360

        ApplyRotationToMaterial(tileMaterial, currentRotation);

        Debug.Log($"Tiles rotated to {currentRotation}°");
    }

    public void StopRotatingTile()
    {
        _rotatingClockwise = false;
        _rotatingCounter = false;
    }

    void ApplyRotationToMaterial(Material material, float degrees)
    {
        // Convert degrees to radians
        float radians = degrees * Mathf.Deg2Rad;

        // Calculate rotation matrix for UVs
        // We rotate around the center (0.5, 0.5) of UV space
        float cos = Mathf.Cos(radians);
        float sin = Mathf.Sin(radians);

        // Unity's material texture offset and scale can't do rotation directly
        // We need to use texture rotation which rotates around (0,0)
        // So we: translate to center -> rotate -> translate back

        // For now, just rotate the texture offset
        // Full UV rotation would need a custom shader property
        material.SetFloat("_Rotation", degrees); // We'll add this to shader
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

    public void MoveTileOffset(float deltaX, float deltaZ)
    {
        if (tileMaterial == null) return;

        _offsetX += deltaX;
        _offsetZ += deltaZ;

        tileMaterial.SetFloat("_OffsetX", _offsetX);
        tileMaterial.SetFloat("_OffsetZ", _offsetZ);
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

        if (_crosshairRoot != null)
            _crosshairRoot.SetActive(true);

        currentRotation = 0f;
        _offsetX = 0f;
        _offsetZ = 0f;

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
