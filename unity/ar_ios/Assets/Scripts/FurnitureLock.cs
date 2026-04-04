using UnityEngine;

public class FurnitureLock : MonoBehaviour
{
    public bool IsLocked { get; private set; } = false;

    public void Lock()
    {
        IsLocked = true;
        Debug.Log($"{gameObject.name} locked");
    }

    public void Unlock()
    {
        IsLocked = false;
        Debug.Log($"{gameObject.name} unlocked");
    }

    public void Toggle()
    {
        if (IsLocked) Unlock();
        else Lock();
    }
}
