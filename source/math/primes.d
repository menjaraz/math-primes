/++
    This module contains utilities relating to prime numbers.

    Right now this module mainly has an infinite range of primes backed by a
    Sieve of Eratosthenes.
    
    HELP_WELCOMED:
    The potential number of "prime number utilities" is much, much larger than
    the relatively small set here, that I've just wanted for some minor
    benchmarks, but please feel free to submit additional utilities so the
    namespace can become more useful.
+/
module math.primes;

import std.traits : isIntegral;

/++
    Calculates the upper bound of the integer range containing the nth prime.

    Useful for knowing how large of a sieve to prepare if you want to collect a
    certain number of prime numbers, for example.
+/
size_t nthPrimeUpperBound(size_t n) @nogc @safe pure nothrow {
    import std.math : log;

    if (n > 6)
        return cast(size_t)(n * log(cast(double)n) + n * log(log(cast(double)n)));
    else
        return 11;
}

///
unittest {
    assert(nthPrimeUpperBound(4) == 11);
    assert(nthPrimeUpperBound(7) == 18);
    assert(nthPrimeUpperBound(50) == 263);
}

/++
    The Sieve of Eratosthenes

    Backed by a bool[]; the template argument is only used for integral type
    yielded by the range.
+/
struct Sieve(T = size_t) if (isIntegral!T) {
    private bool[] sieve; /// false = prime. ignore indexes < 2

    /// Constructs a sieve with the given size.
    this(size_t length) @safe nothrow {
        sieve.length = length;

        // code duplication with sift, but avoids unnecessary division
        foreach (i; 2 .. length / 2) {
            if (!sieve[i]) {
                size_t j = i + i;
                while (j < length) {
                    sieve[j] = true;
                    j += i;
                }
            }
        }
    }

    /++
        Loop over the entire sieve, but only start eliminating composite
        numbers from after the 'from' index on. Useful after resizing the
        sieve.
    +/
    private void sift(size_t from) @nogc @safe nothrow {
        immutable size_t length = sieve.length;
        foreach (i; 2 .. length / 2) {
            if (!sieve[i]) {
                size_t j = i >= from ? i + i : from - from % i + i;
                while (j < length) {
                    sieve[j] = true;
                    j += i;
                }
            }
        }
    }

    private size_t i = 2;

    bool empty = false;

    T front() @nogc @safe nothrow {
        return cast(T) i;
    }

    void popFront() @safe nothrow {
        while (1) {
            while (++i < sieve.length) {
                if (!sieve[i])
                    return;
            }
            --i;
            // ran out of sieve!
            sieve.length += 5000;
            sift(i - 1);
        }
    }

    /// Return a finite slice of the sieve.
    auto fixed() @nogc @safe nothrow {
        struct FixedSieve {
            private bool[] sieve;
            private size_t i = 2;

            bool empty() {
                return i >= sieve.length;
            }

            T front() {
                return cast(T) i;
            }

            void popFront() {
                while (++i < sieve.length) {
                    if (!sieve[i])
                        break;
                }
            }
        }

        return FixedSieve(sieve);
    }
}

///
unittest {
    import std.algorithm : sum, until;
    import std.range : take, array;

    assert(Sieve!int(50).until!(n => n >= 50).sum == 328);
    assert(Sieve!int(nthPrimeUpperBound(50)).take(50).sum == 5117);
    assert(Sieve!int(30).fixed.array == [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]);
    assert(Sieve!int(0).fixed.array == []);

    // this causes compilation to take about 9s and 2 GB of memory.
    // static assert(Sieve!ulong(2_000_000).fixed.sum = 142913828922);

    auto ps = Sieve!int();
    assert(ps.front == 2);
    ps.popFront();
    assert(ps.front == 3);
}
