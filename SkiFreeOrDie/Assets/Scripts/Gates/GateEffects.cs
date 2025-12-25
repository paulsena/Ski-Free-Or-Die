// Assets/Scripts/Gates/GateEffects.cs
using UnityEngine;

public class GateEffects : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private GateTrigger gateTrigger;
    [SerializeField] private ParticleSystem passParticles;
    [SerializeField] private ParticleSystem missParticles;

    [Header("Pass Effect Settings")]
    [SerializeField] private Color passColor = GameColors.MintGreen;
    [SerializeField] private int passParticleCount = 20;
    [SerializeField] private float passParticleSpeed = 3f;

    [Header("Miss Effect Settings")]
    [SerializeField] private Color missColor = GameColors.HotPink;
    [SerializeField] private int missParticleCount = 10;
    [SerializeField] private float missParticleSpeed = 2f;

    private void Start()
    {
        if (gateTrigger == null)
        {
            gateTrigger = GetComponent<GateTrigger>();
        }

        if (gateTrigger != null)
        {
            gateTrigger.OnGatePassed += PlayPassEffect;
            gateTrigger.OnGateMissed += PlayMissEffect;
        }

        // Create particle systems if not assigned
        if (passParticles == null)
        {
            passParticles = CreateParticleSystem("PassParticles", passColor);
        }
        if (missParticles == null)
        {
            missParticles = CreateParticleSystem("MissParticles", missColor);
        }
    }

    private ParticleSystem CreateParticleSystem(string name, Color color)
    {
        var go = new GameObject(name);
        go.transform.SetParent(transform);
        go.transform.localPosition = Vector3.zero;

        var ps = go.AddComponent<ParticleSystem>();
        var main = ps.main;
        main.startColor = color;
        main.startLifetime = 0.5f;
        main.startSpeed = 3f;
        main.startSize = 0.2f;
        main.simulationSpace = ParticleSystemSimulationSpace.World;
        main.playOnAwake = false;

        var emission = ps.emission;
        emission.enabled = false;

        var shape = ps.shape;
        shape.shapeType = ParticleSystemShapeType.Circle;
        shape.radius = 0.5f;

        return ps;
    }

    public void PlayPassEffect()
    {
        if (passParticles != null)
        {
            var emission = passParticles.emission;
            emission.SetBursts(new ParticleSystem.Burst[]
            {
                new ParticleSystem.Burst(0f, passParticleCount)
            });

            var main = passParticles.main;
            main.startSpeed = passParticleSpeed;

            passParticles.Play();
        }

        // Play sound
        if (AudioManager.Instance != null)
        {
            AudioManager.Instance.PlaySFX(GameAudioType.GatePass);
        }
    }

    public void PlayMissEffect()
    {
        if (missParticles != null)
        {
            var emission = missParticles.emission;
            emission.SetBursts(new ParticleSystem.Burst[]
            {
                new ParticleSystem.Burst(0f, missParticleCount)
            });

            var main = missParticles.main;
            main.startSpeed = missParticleSpeed;

            missParticles.Play();
        }

        // Play sound
        if (AudioManager.Instance != null)
        {
            AudioManager.Instance.PlaySFX(GameAudioType.GateMiss);
        }
    }

    private void OnDestroy()
    {
        if (gateTrigger != null)
        {
            gateTrigger.OnGatePassed -= PlayPassEffect;
            gateTrigger.OnGateMissed -= PlayMissEffect;
        }
    }
}
