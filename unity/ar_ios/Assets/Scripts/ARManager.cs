using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using System.Collections;
using UnityEngine.XR.ARFoundation;
using FlutterUnityIntegration;

public enum ARMode
{
    Furniture,
    Tile
}
public class ARManager : MonoBehaviour
{
    private static ARManager _instance;

    [SerializeField] private ARPlaceFurniture placeFurniture;
    [SerializeField] private TilePlacementSystem tilePlacementSystem;
    [SerializeField] private bool useLocalPrefabForTesting = true;
    [SerializeField] private string editorTestKey = "brown_cabinet";

    private bool isInitialized = false;
    private ARObjectSelector _selector;
    private UnityMessageManager _messageManager;
    private ARMode currentMode = ARMode.Furniture;

    void Start()
    {
        _messageManager = UnityMessageManager.Instance;

        if (_messageManager == null)
        {
            Debug.LogError("UnityMessageManager instance not found in scene");
        }

        _selector = FindObjectOfType<ARObjectSelector>();

        if (_selector != null)
        {
            _selector.OnObjectSelected += _ => SendToFlutter("ObjectSelected");
            _selector.OnObjectDeselected += () => SendToFlutter("ObjectDeselected");
        }

        if (!useLocalPrefabForTesting)
            StartCoroutine(InitializeAddressables());
        else
            StartCamera();
    }

    // Mode switching
    public void SetMode(ARMode mode)
    {
        currentMode = mode;

        switch (mode)
        {
            case ARMode.Furniture:

                // Disable tile system
                if (tilePlacementSystem != null)
                {
                    tilePlacementSystem.ClearAll();
                    tilePlacementSystem.SetTileMode(false);
                    tilePlacementSystem.enabled = false;
                }

                // Enable furniture system
                if (placeFurniture != null)
                    placeFurniture.enabled = true;


                Debug.Log("Switched to Furniture mode");
                SendToFlutter("ModeChanged:Furniture");
                break;

            case ARMode.Tile:
                // Disable furniture system
                if (placeFurniture != null)
                {
                    placeFurniture.ResetScene();
                    placeFurniture.enabled = false;
                }

                // Deselect any selected furniture
                if (_selector != null && _selector.HasSelection)
                    _selector.Deselect();

                // Enable tile system
                if (tilePlacementSystem != null)
                {

                    tilePlacementSystem.SetTileMode(true);
                    tilePlacementSystem.enabled = true;
                }

                Debug.Log("Switched to Tile mode");
                SendToFlutter("ModeChanged:Tile");
                break;
        }
    }

    private void SendToFlutter(string message)
    {
        if (_messageManager != null)
            _messageManager.SendMessageToFlutter(message);
        else
            Debug.LogWarning("UnityMessageManager not found on ARManager");
    }

    public void SendLockStateToFlutter(bool isLocked)
    {
        SendToFlutter($"LockState:{isLocked.ToString().ToLower()}");
    }

    IEnumerator InitializeAddressables()
    {
        Debug.Log("Initializing Addressables...");
        yield return Addressables.InitializeAsync();
        Debug.Log("Addressables initialized — loading remote catalog...");

        string catalogUrl = "https://crczirzejyiyliizruyy.supabase.co/storage/v1/object/public/asset-storage/temp_addressables/iOS/catalog_catalog.json";

        var catalogHandle = Addressables.LoadContentCatalogAsync(catalogUrl);
        yield return catalogHandle;

        if (catalogHandle.Result == null)
        {
            Debug.LogError("Catalog loaded but result is null");
            Addressables.Release(catalogHandle);
            yield break;
        }

        Debug.Log("Remote catalog loaded successfully");
        Addressables.Release(catalogHandle);
        isInitialized = true;

        SendToFlutter("OnUnityReady");
    }

    public void OnTileSelected(string jsonMessage)
    {
        Debug.Log("OnTileSelected called from Flutter");
        SetMode(ARMode.Tile);

        var data = JsonUtility.FromJson<ProductMessage>(jsonMessage);
        Debug.Log($"Tile selected: {data.name}");

        if (tilePlacementSystem != null)
        {
            tilePlacementSystem.enabled = true;
            // You can pass tile dimensions here if needed
            // tilePlacementSystem.SetTileDimensions(data.width, data.height);
        }
        else
        {
            Debug.LogError("TilePlacementSystem is null!");
        }
    }

    public void OnProductSelected(string jsonMessage)
    {
        if (useLocalPrefabForTesting)
        {
            Debug.Log("Testing mode — using Inspector prefab");
            return;
        }

        if (!isInitialized)
        {
            Debug.LogWarning("Addressables not ready yet");
            return;
        }

        placeFurniture.ClearScene();
        var data = JsonUtility.FromJson<ProductMessage>(jsonMessage);
        Debug.Log($"Product selected: {data.name} | key: {data.addressableKey} | placement: {data.placementType}");
        StartCoroutine(LoadPrefabByKey(data.addressableKey, data.placementType));
    }

    IEnumerator LoadPrefabByKey(string key, string placementType = "Any")
    {
        Debug.Log("Loading prefab with key: " + key);
        var handle = Addressables.LoadAssetAsync<GameObject>(key);
        yield return handle;

        if (handle.Result != null)
        {
            Debug.Log("Prefab loaded: " + key);
            placeFurniture.SetFurniturePrefab(handle.Result, placementType);
        }
        else
        {
            Debug.LogError("Failed to load prefab: " + key);
            Addressables.Release(handle);
        }
    }

    // Flutter button receivers — all take string param as required by postMessage
    public void RotateClockwise(string message)
    {
        Debug.Log("ARManager: RotateClockwise received from Flutter");
        if (placeFurniture != null)
        {
            placeFurniture.StartRotating(true);
            Debug.Log("ARManager: Called StartRotating(true)");
        }
        else
        {
            Debug.LogError("ARManager: placeFurniture is NULL!");
        }
    }

    public void RotateCounter(string message)
    {
        Debug.Log("ARManager: RotateCounter received from Flutter");
        if (placeFurniture != null)
        {
            placeFurniture.StartRotating(false);
            Debug.Log("ARManager: Called StartRotating(false)");
        }
        else
        {
            Debug.LogError("ARManager: placeFurniture is NULL!");
        }
    }

    public void RotateClockwiseTile(string message)
    {
        if (tilePlacementSystem != null)
        {
            tilePlacementSystem.StartRotatingTile(true);
        }
        else
        {
            Debug.LogError("ARManager: tilePlacementSystem is NULL");
        }
    }

    public void RotateCounterTile(string message)
    {
        if (tilePlacementSystem != null)
        {
            tilePlacementSystem.StartRotatingTile(false);
        }
        else
        {
            Debug.LogError("ARManager: tilePlacementSystem is NULL");
        }
    }


    public void StopRotating(string message)
    {
        Debug.Log("ARManager: StopRotating received from Flutter");
        if (placeFurniture != null)
        {
            placeFurniture.StopRotating();
            Debug.Log("ARManager: Called StopRotating()");
        }
        else
        {
            Debug.LogError("ARManager: placeFurniture is NULL!");
        }
    }

    public void StopRotatingTile(string message)
    {
        if (tilePlacementSystem != null)
        {
            tilePlacementSystem.StopRotatingTile();
        }
        else
        {
            Debug.LogError("ARManager: Cannot stop rotating");
        }
    }

    public void ConfirmCrosshairPoint(string message)
    {
        if (tilePlacementSystem != null)
        {
            tilePlacementSystem.ConfirmCrosshairPoint();
        }
        else
        {
            Debug.LogError("ARManager: Cannot add point");
        }
    }

    public void DeleteSelected(string message) => _selector?.DeleteSelected();
    public void DuplicateSelected(string message)
    {
        Debug.Log($"=== ARManager.DuplicateSelected called === Instance ID: {GetInstanceID()} GameObject: {gameObject.name}");
        if (placeFurniture != null)
        {
            placeFurniture.DuplicateSelected();
        }
        else
        {
            Debug.LogError("placeFurniture is NULL in DuplicateSelected");
        }
    }
    public void ResetScene(string message)
    {
        Debug.Log($"=== ARManager.ResetScene called === Instance ID: {GetInstanceID()} GameObject: {gameObject.name}");
        if (placeFurniture != null)
        {
            placeFurniture.ResetScene();
        }
        else
        {
            Debug.LogError("placeFurniture is NULL in ResetScene");
        }
    }

    public void ToggleLock(string message)
    {
        if (_selector == null || !_selector.HasSelection) return;
        var lockComp = _selector.SelectedObject.GetComponent<FurnitureLock>();
        lockComp?.Toggle();
    }

    public void TakeScreenshot(string message)
    {
        var uiManager = FindObjectOfType<ARUIManager>();
        uiManager?.TakeScreenshot();
    }

    public void StartCamera(string message = "")
    {
        var arSession = FindObjectOfType<ARSession>();
        if (arSession != null)
        {
            arSession.enabled = true;
            arSession.Reset();
        }
        var arCameraManager = FindObjectOfType<ARCameraManager>();
        if (arCameraManager != null)
            arCameraManager.enabled = true;
    }

    public void StopCamera(string message = "")
    {
        var arSession = FindObjectOfType<ARSession>();
        if (arSession != null) arSession.enabled = false;
        var arCameraManager = FindObjectOfType<ARCameraManager>();
        if (arCameraManager != null) arCameraManager.enabled = false;
    }

    public void NotifyScreenshotSaved(string path)
    {
        SendToFlutter($"ScreenshotSaved:{path}");
    }


    public void NotifyTileCount(int count, string tileName)
    {
        SendToFlutter($"TileCount:{count}|{tileName}");
    }

    // Flutter button receivers
    public void SwitchToFurnitureMode(string message)
    {
        Debug.Log("ARManager: Switching to Furniture mode from Flutter");
        SetMode(ARMode.Furniture);
    }

    public void SwitchToTileMode(string message)
    {
        Debug.Log("ARManager: Switching to Tile mode from Flutter");
        SetMode(ARMode.Tile);
    }

    public void ClearAll(string message)
    {
        if (tilePlacementSystem != null)
        {
            tilePlacementSystem.ClearAll();
        }
    }

    void Update()
    {
        if (!useLocalPrefabForTesting && isInitialized)
        {
            if (Input.GetKeyDown(KeyCode.L))
                StartCoroutine(LoadPrefabByKey(editorTestKey));
            if (Input.GetKeyDown(KeyCode.K))
            {
                string fakeMessage = JsonUtility.ToJson(new ProductMessage
                {
                    productId = "test-001",
                    name = "Test Cabinet",
                    addressableKey = editorTestKey,
                    placementType = "HorizontalOnly",
                    category = "furniture"
                });
                OnProductSelected(fakeMessage);
            }
        }

        // Press M to toggle between Furniture and Tile mode
        if (Input.GetKeyDown(KeyCode.M))
        {
            if (currentMode == ARMode.Furniture)
            {
                Debug.Log("Switching to Tile Mode (Editor Test)");
                SetMode(ARMode.Tile);
            }
            else
            {
                Debug.Log("Switching to Furniture Mode (Editor Test)");
                SetMode(ARMode.Furniture);
            }
        }

        // Press F to force Furniture mode
        if (Input.GetKeyDown(KeyCode.F))
        {
            Debug.Log("Force Furniture Mode");
            SetMode(ARMode.Furniture);
        }

        // Press G to force Tile mode  
        if (Input.GetKeyDown(KeyCode.G))
        {
            Debug.Log("Force Tile Mode");
            SetMode(ARMode.Tile);
        }
    }

    [System.Serializable]
    class ProductMessage
    {
        public string productId;
        public string name;
        public string addressableKey;
        public string placementType;
        public string category;
    }
}
