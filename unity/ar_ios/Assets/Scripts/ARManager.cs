using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using System.Collections;

public class ARManager : MonoBehaviour
{
    [SerializeField] private ARPlaceFurniture placeFurniture;
    [SerializeField] private bool useLocalPrefabForTesting = true;

    private bool isInitialized = false;

    void Start()
    {
        if (!useLocalPrefabForTesting)
            StartCoroutine(InitializeAddressables());
    }

    IEnumerator InitializeAddressables()
    {
        Debug.Log("Initializing Addressables...");

        // Correct way to init in 1.21+ — just yield on the handle directly
        yield return Addressables.InitializeAsync();

        Debug.Log("Addressables initialized — loading remote catalog...");

        string catalogUrl = "https://crczirzejyiyliizruyy.supabase.co/storage/v1/object/public/asset-storage/temp_addressables/iOS/catalog_1.0.0.json";

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

        var data = JsonUtility.FromJson<ProductMessage>(jsonMessage);
        StartCoroutine(LoadPrefabByKey(data.addressableKey));
    }

    IEnumerator LoadPrefabByKey(string key)
    {
        Debug.Log("Loading prefab with key: " + key);

        var handle = Addressables.LoadAssetAsync<GameObject>(key);
        yield return handle;

        if (handle.Result != null)
        {
            Debug.Log("Prefab loaded: " + key);
            placeFurniture.SetFurniturePrefab(handle.Result);
        }
        else
        {
            Debug.LogError("Failed to load prefab — key not found: " + key);
            Addressables.Release(handle);
        }
    }

    // Temporary editor test — press L to simulate loading a product
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.L) && isInitialized)
            StartCoroutine(LoadPrefabByKey("Assets/Prefabs/BrownCabinetPrefab.prefab"));
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
