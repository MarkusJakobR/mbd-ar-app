using UnityEngine;
using System.Collections;
using UnityEngine.XR.ARFoundation;

public class ARUIManager : MonoBehaviour
{
    // public void ShowTapToPlaceHint(bool show)
    // {
    //     if (tapToPlaceHint != null)
    //         tapToPlaceHint.SetActive(show);
    // }

    public void TakeScreenshot()
    {
        StartCoroutine(CaptureScreenshot());
    }

    IEnumerator CaptureScreenshot()
    {
        // Hide hint during screenshot
        // if (tapToPlaceHint != null)
        //     tapToPlaceHint.SetActive(false);

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
        // var placeFurniture = FindObjectOfType<ARPlaceFurniture>();
        // if (tapToPlaceHint != null)
        //     ShowTapToPlaceHint(
        //         placeFurniture != null && !placeFurniture.HasPlacedObjects);

        Debug.Log($"Screenshot saved: {path}");

        // Notify Flutter with the file path
        var arManager = FindObjectOfType<ARManager>();
        arManager?.NotifyScreenshotSaved(path);
    }

    public void TakeScreenshotTile()
    {
        StartCoroutine(CaptureScreenshotTile());
    }

    IEnumerator CaptureScreenshotTile()
    {
        var tilePlacementSystem = FindObjectOfType<TilePlacementSystem>();

        // Hide markers and boundary lines
        tilePlacementSystem?.HideMarkersForScreenshot(false);

        // Hide AR planes
        var planes = FindObjectsOfType<ARPlane>();
        foreach (var plane in planes)
            foreach (var r in plane.GetComponentsInChildren<Renderer>())
                r.enabled = false;

        yield return new WaitForEndOfFrame();

        var texture = ScreenCapture.CaptureScreenshotAsTexture();
        var bytes = texture.EncodeToPNG();
        var path = System.IO.Path.Combine(
            Application.persistentDataPath,
            $"AR_Tile_{System.DateTime.Now:yyyyMMdd_HHmmss}.png"
        );
        System.IO.File.WriteAllBytes(path, bytes);
        Destroy(texture);

        // Restore based on current visibility state
        tilePlacementSystem?.RestoreMarkersAfterScreenshot();

        // Restore planes
        foreach (var plane in planes)
            foreach (var r in plane.GetComponentsInChildren<Renderer>())
                r.enabled = true;

        Debug.Log($"Tile screenshot saved: {path}");

        var arManager = FindObjectOfType<ARManager>();
        arManager?.NotifyScreenshotSaved(path);
    }
}
