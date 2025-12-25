// Assets/Scripts/Core/FinishLine.cs
using UnityEngine;

public class FinishLine : MonoBehaviour
{
    public event System.Action OnPlayerFinished;

    private void OnTriggerEnter2D(Collider2D other)
    {
        if (other.GetComponent<SkierController>() != null)
        {
            OnPlayerFinished?.Invoke();
        }
    }
}
