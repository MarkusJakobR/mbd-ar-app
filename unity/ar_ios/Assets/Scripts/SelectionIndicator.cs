using UnityEngine;

public class SelectionIndicator : MonoBehaviour
{
    private GameObject _indicator;
    private ARObjectSelector _selector;

    void Start()
    {
        _selector = ARObjectSelector.Instance;
        _selector.OnObjectSelected += OnSelected;
        _selector.OnObjectDeselected += OnDeselected;

        CreateIndicator();
        _indicator.SetActive(false);
    }

    void OnDestroy()
    {
        if (_selector != null)
        {
            _selector.OnObjectSelected -= OnSelected;
            _selector.OnObjectDeselected -= OnDeselected;
        }
    }

    void CreateIndicator()
    {
        // Create a simple circle using a cylinder scaled flat
        _indicator = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        _indicator.transform.SetParent(transform);
        _indicator.transform.localPosition = Vector3.zero;
        _indicator.transform.localScale = new Vector3(0.5f, 0.01f, 0.5f);

        // Destroy the collider so it doesn't interfere with selection
        Destroy(_indicator.GetComponent<Collider>());

        // White emissive material
        var mat = new Material(Shader.Find("Universal Render Pipeline/Lit"));
        mat.color = new Color(1f, 1f, 1f, 0.6f);
        mat.EnableKeyword("_EMISSION");
        mat.SetColor("_EmissionColor", Color.white * 0.5f);
        _indicator.GetComponent<Renderer>().material = mat;
    }

    void OnSelected(GameObject selected)
    {
        _indicator.SetActive(selected == gameObject);
    }

    void OnDeselected()
    {
        _indicator.SetActive(false);
    }
}
