// Assets/Tests/EditMode/TurnCalculatorTests.cs
using NUnit.Framework;

public class TurnCalculatorTests
{
    [Test]
    public void AtLowSpeed_TurningIsDirect()
    {
        var calc = new TurnCalculator(
            lowSpeedThreshold: 40f,
            highSpeedThreshold: 60f,
            maxSpeed: 100f
        );

        // At 20% speed (low), should get near-instant response
        float response = calc.GetTurnResponse(currentSpeed: 20f);
        Assert.GreaterOrEqual(response, 0.9f); // Near 1.0 = direct
    }

    [Test]
    public void AtHighSpeed_TurningIsMomentumBased()
    {
        var calc = new TurnCalculator(
            lowSpeedThreshold: 40f,
            highSpeedThreshold: 60f,
            maxSpeed: 100f
        );

        // At 80% speed (high), should get sluggish response
        float response = calc.GetTurnResponse(currentSpeed: 80f);
        Assert.LessOrEqual(response, 0.5f); // Low = momentum-based
    }

    [Test]
    public void AtMidSpeed_TurningIsBlended()
    {
        var calc = new TurnCalculator(
            lowSpeedThreshold: 40f,
            highSpeedThreshold: 60f,
            maxSpeed: 100f
        );

        // At 50% speed (transition zone), should be blended
        float response = calc.GetTurnResponse(currentSpeed: 50f);
        Assert.Greater(response, 0.5f);
        Assert.Less(response, 0.9f);
    }

    [Test]
    public void WhenTucking_TurnRadiusIsWider()
    {
        var calc = new TurnCalculator(
            lowSpeedThreshold: 40f,
            highSpeedThreshold: 60f,
            maxSpeed: 100f,
            tuckTurnPenalty: 0.6f
        );

        float normalRadius = calc.GetTurnRadius(isTucking: false);
        float tuckRadius = calc.GetTurnRadius(isTucking: true);

        Assert.Greater(tuckRadius, normalRadius);
    }
}
