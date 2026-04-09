using UnityEngine;
using UnityEngine.XR.ARSubsystems;
using UnityEngine.XR.ARFoundation;

public class FurniturePlacementValidator : MonoBehaviour
{
    [SerializeField] private Material invalidMaterial;  // red/transparent invalid material

    private bool isInvalid = false;
    private Renderer[] renderers;
    private Material[] originalMaterials;
    private FurnitureData furnitureData;
    private Collider furnitureCollider;

    void Start()
    {
        renderers = GetComponentsInChildren<Renderer>();
        furnitureData = GetComponent<FurnitureData>();
        furnitureCollider = GetComponent<Collider>();

        // Cache the original materials so we can restore them later
        originalMaterials = new Material[renderers.Length];
        for (int i = 0; i < renderers.Length; i++)
            originalMaterials[i] = renderers[i].material;
    }

    void Update()
    {
        CheckValidityThisFrame();
    }

    void CheckValidityThisFrame()
    {
        if (furnitureCollider == null || furnitureData == null) return;

        // Sweep for all overlapping colliders this frame
        Collider[] hits = Physics.OverlapBox(
            furnitureCollider.bounds.center,
            furnitureCollider.bounds.extents,
            transform.rotation
        );

        bool foundInvalid = false;
        foreach (var hit in hits)
        {
            if (hit == furnitureCollider) continue; // ignore self

            // Check 1: Invalid plane alignment
            var plane = hit.GetComponent<ARPlane>();
            if (plane != null && IsInvalidAlignment(plane.alignment))
            {
                foundInvalid = true;
                break;
            }

            // Check 2: Collision with another furniture object
            var otherFurniture = hit.GetComponent<FurnitureData>();
            if (otherFurniture != null && hit.gameObject != gameObject)
            {
                Debug.Log($"{gameObject.name} overlapping with {hit.gameObject.name}");
                foundInvalid = true;
                break;
            }

        }
        // Only update material if state actually changed — avoids unnecessary material swaps
        if (foundInvalid != isInvalid)
            SetInvalidAppearance(foundInvalid);
    }

    bool IsInvalidAlignment(PlaneAlignment alignment)
    {
        return furnitureData.placementType switch
        {
            FurniturePlacementType.HorizontalOnly =>
                alignment == PlaneAlignment.Vertical,
            FurniturePlacementType.VerticalOnly =>
                alignment == PlaneAlignment.HorizontalUp ||
                alignment == PlaneAlignment.HorizontalDown,
            _ => false
        };
    }

    void SetInvalidAppearance(bool invalid)
    {
        isInvalid = invalid;
        for (int i = 0; i < renderers.Length; i++)
            renderers[i].material = invalid ? invalidMaterial : originalMaterials[i];
    }

    public bool IsPlacementValid() => !isInvalid;
}
