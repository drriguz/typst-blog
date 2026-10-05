#import "../../template.typ": blog-post, sidenote, note, epigraph, newthought, widefig, notefigure

#show: blog-post.with(
  title: "Understanding the Fast Fourier Transform (快速傅里叶变换)",
  date: "2025-12-01",
  tags: ("math", "algorithms", "signal-processing"),
  summary: [An introduction to the Fast Fourier Transform (FFT) --- from the DFT definition to the Cooley--Tukey algorithm, with Python code and complexity analysis.],
)

// ─── Epigraph ──────────────────────────────────────────────────────
#epigraph[
  The FFT is the most important numerical algorithm of our lifetime.
][
  Gilbert Strang @strang1994
]

= Introduction

#newthought[The Discrete Fourier Transform] (DFT)#sidenote[See Smith @smith1997 for an excellent introduction aimed at engineers.] is one of the most important tools in computational mathematics and signal processing. It converts a sequence of $N$ complex numbers into another sequence of $N$ complex numbers, revealing the frequency content of the original signal.

然而，直接计算 DFT 需要 $O(N^2)$ 次运算，对于大规模数据来说效率太低。#sidenote[DFT 的直接算法复杂度很高——对 $N=10^6$ 的信号需要约 $10^{12}$ 次运算。] 1965年，Cooley 和 Tukey 发表了*快速傅里叶变换*（FFT）算法，将复杂度降低到 $O(N log N)$，使得频谱分析在实际工程中变得可行。#sidenote[FFT 是信号处理领域的革命性突破，被誉为"20世纪最重要的算法之一"。]

You can also use a numbered note: #note[This note has a superscript number marker in the text and margin.]

This article walks through the mathematical foundation of the DFT, derives the radix-2 Cooley--Tukey FFT algorithm, and provides a Python implementation.

= The Discrete Fourier Transform

#newthought[Formally], we write $omega_N = e^(- 2 pi i\/N)$ for the _primitive $N$-th root of unity_, so the transform becomes:
$ X_k = sum_(n = 0)^(N - 1) x_n thin omega_N^(k n) $ <eq:dft>

The inverse DFT recovers the original sequence, as shown in @eq:idft:
$ x_n = 1 / N sum_(k = 0)^(N - 1) X_k thin omega_N^(- k n) $ <eq:idft>

== Key Properties

The DFT satisfies several important properties:

- *Linearity*: $upright(D F T)(alpha x + beta y) = alpha thin upright(D F T)(x) + beta thin upright(D F T)(y)$
- *Parseval's theorem*#sidenote[Parseval's theorem tells us that the DFT preserves energy — the total power is the same whether computed in the time or frequency domain.]: $sum_n |x_n|^2 = 1 / N sum_k |X_k|^2$
- *Convolution theorem*: pointwise multiplication in the frequency domain corresponds to circular convolution in the time domain:
  $ upright(D F T)(x * y) = upright(D F T)(x) dot.op upright(D F T)(y) $
- *Shift property*: 时域中的移位对应频域中的相位旋转。若 $y_n = x_(n - m)$，则 $Y_k = omega_N^(m k) X_k$。

== A Visual Intuition

Below is a margin figure showing the magnitude spectrum of a simple signal:

#notefigure(
  {
    set text(size: 7pt)
    let data = (10, 60, 15, 5, 3, 2, 1)
    let maxv = 60
    let barh = 55pt
    grid(
      columns: data.len(),
      rows: (barh, 8pt),
      gutter: 2pt,
      ..data.map(v => {
        let h = v / maxv * barh
        align(bottom, rect(width: 100%, height: h, fill: blue.lighten(40%)))
      }),
      ..range(data.len()).map(k => align(center)[#k]),
    )
    v(2pt)
    align(center)[Frequency bin $k$]
  },
  caption: [Magnitude spectrum of a two-tone signal (50 Hz + 120 Hz). The two peaks correspond to the two frequency components.],
)<fig-spectrum>

As @fig-spectrum shows, the FFT clearly separates the two frequency components.

= The Cooley--Tukey FFT Algorithm

#newthought[The key insight] of the FFT is to exploit the symmetry and periodicity of $omega_N$. By splitting the DFT into even and odd indices:

$ X_k = underbrace(sum_(m = 0)^(N\/2 - 1) x_(2 m) thin omega_(N\/2)^(m k), E_k) + omega_N^k underbrace(sum_(m = 0)^(N\/2 - 1) x_(2 m + 1) thin omega_(N\/2)^(m k), O_k) $

This gives us the *butterfly operation*, which is the computational core of the FFT:

$ X_k & = E_k + omega_N^k thin O_k\
X_(k + N\/2) & = E_k - omega_N^k thin O_k $

@fig-butterfly visualizes this butterfly structure — each pair of inputs $(E_k, O_k)$ produces two outputs via addition and subtraction of the twiddle factor $omega_N^k$:

#notefigure(
  image("images/butterfly.webp"),
  caption: [The butterfly operation. Each pair of inputs produces two outputs via addition/subtraction of the twiddle factor.],
)<fig-butterfly>

Since $E_k$ and $O_k$ are periodic with period $N\/2$, we only need to compute them for $k = 0, 1, dots.h, N\/2 - 1$.

通过递归地应用这一分解，我们可以将 $N$ 点 DFT 的计算分解为 $log_2 N$ 层蝶形运算，每层包含 $N\/2$ 次蝶形操作。

== Complexity Analysis

#figure(
  align(center)[#table(
    columns: 4,
    align: (left,center,center,center),
    table.header([*Algorithm*], [*Multiplications*], [*Additions*], [*Total*]),
    table.hline(),
    [Naive DFT],   [$N^2$],             [$N(N-1)$],         [$O(N^2)$],
    [Radix-2 FFT], [$N/2 log_2 N$],     [$N log_2 N$],      [$O(N log N)$],
  )]
  , caption: [Comparison of DFT and FFT computational complexity.]
  , kind: table
)

For a concrete example, consider $N = 2^20 approx 10^6$:

- Naive DFT: $tilde.op 10^12$ operations
- FFT: $tilde.op 10^7$ operations
- *Speedup factor*: $tilde.op 10^5$#sidenote[That's roughly 100,000× faster — the difference between a computation finishing in seconds vs. taking all day.]

= Python Implementation

Below is a recursive radix-2 FFT implementation. Note the elegant correspondence to the mathematical derivation above.

```python
import numpy as np

def fft(x):
    """Compute the FFT of sequence x (length must be a power of 2)."""
    N = len(x)
    if N == 1:
        return x

    # Split into even and odd indices
    even = fft(x[0::2])
    odd  = fft(x[1::2])

    # Twiddle factors: ω_N^k for k = 0, ..., N/2 - 1
    T = np.exp(-2j * np.pi * np.arange(N // 2) / N)

    # Butterfly: combine E_k and O_k
    return np.concatenate([
        even + T * odd,   # X_k       = E_k + ω^k · O_k
        even - T * odd    # X_{k+N/2} = E_k - ω^k · O_k
    ])

# Verify against NumPy's FFT
if __name__ == "__main__":
    x = np.random.random(1024)
    assert np.allclose(fft(x), np.fft.fft(x))
    print("FFT implementation verified!")
```

#newthought[Performance note]: this recursive version is clear but not optimal. Production FFT libraries (like FFTW @fftw2005) use iterative approaches with carefully tuned memory access patterns, achieving near-peak hardware performance.

== What the FFT Reveals

@fig-spectrum-real shows a typical FFT output: a time-domain signal containing two sine waves (50 Hz and 120 Hz) is transformed into a frequency-domain representation with clear peaks at those exact frequencies.

#widefig[
  #figure(
    image("images/spectrum.webp"),
    caption: [FFT spectrum of a two-tone signal. The peaks at 50 Hz and 120 Hz correspond to the two frequency components in the original signal.],
  ) <fig-spectrum-real>
]

= Applications

#newthought[Signal processing]. The most common application — spectral analysis, filtering, and compression (MP3, JPEG, etc.) all rely on the FFT.

#block(inset: (left: 1.5em))[
  #set text(size: 10pt, style: "italic")
  #set par(justify: true)
  The FFT reduced the operation count for an $N$-point transform from $N^2$ to $N log N$. For $N = 10^6$, that's a factor of nearly 100,000. This single algorithm change made real-time digital signal processing possible.
  #linebreak()
  --- Press et al. @press2007
]

Other important applications include:

+ *Polynomial multiplication*: multiplying two degree-$n$ polynomials in $O(n log n)$ instead of $O(n^2)$
+ *Large integer multiplication*: the Schönhage--Strassen algorithm uses FFT to multiply $n$-digit integers in $O(n log n log log n)$
+ *Partial differential equations*: 谱方法利用 FFT 在频域中高效求解偏微分方程，在流体力学和量子力学模拟中广泛使用
+ *Convolution*: fast computation of convolutions via the convolution theorem, used in deep learning (CNNs)

== FFT in the Real World

A wide figure showing a more detailed visualization:

#widefig[
  #figure(
    {
      set text(size: 8pt)
      let bars = range(120).map(i => {
        let y = 0.5 + 0.3 * calc.sin(i * 0.25) + 0.15 * calc.sin(i * 0.06) + 0.08 * calc.sin(i * 0.9)
        let h = y * 20pt
        rect(width: 2.2pt, height: h, fill: black.lighten(20%))
      })
      stack(
        dir: ltr,
        spacing: 0.5pt,
        ..bars,
      )
      v(4pt)
      align(center)[#text(fill: gray)[Time → · A noisy composite signal with multiple frequency components]]
    },
    caption: [A time-domain signal containing multiple frequency components. The FFT decomposes this into its constituent frequencies.],
    kind: image,
  ) <fig-wide>
]

As @fig-wide demonstrates, even a visually complex signal is just a sum of simple sinusoids — the FFT tells us exactly which ones.

= Conclusion

The FFT is one of the most beautiful and practical algorithms in all of computational mathematics. It reduces the complexity of the DFT from $O(N^2)$ to $O(N log N)$, making large-scale spectral analysis feasible.

#newthought[The central idea] --- _divide and conquer via the symmetry of roots of unity_ --- is both mathematically elegant and practically powerful. Understanding the FFT provides deep insight into the interplay between the time domain and the frequency domain, a duality that lies at the heart of much of applied mathematics.

// ─── Bibliography ──────────────────────────────────────────────────
#bibliography("refs.bib", style: "ieee")
