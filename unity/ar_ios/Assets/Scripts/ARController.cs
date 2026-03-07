using UnityEngine;
using UnityEngine.XR.ARFoundation;

public class ARController : MonoBehaviour
{
    private ARSession arSession;
    private ARCameraManager arCameraManager;

    void Start()
    {
        arSession = FindObjectOfType<ARSession>();
        arCameraManager = FindObjectOfType<ARCameraManager>();
        
        Debug.Log("ARController initialized");
    }

    // Called from Flutter to stop AR
    public void StopAR()
    {
        Debug.Log("Stopping AR session and camera...");
        
        if (arCameraManager != null)
        {
            arCameraManager.enabled = false;
        }
        
        if (arSession != null)
        {
            arSession.enabled = false;
        }
    }

    // Called from Flutter to resume AR
    public void StartAR()
    {
        Debug.Log("Starting AR session and camera...");
        
        if (arSession != null)
        {
            arSession.enabled = true;
        }
        
        if (arCameraManager != null)
        {
            arCameraManager.enabled = true;
        }
    }
}
