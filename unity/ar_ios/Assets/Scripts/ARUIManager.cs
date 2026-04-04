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

    // Single source of truth — reads from the selected object's FurnitureLock
    public bool IsLocked
    {
        get
        {
            if (!selector.HasSelection) return false;
            var lockComp = selector.SelectedObject.GetComponent<FurnitureLock>();
            return lockComp != null && lockComp.IsLocked;
        }
    }

    void Start()
    {
        if (rotateClockwiseBtn != null)
            AddPointerHold(rotateClockwiseBtn,
                () => _rotatingClockwise = true,
                () => _rotatingClockwise = false);

        if (rotateCounterBtn != null)
            AddPointerHold(rotateCounterBtn,
                () => _rotatingCounter = true,
                () => _rotatingCounter = false);

        if (deleteBtn != null)
            deleteBtn.onClick.AddListener(DeleteSelected);

        if (lockBtn != null)
            lockBtn.onClick.AddListener(ToggleLock);

        if (screenshotBtn != null)
            screenshotBtn.onClick.AddListener(TakeScreenshot);

        if (menuToggleBtn != null)
            menuToggleBtn.onClick.AddListener(ToggleMenu);

        if (menuPanel != null)
            menuPanel.SetActive(false);

        if (resetBtn != null)
            resetBtn.onClick.AddListener(ResetScene);

        if (duplicateBtn != null)
            duplicateBtn.onClick.AddListener(DuplicateSelected);

        if (helpBtn != null)
            helpBtn.onClick.AddListener(OpenHelp);

        if (selector != null)
        {
            selector.OnObjectSelected += _ => UpdateButtonVisibility(true);
            selector.OnObjectDeselected += () => UpdateButtonVisibility(false);
        }

        UpdateButtonVisibility(false);
    }

    void Update()
    {
        if (!selector.HasSelection) return;
        if (IsLocked) return; // uses the property — reads from FurnitureLock

        if (_rotatingClockwise)
            selector.SelectedObject.transform.Rotate(
                Vector3.up, rotationSpeed * Time.deltaTime, Space.World);

        if (_rotatingCounter)
            selector.SelectedObject.transform.Rotate(
                Vector3.up, -rotationSpeed * Time.deltaTime, Space.World);
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

        var exit = new EventTrigger.Entry { eventID = EventTriggerType.PointerExit };
        exit.callback.AddListener(_ => onUp());
        trigger.triggers.Add(exit);
    }

    void UpdateButtonVisibility(bool hasSelection)
    {
        rotateClockwiseBtn?.gameObject.SetActive(hasSelection);
        rotateCounterBtn?.gameObject.SetActive(hasSelection);
        deleteBtn?.gameObject.SetActive(hasSelection);
        lockBtn?.gameObject.SetActive(hasSelection);

        if (hasSelection)
        {
            var lockComp = selector.SelectedObject?.GetComponent<FurnitureLock>();
            UpdateLockButtonVisual(lockComp != null && lockComp.IsLocked);
        }
    }

    void ToggleLock()
    {
        if (!selector.HasSelection) return;

        var lockComp = selector.SelectedObject.GetComponent<FurnitureLock>();
        if (lockComp == null) return;

        lockComp.Toggle();
        UpdateLockButtonVisual(lockComp.IsLocked);
    }

    void UpdateLockButtonVisual(bool isLocked)
    {
        if (lockBtn == null) return;

        var colors = lockBtn.colors;
        colors.normalColor = isLocked
            ? new Color(0.17f, 0.16f, 0.43f)
            : Color.white;
        lockBtn.colors = colors;

    }

    void DeleteSelected()
    {
        // No lock state to reset — lock lives on the object, destroyed with it
        selector.DeleteSelected();
    }

    void ToggleMenu()
    {
        _menuOpen = !_menuOpen;
        menuPanel?.SetActive(_menuOpen);
    }

    void ResetScene()
    {
        placeFurniture.ResetScene();
        selector.Deselect();
        _menuOpen = false;
        menuPanel?.SetActive(false);
    }

    void DuplicateSelected()
    {
        placeFurniture.DuplicateSelected();
        _menuOpen = false;
        menuPanel?.SetActive(false);
    }

    void OpenHelp()
    {
        Debug.Log("Help — tutorial coming soon");
        _menuOpen = false;
        menuPanel?.SetActive(false);
    }

    public void ShowTapToPlaceHint(bool show)
    {
        if (tapToPlaceHint != null)
            tapToPlaceHint.SetActive(show);
        else
            Debug.LogWarning("tapToPlaceHint is not assigned in ARUIManager");
    }

    void TakeScreenshot()
    {
        StartCoroutine(CaptureScreenshot());
    }

    System.Collections.IEnumerator CaptureScreenshot()
    {
        gameObject.SetActive(false);

        var planes = FindObjectsOfType<UnityEngine.XR.ARFoundation.ARPlane>();
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

        gameObject.SetActive(true);
        foreach (var plane in planes)
            foreach (var r in plane.GetComponentsInChildren<Renderer>())
                r.enabled = true;

        Debug.Log($"Screenshot saved: {path}");

        // #if !UNITY_EDITOR
        //         NativeAPI.SendMessageToFlutter($"ScreenshotSaved:{path}");
        // #endif
    }
}
