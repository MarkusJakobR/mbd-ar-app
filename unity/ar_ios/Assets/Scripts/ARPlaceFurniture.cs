using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;

public class ARPlaceFurniture : MonoBehaviour
{
    [SerializeField] private ARRaycastManager raycastManager;
    [SerializeField] private GameObject furniturePrefab;   // assign your prefab here directly
    [SerializeField] private float moveSmoothing = 12f;    // higher = snappier drag
    [SerializeField] private float rotationSpeed = 0.8f;   // degrees per pixel of pinch rotation
    [SerializeField] private ARPlaneVisibilityManager planeVisibilityManager;

    private GameObject spawnedObject;
    private bool isDragging = false;
    private Vector3 targetPosition;
    private float previousPinchAngle;
    private TrackableType activePlaneType;
    private ARPlaneManager planeManager;
    private bool _isDraggingObject = false;
    private ARObjectSelector _selector;
    private bool _hasPlacedFirstObject;
    private List<GameObject> _placedObjects = new List<GameObject>();

    static readonly List<ARRaycastHit> rayHits = new List<ARRaycastHit>();

    void Start()
    {
        // Cache ARPlaneManager once instead of finding it every raycast
        planeManager = FindObjectOfType<ARPlaneManager>();
        _selector = FindObjectOfType<ARObjectSelector>();

        if (furniturePrefab != null)
        {

            activePlaneType = GetPlaneTypeForPrefab(furniturePrefab);
            FurnitureData data = furniturePrefab.GetComponent<FurnitureData>();
            if (data != null && planeVisibilityManager != null)
                planeVisibilityManager.SetPlacementType(data.placementType);
        }
        else
            activePlaneType = TrackableType.PlaneWithinPolygon;
    }

    void Update()
    {
        if (!raycastManager) return;

        HandleTouch();
        HandleMouseFallback();

        // Smoothly move the object toward the target position (avoids glitch snapping)
        if (_selector != null && _selector.HasSelection && isDragging)
        {
            _selector.SelectedObject.transform.position = Vector3.Lerp(
                _selector.SelectedObject.transform.position,
                targetPosition,
                Time.deltaTime * moveSmoothing
            );

            // Lock upright
            Vector3 euler = _selector.SelectedObject.transform.eulerAngles;
            _selector.SelectedObject.transform.eulerAngles =
                new Vector3(0f, euler.y, 0f);
        }
    }

    TrackableType GetPlaneTypeForPrefab(GameObject prefab)
    {
        return TrackableType.PlaneWithinPolygon;
    }

    void HandleTouch()
    {
        if (Input.touchCount == 1)
        {
            Touch touch = Input.GetTouch(0);

            // tap only
            if (touch.phase == TouchPhase.Began)
            {
                // Check if touch hit an AR object
                var hitObject = GetTouchedObject(touch.position);

                if (hitObject != null)
                {
                    // Select the tapped object
                    _selector.Select(hitObject);
                    _isDraggingObject = true;
                }
                else
                {
                    // Tapped empty space
                    if (_selector.HasSelection)
                        _selector.Deselect();
                    else if (!_hasPlacedFirstObject)
                        TryPlaceObject(touch.position); // place new object
                }
            }

            if (touch.phase == TouchPhase.Moved && _isDraggingObject)
            {
                // Drag selected object along the plane
                if (_selector.HasSelection)
                    TryMoveSelected(touch.position);
            }

            if (touch.phase == TouchPhase.Ended)
            {
                isDragging = false;
            }
        }
        else if (Input.touchCount == 2 && _selector.HasSelection)
        {
            // Two fingers: rotate
            Touch t0 = Input.GetTouch(0);
            Touch t1 = Input.GetTouch(1);

            float currentAngle = Mathf.Atan2(
                t1.position.y - t0.position.y,
                t1.position.x - t0.position.x
            ) * Mathf.Rad2Deg;

            if (t1.phase == TouchPhase.Began)
            {
                // Capture baseline angle when second finger first touches
                previousPinchAngle = currentAngle;
            }
            else if (t0.phase == TouchPhase.Moved || t1.phase == TouchPhase.Moved)
            {
                float delta = currentAngle - previousPinchAngle;
                _selector.SelectedObject.transform.Rotate(
                Vector3.up, -delta * rotationSpeed, Space.World);
                previousPinchAngle = currentAngle;
            }
        }
    }

    void HandleMouseFallback()
    {
        // Editor / desktop testing only
        if (Input.GetMouseButtonDown(0))
        {
            // Check if clicking on UI first
            if (EventSystem.current != null && EventSystem.current.IsPointerOverGameObject())
                return;

            var hitObject = GetTouchedObject(Input.mousePosition);

            if (hitObject != null)
            {
                _selector.Select(hitObject);
                _isDraggingObject = true;
            }
            else
            {
                if (_selector.HasSelection)
                    _selector.Deselect();
                else if (!_hasPlacedFirstObject)
                    TryPlaceObject(Input.mousePosition);
            }
        }

        if (Input.GetMouseButton(0) && _isDraggingObject)
        {
            if (_selector.HasSelection)
                TryMoveSelected(Input.mousePosition);
        }

        if (Input.GetMouseButtonUp(0))
        {
            _isDraggingObject = false;
            isDragging = false;
        }

        // Keyboard rotation — acts on selected object
        if (_selector != null && _selector.HasSelection)
        {
            if (Input.GetKey(KeyCode.R))
                _selector.SelectedObject.transform.Rotate(
                    Vector3.up, rotationSpeed * 100f * Time.deltaTime, Space.World);
            if (Input.GetKey(KeyCode.T))
                _selector.SelectedObject.transform.Rotate(
                    Vector3.up, -rotationSpeed * 100f * Time.deltaTime, Space.World);
        }
    }

    void TryRaycast(Vector2 screenPosition)
    {
        // Don't raycast if no prefab is loaded yet
        if (furniturePrefab == null) return;

        if (raycastManager.Raycast(screenPosition, rayHits, activePlaneType))
        {
            var hit = rayHits[0];
            FurnitureData data = furniturePrefab.GetComponent<FurnitureData>();

            Debug.Log($"TryRaycast — FurnitureData placementType: {data?.placementType}");

            if (data != null && !IsHitOnCorrectPlane(hit, data.placementType))
            {
                Debug.Log("TryRaycast — rejected, wrong plane");
                return;
            }

            Pose hitPose = rayHits[0].pose;

            if (spawnedObject == null)
            {
                spawnedObject = Instantiate(furniturePrefab, hitPose.position, Quaternion.identity);

                var spawnedData = spawnedObject.GetComponent<FurnitureData>();
                Debug.Log($"TryRaycast — spawned object placementType: {spawnedData?.placementType}");

                var validator = spawnedObject.GetComponent<FurniturePlacementValidator>();
                Debug.Log($"TryRaycast — FurniturePlacementValidator: {(validator != null ? "FOUND" : "NULL")}");

                ApplyWallRotationIfNeeded(hitPose, spawnedObject);
                targetPosition = hitPose.position;
            }
            else
            {
                targetPosition = hitPose.position;
                isDragging = true;
            }
        }
    }
    void ApplyWallRotationIfNeeded(Pose hitPose, GameObject spawnedObject)
    {
        FurnitureData data = furniturePrefab.GetComponent<FurnitureData>();
        if (data != null && data.placementType == FurniturePlacementType.VerticalOnly)
        {
            // face object outward when in wall
            spawnedObject.transform.rotation = Quaternion.LookRotation(hitPose.forward, Vector3.up);
        }
    }

    public void SetFurniturePrefab(GameObject newPrefab, string placementType = null)
    {
        furniturePrefab = newPrefab;
        activePlaneType = GetPlaneTypeForPrefab(newPrefab);

        // Override placement type from remote if provided
        if (!string.IsNullOrEmpty(placementType))
        {
            var data = newPrefab.GetComponent<FurnitureData>();

            Debug.Log($"SetFurniturePrefab — received placementType: {placementType}");
            Debug.Log($"SetFurniturePrefab — FurnitureData on prefab: {(data != null ? "FOUND" : "NULL")}");

            if (data != null && System.Enum.TryParse<FurniturePlacementType>(placementType, out var parsed))
            {
                data.placementType = parsed;
                Debug.Log($"SetFurniturePrefab — placementType set to: {data.placementType}");

                // activePlaneType = TrackableType.PlaneWithinPolygon;
            }
            else
            {
                Debug.LogWarning($"SetFurniturePrefab — failed to parse: {placementType}");
            }
        }
        else
        {
            Debug.LogWarning("SetFurniturePrefab — placementType was null or empty");
        }

        // Notify visibility manager
        FurnitureData furnitureData = newPrefab.GetComponent<FurnitureData>();
        Debug.Log($"SetFurniturePrefab — final placementType on prefab: {furnitureData?.placementType}");

        if (furnitureData != null && planeVisibilityManager != null)
            planeVisibilityManager.SetPlacementType(furnitureData.placementType);

        if (spawnedObject != null)
        {
            Destroy(spawnedObject);
            spawnedObject = null;
        }
    }

    bool IsHitOnCorrectPlane(ARRaycastHit hit, FurniturePlacementType placementType)
    {
        if (planeManager == null) return true;

        var plane = planeManager.GetPlane(hit.trackableId);
        if (plane == null) return true;

        return placementType switch
        {
            FurniturePlacementType.HorizontalOnly =>
                plane.alignment == PlaneAlignment.HorizontalUp ||
                plane.alignment == PlaneAlignment.HorizontalDown,
            FurniturePlacementType.VerticalOnly =>
                plane.alignment == PlaneAlignment.Vertical,
            _ => true
        };
    }

    public void ClearScene()
    {

        var uiManager = FindObjectOfType<ARUIManager>();

        foreach (var obj in _placedObjects)
        {
            if (obj != null) Destroy(obj);
        }
        _placedObjects.Clear();

        _selector?.Deselect();
        isDragging = false;
        _hasPlacedFirstObject = false;
        uiManager?.ShowTapToPlaceHint(true);
    }

    public void RemoveFromTracking(GameObject obj)
    {
        _placedObjects.Remove(obj);
        if (_placedObjects.Count == 0)
        {
            _hasPlacedFirstObject = false;
            var uiManager = FindObjectOfType<ARUIManager>();
            uiManager?.ShowTapToPlaceHint(true);
        }
    }

    GameObject GetTouchedObject(Vector2 screenPosition)
    {
        Ray ray = Camera.main.ScreenPointToRay(screenPosition);

        // Use IgnoreRaycastLayer check and include triggers
        RaycastHit[] hits = Physics.RaycastAll(ray, 100f);

        foreach (var hit in hits)
        {
            var target = hit.transform;
            while (target != null)
            {
                if (target.GetComponent<FurnitureData>() != null)
                    return target.gameObject;
                target = target.parent;
            }
        }
        return null;

    }

    void TryPlaceObject(Vector2 screenPosition)
    {
        if (furniturePrefab == null) return;

        if (raycastManager.Raycast(screenPosition, rayHits, activePlaneType))
        {
            var hit = rayHits[0];
            FurnitureData data = furniturePrefab.GetComponent<FurnitureData>();
            if (data != null && !IsHitOnCorrectPlane(hit, data.placementType)) return;

            Pose hitPose = hit.pose;
            var newObject = Instantiate(furniturePrefab, hitPose.position, Quaternion.identity);
            ApplyWallRotationIfNeeded(hitPose, newObject);

            // Add selection indicator to spawned object
            newObject.AddComponent<SelectionIndicator>();

            _placedObjects.Add(newObject);
            targetPosition = hitPose.position;
            _hasPlacedFirstObject = true;

            var uiManager = FindObjectOfType<ARUIManager>();
            uiManager?.ShowTapToPlaceHint(false);

            // Delay select by one frame so SelectionIndicator.Start() runs first
            StartCoroutine(SelectNextFrame(newObject));
        }
    }

    IEnumerator SelectNextFrame(GameObject obj)
    {
        yield return null; // wait one frame
        _selector.Select(obj);
    }

    void TryMoveSelected(Vector2 screenPosition)
    {

        var uiManager = FindObjectOfType<ARUIManager>();
        if (uiManager != null && uiManager.IsLocked) return;

        if (!_selector.HasSelection) return;

        if (raycastManager.Raycast(screenPosition, rayHits, activePlaneType))
        {
            var hit = rayHits[0];
            FurnitureData data = _selector.SelectedObject.GetComponent<FurnitureData>();
            if (data != null && !IsHitOnCorrectPlane(hit, data.placementType)) return;

            targetPosition = rayHits[0].pose.position;
            isDragging = true;
        }
    }

    public void DuplicateSelected()
    {
        if (!_selector.HasSelection) return;

        var original = _selector.SelectedObject;
        var duplicate = Instantiate(
            original,
            original.transform.position + Vector3.right * 0.5f,
            original.transform.rotation
        );

        // Add selection indicator since Instantiate copies components
        // but SelectionIndicator needs to be freshly added to subscribe to events
        var existingIndicator = duplicate.GetComponent<SelectionIndicator>();
        if (existingIndicator != null)
            Destroy(existingIndicator);

        duplicate.AddComponent<SelectionIndicator>();

        // Track it properly
        _placedObjects.Add(duplicate);

        var uiManager = FindObjectOfType<ARUIManager>();
        uiManager?.ShowTapToPlaceHint(false);

        // Select next frame so SelectionIndicator.Start() runs first
        StartCoroutine(SelectNextFrame(duplicate));
    }

    public void ResetScene()
    {
        ClearScene(); // ClearScene already handles everything correctly
    }
}
