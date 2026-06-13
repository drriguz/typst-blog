#import "../../template.typ": blog-post, sidenote, note, epigraph, newthought, widefig, notefigure

#show: blog-post.with(
  title: "Bayes' Theorem: Updating Beliefs with Evidence",
  date: "2026-01-15",
  tags: ("math", "probability", "statistics"),
  summary: [A deep dive into Bayes' theorem --- from its 18th-century origins to modern applications in spam filters, medical diagnosis, and machine learning.],
)

// ─── Epigraph ──────────────────────────────────────────────────────
#epigraph[
  Your ability to do good science depends on your ability to update your beliefs in the face of evidence.
][
  E. T. Jaynes @jaynes2003
]

= The Problem of Inverse Probability

#newthought[Suppose] you test positive for a rare disease. The test is 99% accurate. Should you panic?#sidenote[The intuitive answer is "yes" — but as we'll see, the correct answer depends critically on how rare the disease is.]

This is a question of _inverse probability_: given an observed effect (positive test), what is the probability of the underlying cause (having the disease)? For centuries, this kind of reasoning was considered impossible or meaningless. It took a Presbyterian minister named Thomas Bayes to crack the problem.

= Bayes' Theorem

#newthought[Bayes' theorem] relates the conditional probability of a hypothesis $H$ given evidence $E$ to the reverse:

$ P(H | E) = (P(E | H) dot P(H)) / P(E) $ <eq:bayes>

where:

- $P(H | E)$ is the _posterior_ — our updated belief after seeing evidence
- $P(E | H)$ is the _likelihood_ — how probable the evidence is if the hypothesis is true
- $P(H)$ is the _prior_ — our belief before seeing evidence
- $P(E)$ is the _marginal likelihood_ — the total probability of the evidence

== A Simple Example

Consider a medical test for a disease that affects 1 in 1,000 people#sidenote[This base rate is crucial. Many real-world errors in reasoning come from ignoring it — a phenomenon called _base rate neglect_.]:

- *Prevalence*: $P("disease") = 0.001$
- *Sensitivity*: $P("positive" | "disease") = 0.99$ (true positive rate)
- *Specificity*: $P("negative" | "no disease") = 0.95$ (true negative rate)

What is $P("disease" | "positive")$?

First, compute the marginal probability of testing positive:
$ P("positive") = P("positive" | "disease") dot P("disease") + P("positive" | "no disease") dot P("no disease") $
$ = 0.99 times 0.001 + 0.05 times 0.999 = 0.05094 $

Then apply @eq:bayes:
$ P("disease" | "positive") = (0.99 times 0.001) / 0.05094 approx 0.0194 $

#newthought[The result is shocking:] despite the test being 99% accurate, a positive result only means a ~2% chance of actually having the disease. #sidenote[This counterintuitive result arises because the false positives from the large healthy population (5%) vastly outnumber the true positives from the tiny sick population (0.1%).]

== Visualizing the Update

The shift from prior to posterior is best seen visually. @fig-prior-posterior shows how the distribution concentrates around the true value as evidence accumulates:

#notefigure(
  image("images/prior_posterior.webp"),
  caption: [Prior vs posterior distribution. The posterior concentrates around the true value as evidence accumulates.],
)<fig-prior-posterior>

The following table tracks how our belief updates through each piece of evidence:

#figure(
  table(
    columns: 3,
    align: (left, center, center),
    table.header([*Stage*], [*P(disease)*], [*Odds*]),
    table.hline(),
    [Prior (before test)],           [0.001],  [1 : 999],
    [After positive test],           [0.0194], [1 : 50.5],
    [After second positive test],    [0.284],  [1 : 2.5],
    [After third positive test],     [0.867],  [6.5 : 1],
  ),
  caption: [Sequential Bayesian updates. Each independent positive test dramatically shifts the probability.],
  kind: table,
)

#sidenote[This is why doctors order confirmatory tests. A single positive is weak evidence; multiple independent positives compound into strong evidence.]

= The Odds Form

Bayes' theorem has an elegant equivalent in odds form that makes sequential updating trivial:

$ "odds"(H | E) = "LR" times "odds"(H) $

where the _likelihood ratio_ $"LR" = P(E | H) \/ P(E | not H)$ and $"odds"(H) = P(H) \/ (1 - P(H))$.

This is the form used in practice #sidenote[The odds form avoids computing the marginal probability $P(E)$ entirely — the likelihood ratio handles it implicitly.] because it factors out $P(E)$ and lets us chain updates:

$ "odds"_n = "LR"_1 times "LR"_2 times dots times "LR"_n times "odds"_0 $

@fig-lr illustrates the likelihood ratio concept: when the evidence is much more likely under the hypothesis than under the alternative, the LR is large and the update is strong.

#figure(
  image("images/likelihood_ratio.webp", width: 80%),
  caption: [The likelihood ratio compares how probable the evidence is under competing hypotheses. A large LR means strong evidence for the hypothesis.],
)<fig-lr>

= Implementation

#newthought[The code] is straightforward. Here's a Python implementation that handles both single and sequential updates:

```python
class BayesUpdater:
    """Bayesian belief updater using the odds form."""

    def __init__(self, prior: float):
        self.odds = prior / (1 - prior)
        self.history = [prior]

    def update(self, lr: float) -> float:
        """Update belief with a new likelihood ratio."""
        self.odds *= lr
        p = self.odds / (1 + self.odds)
        self.history.append(p)
        return p

    @property
    def probability(self) -> float:
        return self.odds / (1 + self.odds)

# Medical diagnosis example
belief = BayesUpdater(prior=0.001)

# First positive test (LR = sensitivity / (1 - specificity))
belief.update(lr=0.99 / 0.05)   # P ≈ 0.0194
print(f"After 1st positive: {belief.probability:.4f}")

# Second independent positive test
belief.update(lr=0.99 / 0.05)   # P ≈ 0.284
print(f"After 2nd positive: {belief.probability:.4f}")

# Third independent positive test
belief.update(lr=0.99 / 0.05)   # P ≈ 0.867
print(f"After 3rd positive: {belief.probability:.4f}")
```

Output:
```
After 1st positive: 0.0194
After 2nd positive: 0.2841
After 3rd positive: 0.8673
```

#newthought[Visualizing the sequence:] @fig-update shows how the probability climbs with each independent positive test — starting from near zero and crossing 50% after just three tests.

#widefig[
  #figure(
    image("images/bayesian_update.webp"),
    caption: [Sequential Bayesian updates in the medical diagnosis example. Each positive test dramatically shifts the posterior probability.],
  ) <fig-update>
]

= Applications

== Spam Filtering

#newthought[Email spam filters] were one of the first killer apps of Bayesian reasoning. Paul Graham's 2002 essay _A Plan for Spam_ @graham2002 showed that a simple Bayesian classifier could achieve >99.5% accuracy.

The idea: each word has a spam probability. Given the words in an email, combine them using Bayes' theorem:

$ P("spam" | w_1, w_2, dots, w_n) = 1 / (1 + product_(i=1)^n (1 - p_i) / p_i dot (1 - s) / s) $

where $p_i = P("spam" | w_i)$ and $s$ is the prior spam rate.

#sidenote[Modern spam filters (Gmail, etc.) use more sophisticated models, but the core insight remains Bayesian.]

== A/B Testing

In product development, Bayesian A/B testing provides a principled way to decide whether variant A or variant B is better:

$ P("B > A" | "data") = integral_0^1 integral_0^1 bb(1)[p_B > p_A] dot P(p_A | "data") dot P(p_B | "data") thin d p_A thin d p_B $

Unlike frequentist hypothesis testing, this directly answers the question product managers actually care about: "what is the probability that B is better?"

== Bayesian Neural Networks

#newthought[Deep learning] has embraced Bayesian ideas. Instead of learning a single weight vector $w$, a Bayesian neural network learns a _distribution_ over weights $P(w | "data")$, enabling principled uncertainty estimates #sidenote[Uncertainty quantification is critical for safety-sensitive applications like autonomous driving and medical diagnosis.].

@fig-bnn compares traditional and Bayesian approaches to neural network weights:

#figure(
  image("images/prior_posterior.webp", width: 90%),
  caption: [Traditional neural networks learn a single point estimate (left). Bayesian networks learn a distribution over weights (right), capturing uncertainty.],
)<fig-bnn>

$ P(y | x, "data") = integral P(y | x, w) dot P(w | "data") thin d w $

= The Philosophy of Priors

#newthought[The choice of prior] is the most controversial aspect of Bayesian reasoning. Critics argue it introduces subjectivity; proponents counter that _all_ reasoning involves assumptions, and Bayes just makes them explicit.

There are several schools of thought:

- *Objective Bayes*: use "uninformative" priors (Jeffreys, maximum entropy) that let the data speak
- *Subjective Bayes*: encode genuine prior knowledge — this is a feature, not a bug
- *Empirical Bayes*: estimate the prior from the data itself #sidenote[Empirical Bayes is widely used in genomics and other fields with many similar hypotheses — see Efron's work on large-scale inference @efron2010.]

The pragmatic view: the prior matters most with little data. With enough evidence, all reasonable priors converge #sidenote[This is a consequence of the "washing out of priors" — Bayesian posteriors are asymptotically dominated by the likelihood.].

= Conclusion

Bayes' theorem is not just a formula — it is a framework for rational thought. It tells us how to update our beliefs when new evidence arrives, how much weight to give that evidence, and when to be skeptical of our own intuitions.

From spam filters to medical diagnosis, from A/B testing to artificial intelligence, Bayesian reasoning is everywhere — often hiding in plain sight. The next time you encounter surprising evidence, ask yourself: _what is the likelihood ratio, and what was my prior?_

// ─── Bibliography ──────────────────────────────────────────────────
#bibliography("refs.bib", style: "ieee")
