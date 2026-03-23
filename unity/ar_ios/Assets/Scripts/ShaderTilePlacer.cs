using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;
using System.Collections.Generic;

public class ShaderTilePlacer : MonoBehaviour
{
    public ARPlaneManager planeManager;
    public Material tileMaterial;
    public Vector2 tileSize = new Vector2(0.5f, 0.5f); // 50cm x 50cm

    // Track which planes have been tiled
    private Dictionary<ARPlane, GameObject> tiledPlanes = new Dictionary<ARPlane, GameObject>();

    void Start()
    {
        // Listen for when AR detects planes
        planeManager.planesChanged += OnPlanesChanged;
    }

    void OnDestroy()
    {
        planeManager.planesChanged -= OnPlanesChanged;
    }

    void OnPlanesChanged(ARPlanesChangedEventArgs args)
    {
        // When a new horizontal plane is detected, tile it!
        foreach (ARPlane plane in args.added)
        {
            if (plane.alignment == PlaneAlignment.HorizontalUp)
            {
                Debug.Log("✅ Horizontal plane detected! Auto-tiling...");
                CreateTiledSurface(plane);
            }
        }

        // When plane gets bigger (AR detects more floor), update tiles
        foreach (ARPlane plane in args.updated)
        {
            if (plane.alignment == PlaneAlignment.HorizontalUp && tiledPlanes.ContainsKey(plane))
            {
                Debug.Log("📏 Plane expanded, updating tiles...");
                RemoveTiles(plane);
                CreateTiledSurface(plane);
            }
        }

        // When plane is removed, remove tiles
        foreach (ARPlane plane in args.removed)
        {
            RemoveTiles(plane);
        }
    }

    void CreateTiledSurface(ARPlane plane)
    {
        // Get plane info
        Vector2 planeSize = plane.size;

        Debug.Log($"Creating tiled surface: {planeSize.x}m × {planeSize.y}m");

        // Create a mesh for this plane
        GameObject tiledSurface = new GameObject("TiledSurface_" + plane.trackableId);
        tiledSurface.transform.SetParent(plane.transform);
        tiledSurface.transform.localPosition = Vector3.up * 0.01f; // 1cm above plane
        tiledSurface.transform.localRotation = Quaternion.identity;

        MeshFilter meshFilter = tiledSurface.AddComponent<MeshFilter>();
        MeshRenderer renderer = tiledSurface.AddComponent<MeshRenderer>();

        // Create rectangular mesh matching plane size
        Mesh mesh = CreatePlaneMesh(planeSize);
        meshFilter.mesh = mesh;

        // Apply tile material
        renderer.material = tileMaterial;

        // Calculate UV tiling
        float tilesX = planeSize.x / tileSize.x;
        float tilesY = planeSize.y / tileSize.y;

        // Set material tiling
        renderer.material.mainTextureScale = new Vector2(tilesX, tilesY);

        // Store reference
        tiledPlanes[plane] = tiledSurface;

        // Calculate tile count
        int totalTiles = Mathf.CeilToInt(tilesX) * Mathf.CeilToInt(tilesY);
        Debug.Log($"✓ Tiled! Area: {planeSize.x:F2}m × {planeSize.y:F2}m");
        Debug.Log($"✓ Tiles needed: {totalTiles} ({Mathf.CeilToInt(tilesX)} × {Mathf.CeilToInt(tilesY)})");
    }

    Mesh CreatePlaneMesh(Vector2 size)
    {
        Mesh mesh = new Mesh();

        float halfWidth = size.x / 2f;
        float halfHeight = size.y / 2f;

        // 4 corners
        Vector3[] vertices = new Vector3[]
        {
            new Vector3(-halfWidth, 0, -halfHeight),
            new Vector3(halfWidth, 0, -halfHeight),
            new Vector3(halfWidth, 0, halfHeight),
            new Vector3(-halfWidth, 0, halfHeight)
        };

        // 2 triangles
        int[] triangles = new int[]
        {
            0, 1, 2,
            0, 2, 3
        };

        // UVs (texture coordinates)
        Vector2[] uvs = new Vector2[]
        {
            new Vector2(0, 0),
            new Vector2(1, 0),
            new Vector2(1, 1),
            new Vector2(0, 1)
        };

        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.uv = uvs;
        mesh.RecalculateNormals();

        return mesh;
    }

    void RemoveTiles(ARPlane plane)
    {
        if (tiledPlanes.ContainsKey(plane))
        {
            Destroy(tiledPlanes[plane]);
            tiledPlanes.Remove(plane);
        }
    }

    // Call this to change tile size (e.g., from UI button)
    public void SetTileSize(float width, float height)
    {
        tileSize = new Vector2(width, height);

        // Re-tile all existing planes
        foreach (var kvp in tiledPlanes)
        {
            ARPlane plane = kvp.Key;
            RemoveTiles(plane);
            CreateTiledSurface(plane);
        }

        Debug.Log($"Tile size changed to {width * 100}cm × {height * 100}cm");
    }
}
