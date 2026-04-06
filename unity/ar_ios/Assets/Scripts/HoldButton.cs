using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using System;

public class HoldButton : MonoBehaviour,
    IPointerDownHandler, IPointerUpHandler,
    IPointerExitHandler, ICancelHandler
{
    public Action onDown;
    public Action onUp;

    public void OnPointerDown(PointerEventData e) => onDown?.Invoke();
    public void OnPointerUp(PointerEventData e) => onUp?.Invoke();
    public void OnPointerExit(PointerEventData e) => onUp?.Invoke();
    public void OnCancel(BaseEventData e) => onUp?.Invoke();
}
