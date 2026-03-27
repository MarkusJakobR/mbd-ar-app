using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;

[RequireComponent(typeof(ARRaycastManager))]
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

    static readonly List<ARRaycastHit> rayHits = new List<ARRaycastHit>();

    void Start()
    {
        // Cache ARPlaneManager once instead of finding it every raycast
        planeManager = FindObjectOfType<ARPlaneManager>();

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
        if (spawnedObject != null)
        {
            if (isDragging)
            {
                spawnedObject.transform.position = Vector3.Lerp(
                    spawnedObject.transform.position,
                    targetPosition,
                    Time.deltaTime * moveSmoothing
                );
            }

            Vector3 euler = spawnedObject.transform.eulerAngles;
            spawnedObject.transform.eulerAngles = new Vector3(0f, euler.y, 0f);
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

            // Single finger: place or drag
            if (touch.phase == TouchPhase.Began || touch.phase == TouchPhase.Moved)
            {
                TryRaycast(touch.position);
            }

            if (touch.phase == TouchPhase.Ended)
            {
                isDragging = false;
            }
        }
        else if (Input.touchCount == 2 && spawnedObject != null)
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
                spawnedObject.transform.Rotate(Vector3.up, -delta * rotationSpeed, Space.World);
                previousPinchAngle = currentAngle;
            }
        }
    }

    void HandleMouseFallback()
    {
        // Editor / desktop testing only
        if (Input.GetMouseButton(0))
        {
            TryRaycast(Input.mousePosition);
        }
        if (Input.GetMouseButtonUp(0))
        {
            isDragging = false;
        }
        if (spawnedObject != null)
        {
            if (Input.GetKey(KeyCode.R))
            {
                spawnedObject.transform.Rotate(Vector3.up, rotationSpeed * 100f * Time.deltaTime, Space.World);
            }
            if (Input.GetKey(KeyCode.T))
            {
                spawnedObject.transform.Rotate(Vector3.up, -rotationSpeed * 100f * Time.deltaTime, Space.World);
            }
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

                ApplyWallRotationIfNeeded(hitPose);
                targetPosition = hitPose.position;
            }
            else
            {
                targetPosition = hitPose.position;
                isDragging = true;
            }
        }
    }
    void ApplyWallRotationIfNeeded(Pose hitPose)
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
        if (spawnedObject != null)
        {
            Destroy(spawnedObject);
            spawnedObject = null;
        }
        isDragging = false;
    }
}
