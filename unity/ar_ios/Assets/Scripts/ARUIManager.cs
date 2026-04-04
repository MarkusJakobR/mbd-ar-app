using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;


public class ARUIManager : MonoBehaviour
{
    [Header("Right Side Buttons")]
    [SerializeField] private Button rotateClockwiseBtn;
    [SerializeField] private Button rotateCounterBtn;
    [SerializeField] private Button deleteBtn;
    [SerializeField] private Button lockBtn;
    [SerializeField] private Button screenshotBtn;

    [Header("Menu Buttons")]
    [SerializeField] private Button menuToggleBtn;
    [SerializeField] private GameObject menuPanel;
    [SerializeField] private Button resetBtn;
    [SerializeField] private Button duplicateBtn;
    [SerializeField] private Button helpBtn;

    [Header("References")]
    [SerializeField] private ARPlaceFurniture placeFurniture;
    [SerializeField] private ARObjectSelector selector;

    [Header("Variables")]
    [SerializeField] private float rotationSpeed = 100f;
    [SerializeField] private GameObject tapToPlaceHint;


    private bool _rotatingClockwise = false;
    private bool _rotatingCounter = false;
    private bool _menuOpen = false;
    private bool _isLocked = false;

    public bool IsLocked => _isLocked;

    void Start()
    {
        // Right side buttons
        AddPointerHold(rotateClockwiseBtn,
            () => _rotatingClockwise = true,
            () => _rotatingClockwise = false);

        AddPointerHold(rotateCounterBtn,
            () => _rotatingCounter = true,
            () => _rotatingCounter = false);
        deleteBtn.onClick.AddListener(DeleteSelected);
        lockBtn.onClick.AddListener(ToggleLock);
        screenshotBtn.onClick.AddListener(TakeScreenshot);

        // Menu buttons
        menuToggleBtn.onClick.AddListener(ToggleMenu);
        resetBtn.onClick.AddListener(ResetScene);
        duplicateBtn.onClick.AddListener(DuplicateSelected);
        helpBtn.onClick.AddListener(OpenHelp);

        menuPanel.SetActive(false);

        // Show/hide buttons based on selection
        selector.OnObjectSelected += _ => UpdateButtonVisibility(true);
        selector.OnObjectDeselected += () => UpdateButtonVisibility(false);
        UpdateButtonVisibility(false);
    }

    void AddPointerHold(Button btn, System.Action onDown, System.Action onUp)
    {
        var trigger = btn.gameObject.AddComponent<EventTrigger>();

        var down = new EventTrigger.Entry { eventID = EventTriggerType.PointerDown };
        down.callback.AddListener(_ => onDown());
        trigger.triggers.Add(down);

        var up = new EventTrigger.Entry { eventID = EventTriggerType.PointerUp };
        up.callback.AddListener(_ => onUp());
        trigger.triggers.Add(up);

        // Also handle pointer exit so releasing outside button still stops rotation
        var exit = new EventTrigger.Entry { eventID = EventTriggerType.PointerExit };
        exit.callback.AddListener(_ => onUp());
        trigger.triggers.Add(exit);
    }

    void Update()
    {
        if (selector.HasSelection && !_isLocked)
        {
            if (_rotatingClockwise)
                selector.SelectedObject.transform.Rotate(
                    Vector3.up, rotationSpeed * Time.deltaTime, Space.World);

            if (_rotatingCounter)
                selector.SelectedObject.transform.Rotate(
                    Vector3.up, -rotationSpeed * Time.deltaTime, Space.World);
        }
    }

    void UpdateButtonVisibility(bool hasSelection)
    {
        // These only make sense when something is selected
        rotateClockwiseBtn?.gameObject.SetActive(hasSelection);
        rotateCounterBtn?.gameObject.SetActive(hasSelection);
        deleteBtn?.gameObject.SetActive(hasSelection);
        lockBtn?.gameObject.SetActive(hasSelection);
    }

    public void ShowTapToPlaceHint(bool show)
    {
        if (tapToPlaceHint != null)
            tapToPlaceHint.SetActive(show);
        else
            Debug.LogWarning("tapToPlaceHint is not assigned in ARUIManager");
    }

    void RotateClockwise()
    {
        if (!selector.HasSelection || _isLocked) return;
        selector.SelectedObject.transform.Rotate(
            Vector3.up, rotationSpeed * 100f * Time.deltaTime, Space.World);
    }

    void RotateCounter()
    {
        if (!selector.HasSelection || _isLocked) return;
        selector.SelectedObject.transform.Rotate(
            Vector3.up, -rotationSpeed * 100f * Time.deltaTime, Space.World);

    }

    void DeleteSelected()
    {
        _isLocked = false;
        selector.DeleteSelected();
    }

    void ToggleLock()
    {
        if (!selector.HasSelection) return;
        _isLocked = !_isLocked;

        // Visual feedback on lock button
        var colors = lockBtn.colors;
        colors.normalColor = _isLocked
            ? new Color(0.17f, 0.16f, 0.43f) // your purple
            : Color.white;
        lockBtn.colors = colors;

        // Disable drag while locked
        var placeFurnitureScript = FindObjectOfType<ARPlaceFurniture>();
        // Lock is read by ARPlaceFurniture to prevent moving
        Debug.Log(_isLocked ? "Object locked" : "Object unlocked");
    }

    void ToggleMenu()
    {
        _menuOpen = !_menuOpen;
        menuPanel.SetActive(_menuOpen);
    }

    void ResetScene()
    {
        _isLocked = false;
        placeFurniture.ClearScene();
        selector.Deselect();
        _menuOpen = false;
        menuPanel.SetActive(false);
    }

    void DuplicateSelected()
    {
        if (!selector.HasSelection) return;

        var original = selector.SelectedObject;
        var duplicate = Instantiate(
            original,
            original.transform.position + Vector3.right * 0.5f,
            original.transform.rotation
        );

        duplicate.AddComponent<SelectionIndicator>();
        selector.Select(duplicate);
        _menuOpen = false;
        menuPanel.SetActive(false);
    }

    void OpenHelp()
    {
        Debug.Log("Help — tutorial coming soon");
        _menuOpen = false;
        menuPanel.SetActive(false);
    }

    void TakeScreenshot()
    {
        StartCoroutine(CaptureScreenshot());
    }

    System.Collections.IEnumerator CaptureScreenshot()
    {
        // Hide UI
        gameObject.SetActive(false);

        // Hide plane visualizations
        var planes = FindObjectsOfType<UnityEngine.XR.ARFoundation.ARPlane>();
        foreach (var plane in planes)
        {
            foreach (var r in plane.GetComponentsInChildren<Renderer>())
                r.enabled = false;
        }

        yield return new WaitForEndOfFrame();

        // Capture
        var texture = ScreenCapture.CaptureScreenshotAsTexture();
        var bytes = texture.EncodeToPNG();
        var path = System.IO.Path.Combine(
            Application.persistentDataPath,
            $"AR_{System.DateTime.Now:yyyyMMdd_HHmmss}.png"
        );
        System.IO.File.WriteAllBytes(path, bytes);
        Destroy(texture);

        // Restore UI
        gameObject.SetActive(true);
        foreach (var plane in planes)
        {
            foreach (var r in plane.GetComponentsInChildren<Renderer>())
                r.enabled = true;
        }

        Debug.Log($"Screenshot saved: {path}");

        // Notify Flutter to save to photo library
#if !UNITY_EDITOR
        NativeAPI.SendMessageToFlutter($"ScreenshotSaved:{path}");
#endif
    }
}
