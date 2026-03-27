using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using System.Collections;
using UnityEngine.XR.ARFoundation;

public class ARManager : MonoBehaviour
{
    [SerializeField] private ARPlaceFurniture placeFurniture;
    [SerializeField] private bool useLocalPrefabForTesting = true;

    // Editor testing — set this to whatever addressable key you want to test with
    [SerializeField] private string editorTestKey = "brown_cabinet";

    private bool isInitialized = false;

    void Start()
    {
        if (!useLocalPrefabForTesting)
            StartCoroutine(InitializeAddressables());
        else
            StartCamera();
    }

    IEnumerator InitializeAddressables()
    {
        Debug.Log("Initializing Addressables...");

        // Correct way to init in 1.21+ — just yield on the handle directly
        yield return Addressables.InitializeAsync();

        Debug.Log("Addressables initialized — loading remote catalog...");

        string catalogUrl = "https://crczirzejyiyliizruyy.supabase.co/storage/v1/object/public/asset-storage/temp_addressables/iOS/catalog_catalog.json";

        var catalogHandle = Addressables.LoadContentCatalogAsync(catalogUrl);
        yield return catalogHandle;

        // Check result AFTER yielding, not via Status on the handle
        if (catalogHandle.Result == null)
        {
            Debug.LogError("Catalog loaded but result is null — check your Supabase URL");
            Addressables.Release(catalogHandle);
            yield break;
        }

        Debug.Log("Remote catalog loaded successfully");
        Addressables.Release(catalogHandle);
        isInitialized = true;

        // Notify Flutter that Unity is ready to receive product data
#if !UNITY_EDITOR
        SendMessageToFlutter("OnUnityReady", "true");
#else
    Debug.Log("Unity ready — would notify Flutter here");
#endif
    }

    // Called by Flutter via postMessage('ARManager', 'OnProductSelected', json)
    public void OnProductSelected(string jsonMessage)
    {
        if (useLocalPrefabForTesting)
        {
            Debug.Log("Testing mode — using Inspector prefab, ignoring message");
            return;
        }

        if (!isInitialized)
        {
            Debug.LogWarning("Addressables not ready yet — try again in a moment");
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
            Debug.LogError("Failed to load prefab — key not found: " + key);
            Addressables.Release(handle);
        }
    }

    void SendMessageToFlutter(string methodName, string message)
    {
        // flutter_unity_widget receives this via onUnityMessage callback
        using (var unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
        {
            // On iOS this is handled differently — flutter_unity_widget
            // intercepts NativeAPI.sendMessageToFlutter automatically
        }
    }

    // Temporary editor test — press L to simulate loading a product
    void Update()
    {
        if (!useLocalPrefabForTesting && isInitialized)
        {
            // L = load directly by key (quick test)
            if (Input.GetKeyDown(KeyCode.L))
                StartCoroutine(LoadPrefabByKey(editorTestKey));

            // K = simulate a full Flutter message (tests the whole pipeline)
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

    public void ResetScene()
    {
        placeFurniture.ClearScene();
        Debug.Log("Scene reset");
    }

    public void StopCamera()
    {
        var arSession = FindObjectOfType<ARSession>();
        if (arSession != null)
        {
            arSession.enabled = false;
            Debug.Log("AR Session disabled — camera released");
        }

        var arCameraManager = FindObjectOfType<ARCameraManager>();
        if (arCameraManager != null)
            arCameraManager.enabled = false;
    }

    public void StartCamera()
    {

        var arSession = FindObjectOfType<ARSession>();
        if (arSession != null)
        {
            arSession.enabled = true;
            // Reset the session so plane detection restarts cleanly
            arSession.Reset();
            Debug.Log("AR Session enabled and reset — camera started");
        }

        var arCameraManager = FindObjectOfType<ARCameraManager>();
        if (arCameraManager != null)
            arCameraManager.enabled = true;
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
