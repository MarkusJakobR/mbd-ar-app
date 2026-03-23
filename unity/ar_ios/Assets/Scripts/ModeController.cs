using UnityEngine;
using TMPro;

public class ModeController : MonoBehaviour
{
    // The GameObject that has the Object Spawner script
    public GameObject spawnerObject;

    // The GameObject that has the ShaderTilePlacer script (XR Origin)
    public GameObject tileObject;

    public TextMeshProUGUI buttonText;

    private MonoBehaviour objectSpawner;
    private ShaderTilePlacer tilePlacer;
    private bool isTileMode = false;

    void Start()
    {
        // Find the Object Spawner script
        if (spawnerObject != null)
        {
            objectSpawner = spawnerObject.GetComponent<MonoBehaviour>();

            // If multiple scripts on the object, find the right one
            MonoBehaviour[] scripts = spawnerObject.GetComponents<MonoBehaviour>();
            foreach (MonoBehaviour script in scripts)
            {
                if (script.GetType().Name == "ObjectSpawner")
                {
                    objectSpawner = script;
                    Debug.Log("✓ Found Object Spawner script on: " + spawnerObject.name);
                    break;
                }
            }
        }

        // Find the Tile Placer script
        if (tileObject != null)
        {
            tilePlacer = tileObject.GetComponent<ShaderTilePlacer>();
            if (tilePlacer != null)
            {
                Debug.Log("✓ Found ShaderTilePlacer script on: " + tileObject.name);
            }
        }

        // Start with furniture mode active
        SetFurnitureMode();
    }

    public void ToggleMode()
    {
        if (isTileMode)
        {
            SetFurnitureMode();
        }
        else
        {
            SetTileMode();
        }
    }

    void SetFurnitureMode()
    {
        isTileMode = false;

        // Enable Object Spawner
        if (objectSpawner != null)
        {
            objectSpawner.enabled = true;
            Debug.Log("✓ Furniture Mode - Object Spawner enabled");
        }
        else
        {
            Debug.LogError("❌ Object Spawner not found!");
        }

        // Disable Tile Placer
        if (tilePlacer != null)
        {
            tilePlacer.enabled = false;
        }

        // Update button
        if (buttonText != null)
        {
            buttonText.text = "Furniture Mode";
        }
    }

    void SetTileMode()
    {
        isTileMode = true;

        // Disable Object Spawner
        if (objectSpawner != null)
        {
            objectSpawner.enabled = false;
            Debug.Log("✓ Tile Mode - Object Spawner disabled");
        }
        else
        {
            Debug.LogError("❌ Object Spawner not found!");
        }

        // Enable Tile Placer
        if (tilePlacer != null)
        {
            tilePlacer.enabled = true;
        }

        // Update button
        if (buttonText != null)
        {
            buttonText.text = "Tile Mode";
        }
    }
}
