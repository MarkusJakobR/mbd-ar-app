using UnityEngine;
using System.Collections;
using UnityEngine.XR.ARFoundation;

public class ARUIManager : MonoBehaviour
{
    [Header("UI")]
    [SerializeField] private GameObject tapToPlaceHint;

    public void ShowTapToPlaceHint(bool show)
    {
        if (tapToPlaceHint != null)
            tapToPlaceHint.SetActive(show);
    }

    public void TakeScreenshot()
    {
        StartCoroutine(CaptureScreenshot());
    }

    IEnumerator CaptureScreenshot()
    {
        // Hide hint during screenshot
        if (tapToPlaceHint != null)
            tapToPlaceHint.SetActive(false);

        // Hide plane visualizations
        var planes = FindObjectsOfType<ARPlane>();
        foreach (var plane in planes)
            foreach (var r in plane.GetComponentsInChildren<Renderer>())
                r.enabled = false;

        yield return new WaitForEndOfFrame();

        var texture = ScreenCapture.CaptureScreenshotAsTexture();
        var bytes = texture.EncodeToPNG();
        var path = System.IO.Path.Combine(
            Application.persistentDataPath,
            $"AR_{System.DateTime.Now:yyyyMMdd_HHmmss}.png"
        );
        System.IO.File.WriteAllBytes(path, bytes);
        Destroy(texture);

        // Restore planes
        foreach (var plane in planes)
            foreach (var r in plane.GetComponentsInChildren<Renderer>())
                r.enabled = true;

        // Restore hint if no objects placed
        var placeFurniture = FindObjectOfType<ARPlaceFurniture>();
        if (tapToPlaceHint != null)
            ShowTapToPlaceHint(
                placeFurniture != null && !placeFurniture.HasPlacedObjects);

        Debug.Log($"Screenshot saved: {path}");

        // Notify Flutter with the file path
        var arManager = FindObjectOfType<ARManager>();
        arManager?.NotifyScreenshotSaved(path);
    }
}
