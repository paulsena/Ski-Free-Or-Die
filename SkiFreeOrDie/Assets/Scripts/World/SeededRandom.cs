// Assets/Scripts/World/SeededRandom.cs
using System;

public class SeededRandom
{
    private Random random;

    public SeededRandom(int seed)
    {
        random = new Random(seed);
    }

    public float NextFloat()
    {
        return (float)random.NextDouble();
    }

    public int NextInt(int maxExclusive)
    {
        return random.Next(maxExclusive);
    }

    public int NextInt(int minInclusive, int maxExclusive)
    {
        return random.Next(minInclusive, maxExclusive);
    }

    public float Range(float min, float max)
    {
        return min + NextFloat() * (max - min);
    }

    public T Choose<T>(T[] options)
    {
        return options[NextInt(options.Length)];
    }
}
