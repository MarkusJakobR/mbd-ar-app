using UnityEngine;

public class SelectionIndicator : MonoBehaviour
{
    private GameObject _bracketsRoot;
    private ARObjectSelector _selector;
    private LineRenderer[] _corners;

    // Bracket appearance
    private const float BracketLength = 0.25f; // how long each bracket arm is
    private const float BracketOffset = 0.02f; // gap between bracket and object
    private const float LineWidth = 0.008f;
    private Color BracketColor = new Color(1f, 1f, 1f, 0.9f);

    void Start()
    {
        _selector = ARObjectSelector.Instance;

        if (_selector == null)
        {
            Debug.LogError("ARObjectSelector.Instance is null");
            return;
        }

        _selector.OnObjectSelected += OnSelected;
        _selector.OnObjectDeselected += OnDeselected;

        CreateBrackets();
        _bracketsRoot.SetActive(false);
    }

    void Update()
    {
        if (_bracketsRoot != null && _bracketsRoot.activeSelf)
            UpdateBracketPositions();
    }

    void OnDestroy()
    {
        if (_selector != null)
        {
            _selector.OnObjectSelected -= OnSelected;
            _selector.OnObjectDeselected -= OnDeselected;
        }

        if (_bracketsRoot != null)
            Destroy(_bracketsRoot);
    }

    void OnSelected(GameObject selected)
    {
        if (_bracketsRoot == null) return;
        _bracketsRoot.SetActive(selected == gameObject);
        if (selected == gameObject)
            UpdateBracketPositions();
    }

    void OnDeselected()
    {
        if (_bracketsRoot != null)
            _bracketsRoot.SetActive(false);
    }

    void CreateBrackets()
    {
        _bracketsRoot = new GameObject("SelectionBrackets");
        _bracketsRoot.transform.SetParent(null); // world space — not child

        // 4 corners, each corner has 2 lines (horizontal + vertical arm)
        _corners = new LineRenderer[12];

        for (int i = 0; i < 12; i++)
        {
            var go = new GameObject($"BracketLine_{i}");
            go.transform.SetParent(_bracketsRoot.transform);

            var lr = go.AddComponent<LineRenderer>();
            lr.positionCount = 3; // L shape: 3 points = 2 segments
            lr.startWidth = LineWidth;
            lr.endWidth = LineWidth;
            lr.useWorldSpace = true;
            lr.material = new Material(Shader.Find("Universal Render Pipeline/Lit"));
            lr.material.color = BracketColor;
            lr.material.EnableKeyword("_EMISSION");
            lr.material.SetColor("_EmissionColor", BracketColor * 2f);

            _corners[i] = lr;
        }
    }

    void UpdateBracketPositions()
    {
        Bounds bounds = GetObjectBounds();

        float ox = bounds.extents.x + BracketOffset;
        float oy = bounds.extents.y + BracketOffset;
        float oz = bounds.extents.z + BracketOffset;
        Vector3 c = bounds.center;

        // Make bracket length proportional to the smallest dimension
        // Cap at BracketLength maximum so large objects don't get huge brackets
        float bracketX = Mathf.Min(bounds.size.x * 0.25f, BracketLength);
        float bracketY = Mathf.Min(bounds.size.y * 0.25f, BracketLength);
        float bracketZ = Mathf.Min(bounds.size.z * 0.25f, BracketLength);

        // Top corners
        SetCornerBracket(_corners[0], c,
            new Vector3(-ox, oy, -oz),
            new Vector3(-ox + bracketX, oy, -oz),
            new Vector3(-ox, oy, -oz + bracketZ));

        SetCornerBracket(_corners[1], c,
            new Vector3(ox, oy, -oz),
            new Vector3(ox - bracketX, oy, -oz),
            new Vector3(ox, oy, -oz + bracketZ));

        SetCornerBracket(_corners[2], c,
            new Vector3(-ox, oy, oz),
            new Vector3(-ox + bracketX, oy, oz),
            new Vector3(-ox, oy, oz - bracketZ));

        SetCornerBracket(_corners[3], c,
            new Vector3(ox, oy, oz),
            new Vector3(ox - bracketX, oy, oz),
            new Vector3(ox, oy, oz - bracketZ));

        // Bottom corners
        SetCornerBracket(_corners[4], c,
            new Vector3(-ox, -oy, -oz),
            new Vector3(-ox + bracketX, -oy, -oz),
            new Vector3(-ox, -oy, -oz + bracketZ));

        SetCornerBracket(_corners[5], c,
            new Vector3(ox, -oy, -oz),
            new Vector3(ox - bracketX, -oy, -oz),
            new Vector3(ox, -oy, -oz + bracketZ));

        SetCornerBracket(_corners[6], c,
            new Vector3(-ox, -oy, oz),
            new Vector3(-ox + bracketX, -oy, oz),
            new Vector3(-ox, -oy, oz - bracketZ));

        SetCornerBracket(_corners[7], c,
            new Vector3(ox, -oy, oz),
            new Vector3(ox - bracketX, -oy, oz),
            new Vector3(ox, -oy, oz - bracketZ));

        // Vertical arms connecting top and bottom at each corner
        float bracketVert = Mathf.Min(bounds.size.y * 0.25f, BracketLength);

        // Each vertical arm goes from slightly below top to slightly above bottom
        SetVerticalBracket(_corners[8],
            c + new Vector3(-ox, oy, -oz),
            c + new Vector3(-ox, oy - bracketVert, -oz));

        SetVerticalBracket(_corners[9],
            c + new Vector3(ox, oy, -oz),
            c + new Vector3(ox, oy - bracketVert, -oz));

        SetVerticalBracket(_corners[10],
            c + new Vector3(-ox, oy, oz),
            c + new Vector3(-ox, oy - bracketVert, oz));

        SetVerticalBracket(_corners[11],
            c + new Vector3(ox, oy, oz),
            c + new Vector3(ox, oy - bracketVert, oz));
    }

    void SetCornerBracket(LineRenderer lr, Vector3 center,
        Vector3 corner, Vector3 arm1End, Vector3 arm2End)
    {
        // L shape: arm1End → corner → arm2End
        lr.SetPosition(0, center + arm1End);
        lr.SetPosition(1, center + corner);
        lr.SetPosition(2, center + arm2End);
    }

    void SetVerticalBracket(LineRenderer lr, Vector3 top, Vector3 bottom)
    {
        lr.positionCount = 2;
        lr.SetPosition(0, top);
        lr.SetPosition(1, bottom);
    }

    Bounds GetObjectBounds()
    {
        var renderers = GetComponentsInChildren<Renderer>();
        var filtered = System.Array.FindAll(renderers,
            r => r.gameObject != _bracketsRoot &&
                 !r.gameObject.name.StartsWith("BracketLine"));

        if (filtered.Length == 0)
            return new Bounds(transform.position, Vector3.one);

        Bounds bounds = filtered[0].bounds;
        foreach (var r in filtered)
            bounds.Encapsulate(r.bounds);

        return bounds;
    }
}
