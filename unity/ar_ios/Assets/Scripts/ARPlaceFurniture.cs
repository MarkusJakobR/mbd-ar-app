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
    public bool HasPlacedObjects => _placedObjects.Count > 0;
    private bool _rotatingClockwise = false;
    private bool _rotatingCounter = false;
    private bool _isDuplicating = false;
    private bool _isResetting = false;

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

        // Handle rotation from Flutter buttons
        if (_selector != null && _selector.HasSelection)
        {
            var lockComp = _selector.SelectedObject.GetComponent<FurnitureLock>();
            bool isLocked = lockComp != null && lockComp.IsLocked;

            if (!isLocked)
            {
                if (_rotatingClockwise)
                {

                    Debug.Log("Update: Rotating clockwise NOW");
                    _selector.SelectedObject.transform.Rotate(
                        Vector3.up, 100f * Time.deltaTime * rotationSpeed, Space.World);
                }
                if (_rotatingCounter)
                {
                    Debug.Log("Update: Rotating counter NOW");
                    _selector.SelectedObject.transform.Rotate(
                        Vector3.up, -100f * Time.deltaTime * rotationSpeed, Space.World);
                }
            }
            else
            {
                Debug.Log("Update: Object is LOCKED, cannot rotate");

            }
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
            var lockComp = _selector.SelectedObject.GetComponent<FurnitureLock>();
            if (lockComp != null && lockComp.IsLocked) return;

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
            var lockComp = _selector.SelectedObject.GetComponent<FurnitureLock>();
            bool isLocked = lockComp != null && lockComp.IsLocked;

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
            newObject.AddComponent<FurnitureLock>();

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
        yield return null; // wait one frame
        yield return null; // wait one frame
        _selector.Select(obj);
    }

    void TryMoveSelected(Vector2 screenPosition)
    {

        if (!_selector.HasSelection) return;

        // Check this specific object's lock state
        var lockComp = _selector.SelectedObject.GetComponent<FurnitureLock>();
        if (lockComp != null && lockComp.IsLocked) return;

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
        Debug.Log("=== DuplicateSelected START ===");

        // Prevent re-entry
        if (_isDuplicating)
        {
            Debug.LogWarning("DuplicateSelected already in progress - ignoring");
            return;
        }

        _isDuplicating = true;
        Debug.Log($"_placedObjects count BEFORE: {_placedObjects.Count}");

        if (!_selector.HasSelection)
        {
            Debug.Log("No selection, aborting");
            _isDuplicating = false;
            return;
        }

        var original = _selector.SelectedObject;
        Debug.Log($"Duplicating: {original.name}");

        var duplicate = Instantiate(
            original,
            original.transform.position + Vector3.right * 0.5f,
            original.transform.rotation
        );

        Debug.Log($"Instantiated: {duplicate.name}");

        // Remove ALL components that might have been copied
        var existingIndicator = duplicate.GetComponent<SelectionIndicator>();
        if (existingIndicator != null)
        {
            Debug.Log("Destroying existing SelectionIndicator");
            Destroy(existingIndicator);
        }

        var existingLock = duplicate.GetComponent<FurnitureLock>();
        if (existingLock != null)
        {
            Debug.Log("Destroying existing FurnitureLock");
            Destroy(existingLock);
        }

        // Add fresh components
        duplicate.AddComponent<SelectionIndicator>();
        duplicate.AddComponent<FurnitureLock>();
        Debug.Log("Added fresh components");

        // Track it properly
        _placedObjects.Add(duplicate);
        Debug.Log($"_placedObjects count AFTER: {_placedObjects.Count}");

        var uiManager = FindObjectOfType<ARUIManager>();
        uiManager?.ShowTapToPlaceHint(false);

        Debug.Log("=== DuplicateSelected END ===");

        _isDuplicating = false;
    }

    public void ResetScene()
    {
        if (_isResetting)
        {
            Debug.LogWarning("ResetScene already in progress - ignoring");
            return;
        }

        _isResetting = true;
        Debug.Log("=== ResetScene START ===");
        ClearScene();
        Debug.Log("=== ResetScene END ===");
        _isResetting = false;
    }

    public void StartRotating(bool clockwise)
    {
        Debug.Log($"ARPlaceFurniture: StartRotating called with clockwise={clockwise}");
        if (clockwise)
        {
            _rotatingClockwise = true;
            Debug.Log("ARPlaceFurniture: _rotatingClockwise set to TRUE");
        }
        else
        {
            _rotatingCounter = true;
            Debug.Log("ARPlaceFurniture: _rotatingCounter set to TRUE");
        }
    }

    public void StopRotating()
    {
        Debug.Log("ARPlaceFurniture: StopRotating called");
        _rotatingClockwise = false;
        _rotatingCounter = false;
        Debug.Log("ARPlaceFurniture: Both rotation flags set to FALSE");
    }
}
