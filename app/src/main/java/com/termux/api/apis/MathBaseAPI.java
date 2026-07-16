package com.termux.api.apis;

import android.content.Context;
import android.content.Intent;
import android.util.JsonWriter;

import com.termux.api.TermuxApiReceiver;
import com.termux.api.util.ResultReturner;
import com.termux.shared.logger.Logger;

import java.util.Arrays;

/**
 * NumericBase API — base conversion, sequences, and modular analysis.
 *
 * Subcommands (intent extra "subcommand"):
 *   convert    — convert a number between bases
 *   sequence   — generate Fibonacci/Tribonacci/Primonacci terms
 *   pisano     — Pisano period for Fibonacci mod m (Poincaré recurrence)
 *   special    — analyze the RAFAELIA special numbers in multiple bases
 *   zerocurve  — describe how Z/aZ and Z/bZ coexist
 *   efficiency — radix economy comparison across bases
 *   primes     — prime fluid graph (primes connected by modular difference)
 */
public class MathBaseAPI {

    private static final String LOG_TAG = "MathBaseAPI";

    /* RAFAELIA special numbers — user's list */
    private static final long[] SPECIAL_NUMS = {
        5, 144, 288, 1008, 4096, 512, 128, 288000, 144000,
        936, 999, 777, 333, 111, 60, 70, 7, 13, 14, 8, 3, 2, 1, 0, 20,
        35, 50, 56
    };

    private static final int[] DEFAULT_BASES = {2, 3, 7, 8, 10, 12, 16, 20};

    private static final int[] MOD_VALUES = {7, 10, 14, 70};

    public static void onReceive(TermuxApiReceiver apiReceiver,
                                 final Context context,
                                 final Intent intent) {
        Logger.logDebug(LOG_TAG, "onReceive");
        final String sub = intent.getStringExtra("subcommand");

        ResultReturner.returnData(apiReceiver, intent, new ResultReturner.ResultJsonWriter() {
            @Override
            public void writeJson(JsonWriter out) throws Exception {
                if (sub == null) {
                    writeHelp(out);
                    return;
                }
                switch (sub) {
                    case "convert":    writeConvert(out, intent);    break;
                    case "sequence":   writeSequence(out, intent);   break;
                    case "pisano":     writePisano(out, intent);     break;
                    case "special":    writeSpecial(out, intent);    break;
                    case "zerocurve":  writeZeroCurve(out, intent);  break;
                    case "efficiency": writeEfficiency(out, intent); break;
                    case "primes":     writePrimes(out, intent);     break;
                    default:
                        out.beginObject();
                        out.name("error").value("unknown subcommand: " + sub);
                        out.endObject();
                }
            }
        });
    }

    /* -----------------------------------------------------------------------
     * convert: number → string in target base
     * Extras: n (long), from_base (int, default 10), to_base (int, default 7)
     * ----------------------------------------------------------------------- */
    private static void writeConvert(JsonWriter out, Intent intent) throws Exception {
        long n       = intent.getLongExtra("n", 0);
        int fromBase = intent.getIntExtra("from_base", 10);
        int toBase   = intent.getIntExtra("to_base", 7);

        out.beginObject();
        out.name("input").value(n);
        out.name("from_base").value(fromBase);
        out.name("from_repr").value(toBase(n, fromBase));
        out.name("to_base").value(toBase);
        out.name("to_repr").value(toBase(n, toBase));
        out.endObject();
    }

    /* -----------------------------------------------------------------------
     * sequence: list of terms, optionally mod m
     * Extras: type (fibonacci|tribonacci|primonacci), length (int), mod (int)
     * ----------------------------------------------------------------------- */
    private static void writeSequence(JsonWriter out, Intent intent) throws Exception {
        String type = intent.getStringExtra("type");
        if (type == null) type = "fibonacci";
        int length = Math.min(intent.getIntExtra("length", 20), 200);
        int mod    = intent.getIntExtra("mod", 0);

        out.beginObject();
        out.name("type").value(type);
        out.name("length").value(length);
        if (mod > 0) out.name("mod").value(mod);

        out.name("terms");
        out.beginArray();
        for (int i = 0; i < length; i++) {
            long v = seqTerm(type, i);
            out.value(mod > 0 ? ((v % mod + mod) % mod) : v);
        }
        out.endArray();

        /* The four seed subsequences from the RAFAELIA spec */
        out.name("seeds");
        out.beginObject();
        writeIntArray(out, "triple_zero_seed",  new int[]{0, 0, 0, 1, 1, 2, 3, 5, 8, 13});
        writeIntArray(out, "fibonacci_01",       new int[]{0, 1, 1, 2, 3, 5, 8, 13});
        writeIntArray(out, "linear_0123",        new int[]{0, 1, 2, 3});
        writeIntArray(out, "from_1",             new int[]{1, 2, 3, 5, 8, 13});
        out.endObject();

        out.endObject();
    }

    /* -----------------------------------------------------------------------
     * pisano: Fibonacci mod m period (Poincaré recurrence applied to sequences)
     * Extras: mod (int, default 10)
     * ----------------------------------------------------------------------- */
    private static void writePisano(JsonWriter out, Intent intent) throws Exception {
        int mod    = intent.getIntExtra("mod", 10);
        int period = pisanoPeriod(mod);

        out.beginObject();
        out.name("mod").value(mod);
        out.name("period").value(period);
        out.name("note").value(
            "Fibonacci mod " + mod + " repeats every " + period +
            " terms. The number 60 in the RAFAELIA list = P(10).");

        out.name("first_period");
        out.beginArray();
        long a = 0, b = 1;
        out.value(a);
        for (int i = 0; i < period - 1; i++) {
            out.value(b);
            long c = (a + b) % mod;
            a = b; b = c;
        }
        out.endArray();
        out.endObject();
    }

    /* -----------------------------------------------------------------------
     * special: analyze RAFAELIA special numbers in multiple bases
     * Extras: bases (comma-separated ints)
     * ----------------------------------------------------------------------- */
    private static void writeSpecial(JsonWriter out, Intent intent) throws Exception {
        String basesExtra = intent.getStringExtra("bases");
        int[] bases = parseBasesExtra(basesExtra, DEFAULT_BASES);

        out.beginArray();
        for (long n : SPECIAL_NUMS) {
            out.beginObject();
            out.name("n").value(n);

            out.name("bases");
            out.beginObject();
            for (int base : bases) {
                out.name(String.valueOf(base)).value(toBase(n, base));
            }
            out.endObject();

            out.name("mod");
            out.beginObject();
            for (int m : MOD_VALUES) {
                out.name(String.valueOf(m)).value(((n % m) + m) % m);
            }
            out.endObject();

            int fibIdx = fibonacciIndex(n);
            if (fibIdx >= 0) out.name("fibonacci_index").value(fibIdx);
            out.endObject();
        }
        out.endArray();
    }

    /* -----------------------------------------------------------------------
     * zerocurve: Z/aZ and Z/bZ coexistence — "curving zero"
     * Extras: base_a (int, default 7), base_b (int, default 10)
     * ----------------------------------------------------------------------- */
    private static void writeZeroCurve(JsonWriter out, Intent intent) throws Exception {
        int baseA = intent.getIntExtra("base_a", 7);
        int baseB = intent.getIntExtra("base_b", 10);
        int g     = gcd(baseA, baseB);
        int lcm   = (baseA / g) * baseB;

        out.beginObject();
        out.name("base_a").value(baseA);
        out.name("base_b").value(baseB);
        out.name("lcm").value(lcm);
        out.name("pisano_a").value(pisanoPeriod(baseA));
        out.name("pisano_b").value(pisanoPeriod(baseB));
        out.name("note").value(
            "In Z/" + baseA + "Z, adding " + baseA + " curves back to 0. " +
            "In Z/" + baseB + "Z, adding " + baseB + " curves back to 0. " +
            "Both coincide at " + lcm + " = LCM(" + baseA + "," + baseB + ").");

        out.name("ring_a");
        out.beginArray();
        for (int i = 0; i < baseA; i++) out.value(i);
        out.endArray();

        out.name("ring_b");
        out.beginArray();
        for (int i = 0; i < baseB; i++) out.value(i);
        out.endArray();

        out.name("coincidences");
        out.beginArray();
        for (int i = 0; i <= lcm; i++) {
            if (i % baseA == 0 && i % baseB == 0) out.value(i);
        }
        out.endArray();

        /* Abscissas: 35=5×7, 50=5×10, 56=7×8 */
        out.name("abscissas");
        out.beginObject();
        for (int pt : new int[]{35, 50, 56}) {
            out.name(String.valueOf(pt));
            out.beginObject();
            out.name("mod_a").value(pt % baseA);
            out.name("mod_b").value(pt % baseB);
            out.name("in_a").value(toBase(pt, baseA));
            out.name("in_b").value(toBase(pt, baseB));
            out.endObject();
        }
        out.endObject();
        out.endObject();
    }

    /* -----------------------------------------------------------------------
     * efficiency: radix economy comparison
     * Extras: n_max (long, default 1000000)
     * ----------------------------------------------------------------------- */
    private static void writeEfficiency(JsonWriter out, Intent intent) throws Exception {
        long nMax = intent.getLongExtra("n_max", 1_000_000L);
        int[] bases = {2, 3, 7, 8, 10, 12, 16, 20, 60};

        out.beginObject();
        out.name("n_max").value(nMax);
        out.name("note").value(
            "Radix economy = ceil(log_base(n)) * base. " +
            "Lower = more efficient. Optimum at e≈2.718; base 3 nearest integer.");

        out.name("economy");
        out.beginObject();
        double bestEconomy = Double.MAX_VALUE;
        int bestBase = 3;
        for (int b : bases) {
            double digits  = Math.ceil(Math.log(nMax) / Math.log(b));
            double economy = digits * b;
            out.name(String.valueOf(b)).value(Math.round(economy * 100.0) / 100.0);
            if (economy < bestEconomy) { bestEconomy = economy; bestBase = b; }
        }
        out.endObject();
        out.name("most_efficient").value(bestBase);
        out.endObject();
    }

    /* -----------------------------------------------------------------------
     * primes: prime fluid graph
     * Extras: range (int, default 100), mod (int, default 7)
     * ----------------------------------------------------------------------- */
    private static void writePrimes(JsonWriter out, Intent intent) throws Exception {
        int range = Math.min(intent.getIntExtra("range", 100), 1000);
        int mod   = intent.getIntExtra("mod", 7);
        int[] primes = primesUpTo(range);

        out.beginObject();
        out.name("range").value(range);
        out.name("mod").value(mod);
        out.name("prime_count").value(primes.length);
        out.name("note").value(
            "Edge when (p2-p1) % " + mod + " == 0. " +
            "Weight = 1/diff (fluid coupling; closer = stronger).");

        out.name("nodes");
        out.beginArray();
        for (int p : primes) out.value(p);
        out.endArray();

        out.name("edges");
        out.beginArray();
        for (int i = 0; i < primes.length; i++) {
            for (int j = i + 1; j < primes.length; j++) {
                int diff = primes[j] - primes[i];
                if (diff % mod == 0) {
                    out.beginObject();
                    out.name("from").value(primes[i]);
                    out.name("to").value(primes[j]);
                    out.name("diff").value(diff);
                    out.name("weight").value(Math.round((1.0 / diff) * 1_000_000) / 1_000_000.0);
                    out.endObject();
                }
            }
        }
        out.endArray();
        out.endObject();
    }

    /* -----------------------------------------------------------------------
     * Help
     * ----------------------------------------------------------------------- */
    private static void writeHelp(JsonWriter out) throws Exception {
        out.beginObject();
        out.name("api").value("NumericBase");
        out.name("subcommands");
        out.beginArray();
        for (String s : new String[]{
            "convert    — n, from_base, to_base",
            "sequence   — type (fibonacci|tribonacci|primonacci), length, mod",
            "pisano     — mod",
            "special    — bases (comma-separated, e.g. '2,7,10')",
            "zerocurve  — base_a, base_b",
            "efficiency — n_max",
            "primes     — range, mod"
        }) out.value(s);
        out.endArray();
        out.endObject();
    }

    /* =========================================================================
     * Shared math helpers
     * ========================================================================= */

    static String toBase(long n, int base) {
        if (base < 2 || base > 36) return "?";
        if (n == 0) return "0";
        boolean neg = n < 0;
        if (neg) n = -n;
        StringBuilder sb = new StringBuilder();
        while (n > 0) {
            int r = (int)(n % base);
            sb.append(r < 10 ? (char)('0' + r) : (char)('a' + r - 10));
            n /= base;
        }
        if (neg) sb.append('-');
        return sb.reverse().toString();
    }

    static long fibonacci(int n) {
        if (n <= 0) return 0;
        if (n == 1) return 1;
        long a = 0, b = 1;
        for (int i = 2; i <= n; i++) { long c = a + b; a = b; b = c; }
        return b;
    }

    static long tribonacci(int n) {
        if (n <= 0) return 0;
        if (n == 1) return 0;
        if (n == 2) return 1;
        long a = 0, b = 0, c = 1;
        for (int i = 3; i <= n; i++) { long d = a + b + c; a = b; b = c; c = d; }
        return c;
    }

    static boolean isPrime(long n) {
        if (n < 2) return false;
        if (n == 2) return true;
        if (n % 2 == 0) return false;
        for (long i = 3; i * i <= n; i += 2) if (n % i == 0) return false;
        return true;
    }

    static long nextPrime(long n) {
        if (n < 2) return 2;
        long p = (n % 2 == 0) ? n + 1 : n + 2;
        while (!isPrime(p)) p += 2;
        return p;
    }

    static long primonacci(int n) {
        if (n <= 0) return 2;
        if (n == 1) return 3;
        long a = 2, b = 3;
        for (int i = 2; i <= n; i++) {
            long sum = a + b;
            long p = isPrime(sum) ? sum : nextPrime(sum - 1);
            a = b; b = p;
        }
        return b;
    }

    static long seqTerm(String type, int n) {
        switch (type) {
            case "tribonacci": return tribonacci(n);
            case "primonacci": return primonacci(n);
            default:           return fibonacci(n);
        }
    }

    static int pisanoPeriod(int m) {
        if (m <= 1) return 1;
        long a = 0, b = 1;
        for (int i = 0; i < 6 * m; i++) {
            long c = (a + b) % m;
            a = b; b = c;
            if (a == 0 && b == 1) return i + 1;
        }
        return 0;
    }

    static int gcd(int a, int b) {
        while (b != 0) { int t = b; b = a % b; a = t; }
        return a;
    }

    static int fibonacciIndex(long n) {
        if (n < 0) return -1;
        for (int k = 0; k <= 86; k++) {
            long f = fibonacci(k);
            if (f == n) return k;
            if (f > n) break;
        }
        return -1;
    }

    static int[] primesUpTo(int max) {
        if (max < 2) return new int[0];
        boolean[] sieve = new boolean[max + 1];
        Arrays.fill(sieve, true);
        sieve[0] = sieve[1] = false;
        for (int i = 2; (long)i * i <= max; i++) {
            if (sieve[i]) for (int j = i * i; j <= max; j += i) sieve[j] = false;
        }
        int count = 0;
        for (int i = 2; i <= max; i++) if (sieve[i]) count++;
        int[] primes = new int[count];
        int idx = 0;
        for (int i = 2; i <= max; i++) if (sieve[i]) primes[idx++] = i;
        return primes;
    }

    static int[] parseBasesExtra(String s, int[] fallback) {
        if (s == null || s.isEmpty()) return fallback;
        String[] parts = s.split(",");
        int[] result = new int[parts.length];
        try {
            for (int i = 0; i < parts.length; i++) result[i] = Integer.parseInt(parts[i].trim());
            return result;
        } catch (NumberFormatException e) {
            return fallback;
        }
    }

    private static void writeIntArray(JsonWriter out, String name, int[] values) throws Exception {
        out.name(name);
        out.beginArray();
        for (int v : values) out.value(v);
        out.endArray();
    }
}
