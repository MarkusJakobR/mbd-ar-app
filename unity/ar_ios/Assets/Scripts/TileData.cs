using UnityEngine;

[CreateAssetMenu(fileName = "NewTile", menuName = "AR Furniture/Tile Data")]
public class TileData : ScriptableObject
{
    public string tileName;
    public string productId;
    public Material tileMaterial;
    
    [Header("Real-world dimensions in meters")]
    public float width = 0.6f;   // 60cm common tile size
    public float height = 0.6f;  // 60cm
    public float thickness = 0.01f; // 1cm
    
    [Header("Grout settings")]
    public float groutWidth = 0.002f; // 2mm grout gap
    public Color groutColor = new Color(0.8f, 0.8f, 0.8f);
}
