using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using System.Collections;
using UnityEngine.XR.ARFoundation;
using FlutterUnityIntegration;

public class ARManager : MonoBehaviour
{
    [SerializeField] private ARPlaceFurniture placeFurniture;
    [SerializeField] private bool useLocalPrefabForTesting = true;
    [SerializeField] private string editorTestKey = "brown_cabinet";

    private bool isInitialized = false;
    private ARObjectSelector _selector;
    private UnityMessageManager _messageManager;

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

    public void OnTileSelected(string jsonMessage)
    {
        SetMode(ARMode.Tile);

        var data = JsonUtility.FromJson<ProductMessage>(jsonMessage);
        Debug.Log($"Tile selected: {data.name}");

        if (tilePlacementSystem != null)
        {
            // Create TileData from product message
            // You'll need to implement this based on your tile data structure
            tilePlacementSystem.enabled = true;
        }
    }

    public void ClearTiles(string message)
    {
        if (tilePlacementSystem != null)
        {
            tilePlacementSystem.ClearTiles();
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
