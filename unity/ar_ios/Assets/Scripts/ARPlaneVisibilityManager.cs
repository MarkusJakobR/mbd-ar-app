using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;

public class ARPlaneVisibilityManager : MonoBehaviour
{
    private ARPlaneManager planeManager;
    private FurniturePlacementType currentPlacementType = FurniturePlacementType.Any;

    void Start()
    {
        planeManager = FindObjectOfType<ARPlaneManager>();

        if (planeManager != null)
            planeManager.planesChanged += OnPlanesChanged;

        RefreshAllPlaneVisibility();
    }

    void OnDestroy()
    {
        if (planeManager != null)
            planeManager.planesChanged -= OnPlanesChanged;
    }

    // Call this from ARPlaceFurniture whenever the prefab changes
    public void SetPlacementType(FurniturePlacementType placementType)
    {
        currentPlacementType = placementType;
        RefreshAllPlaneVisibility();
    }

    void OnPlanesChanged(ARPlanesChangedEventArgs args)
    {
        foreach (var plane in args.added)
        {

            UpdatePlaneVisibility(plane);
            AddColliderToPlane(plane);
        }

        foreach (var plane in args.updated)
        {

            UpdatePlaneVisibility(plane);

            // Keep the collider mesh in sync as AR refines the plane
            var meshCollider = plane.GetComponent<MeshCollider>();
            if (meshCollider != null)
                meshCollider.sharedMesh = plane.GetComponent<MeshFilter>()?.sharedMesh;
        }
    }

    void AddColliderToPlane(ARPlane plane)
    {
        // Avoid adding duplicate colliders
        if (plane.GetComponent<MeshCollider>() != null) return;

        var meshCollider = plane.gameObject.AddComponent<MeshCollider>();
        meshCollider.sharedMesh = plane.GetComponent<MeshFilter>()?.sharedMesh;

        // Tag it so furniture can identify what it's hitting
        plane.gameObject.tag = "ARPlane";
    }

    void RefreshAllPlaneVisibility()
    {
        if (planeManager == null) return;

        foreach (var plane in planeManager.trackables)
            UpdatePlaneVisibility(plane);
    }

    void UpdatePlaneVisibility(ARPlane plane)
    {
        bool shouldShow = currentPlacementType switch
        {
            FurniturePlacementType.HorizontalOnly =>
                plane.alignment == PlaneAlignment.HorizontalUp ||
                plane.alignment == PlaneAlignment.HorizontalDown,
            FurniturePlacementType.VerticalOnly =>
                plane.alignment == PlaneAlignment.Vertical,
            _ => true
        };

        // Use GetComponentsInChildren to reach renderers on child objects
        foreach (var renderer in plane.GetComponentsInChildren<MeshRenderer>())
            renderer.enabled = shouldShow;

        foreach (var renderer in plane.GetComponentsInChildren<LineRenderer>())
            renderer.enabled = shouldShow;
    }
}
