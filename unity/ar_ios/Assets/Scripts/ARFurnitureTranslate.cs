using UnityEngine;

public class FurnitureInteraction : MonoBehaviour
{
    private float rotationSpeed = 500f;
    private Camera cam;

    void Start()
    {
        cam = Camera.main;
    }

    // Handles Moving (Dragging)
    void OnMouseDrag()
    {
        // For moving, we project the mouse/touch onto the horizontal plane
        Ray ray = cam.ScreenPointToRay(Input.mousePosition);
        if (Physics.Raycast(ray, out RaycastHit hit))
        {
            // Only move if we hit an AR Plane or the ground
            // Make sure your AR Planes have a 'Layer' named "Planes" or similar
            transform.position = new Vector3(hit.point.x, transform.position.y, hit.point.z);
        }
    }

    // Handles Rotating (Right Click + Drag or Two Fingers)
    void Update()
    {
        // Laptop Testing: Right-click drag to rotate
        if (Input.GetMouseButton(1))
        {
            float rotX = Input.GetAxis("Mouse X") * rotationSpeed * Time.deltaTime;
            transform.Rotate(Vector3.up, -rotX);
        }

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
