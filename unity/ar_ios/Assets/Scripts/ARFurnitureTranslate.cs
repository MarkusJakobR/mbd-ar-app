using UnityEngine;

public class FurnitureInteraction : MonoBehaviour
{
    private Camera cam;

    void Start()
    {
        cam = Camera.main;
    }

    // Handles Rotating (Right Click + Drag or Two Fingers)
    void Update()
    {
        // Mobile: Two-finger twist (Standard AR logic)
        if (Input.touchCount == 2)
        {
            Touch touch0 = Input.GetTouch(0);
            Touch touch1 = Input.GetTouch(1);

            if (touch0.phase == TouchPhase.Moved || touch1.phase == TouchPhase.Moved)
            {
                Vector2 prevDir = (touch0.position - touch0.deltaPosition) - (touch1.position - touch1.deltaPosition);
                Vector2 currDir = touch0.position - touch1.position;
                float angle = Vector2.SignedAngle(prevDir, currDir);
                transform.Rotate(Vector3.up, -angle);
            }
        }
    }
}
