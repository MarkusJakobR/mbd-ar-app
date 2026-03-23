using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum FurniturePlacementType
{
    HorizontalOnly,  // tables, desks, cabinets, tiles (floor)
    VerticalOnly,    // doors, wall panels
    Any              // flexible items
}

public class FurnitureData : MonoBehaviour
{
    public FurniturePlacementType placementType = FurniturePlacementType.HorizontalOnly;
}
