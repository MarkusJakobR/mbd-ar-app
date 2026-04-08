using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

public class ARObjectSelector : MonoBehaviour
{
    public static ARObjectSelector Instance { get; private set; }

    private GameObject _selectedObject;
    private ARPlaceFurniture _placeFurniture;

    // Events other scripts can listen to
    public event System.Action<GameObject> OnObjectSelected;
    public event System.Action OnObjectDeselected;

    void Awake()
    {
        Instance = this;
        _placeFurniture = FindObjectOfType<ARPlaceFurniture>();
    }

    public GameObject SelectedObject => _selectedObject;
    public bool HasSelection => _selectedObject != null;

    public void Select(GameObject obj)
    {
        if (_selectedObject == obj) return;

        // Deselect previous
        if (_selectedObject != null)
            OnObjectDeselected?.Invoke();

        _selectedObject = obj;
        OnObjectSelected?.Invoke(obj);

        // Send lock state to Flutter
        var lockComp = obj.GetComponent<FurnitureLock>();
        bool isLocked = lockComp != null && lockComp.IsLocked;
        var manager = FindObjectOfType<ARManager>();
        if (manager != null)
            manager.SendLockStateToFlutter(isLocked);

        Debug.Log($"Selected: {obj.name}");
    }

    public void Deselect()
    {
        if (_selectedObject == null) return;
        _selectedObject = null;
        OnObjectDeselected?.Invoke();
    }

    public void DeleteSelected()
    {

        if (_selectedObject == null) return;

        // Remove from ARPlaceFurniture tracking
        var placeFurniture = FindObjectOfType<ARPlaceFurniture>();
        placeFurniture?.RemoveFromTracking(_selectedObject);

        Destroy(_selectedObject);
        _selectedObject = null;
        OnObjectDeselected?.Invoke();
    }
}
