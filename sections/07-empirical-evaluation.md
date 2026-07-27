# Empirical Evaluation

This chapter evaluates whether the implemented optimization pipeline improves Router accuracy under controlled conditions. All experiments use the synthetic data introduced in Section 3 because Interhyp could not provide production queries. Consequently, the reported results demonstrate the behavior of the pipeline on the project datasets rather than its performance under live broker traffic.

The evaluation separates two datasets with different purposes. A fixed set of 240 queries serves exclusively as the evaluation dataset and remains unchanged across the baseline and final measurements. A distinct set of 1,000 queries is used to generate judge feedback and optimize the Stage 2 prompt. No query from the fixed evaluation set is included in the optimization data. This separation prevents the optimizer from improving its score by adapting directly to the cases on which the final result is reported.

| Dataset | Number of queries | Purpose | Used for prompt optimization |
|---|---:|---|---|
| Fixed evaluation dataset | 240 | Baseline and final evaluation | No |
| Training dataset | 1,000 | Judge-label generation and OPRO optimization | Yes |

The experiments also distinguish the two routing stages. Stage 1 performs similarity-based routing through the vector store, whereas Stage 2 uses the LLM-based Router and its versioned system prompt. The main optimization experiment deliberately isolates Stage 2. This mirrors Interhyp's current production setup, which has no direct equivalent of the implemented Stage 1, and makes it possible to attribute changes in accuracy to prompt optimization rather than to the growing vector store.

> **[IMAGE PLACEHOLDER — Figure 7.1: Experimental setup]**
>
> Insert a screenshot or diagram showing the fixed 240-query evaluation dataset, the separate 1,000-query training dataset, and the disabled Stage 1 write-back.
>
> *Suggested caption: Experimental setup separating the fixed evaluation dataset from the training data used by the judge and optimizer.*

## Baseline: Stage 2 with the Original Prompt

The baseline was measured in the Evaluation Dashboard on the fixed set of 240 queries. Every query was routed through Stage 2; Stage 1 was not used. The Stage 2 system prompt was intentionally minimal—“You are a Router, route the query to the correct agent”—and was supplemented only by broad descriptions of the eight agents and a small number of few-shot examples. This configuration approximated the routing approach available at Interhyp at the beginning of the project and therefore provided the relevant point of comparison for the optimization pipeline.

The baseline Router correctly assigned 83% of the evaluation queries. The aggregate result concealed a particularly severe class-level failure: when `PlatformSupportAgent` was the golden label, the Router did not select it for any query, resulting in an agent-level accuracy of 0%. The finding illustrates why overall accuracy alone is insufficient in a multi-agent system. A Router can appear broadly functional while completely failing to recognize one specialist domain.

> **[IMAGE PLACEHOLDER — Figure 7.2: Baseline evaluation]**
>
> Insert the Evaluation Dashboard screenshot for the original Stage 2 prompt. The screenshot should show the 83% overall accuracy and the per-agent breakdown, including the 0% result for `PlatformSupportAgent`.
>
> *Suggested caption: Baseline evaluation of the original Stage 2 prompt on the fixed 240-query dataset.*

## Generation of Judge Labels

The next step used the Training Dashboard to process the separate 1,000-query training dataset. For each query, the Router produced a routing decision and the judge compared the selected agent's answer with the answer of the strongest alternative available from the Router's candidate ranking. The resulting verdict and reasoning formed the feedback signal for prompt optimization.

Although the Training Dashboard can normally write judge-confirmed examples back to the Stage 1 vector store, this functionality was explicitly disabled for the experiment. Enabling it would have changed two components at once: new examples could have improved Stage 1 while OPRO modified the Stage 2 prompt. Disabling write-back therefore created a controlled ablation in which any observed improvement had to result from changes to Stage 2. It also made the experiment more directly relevant to Interhyp's current architecture, which has no Stage 1 equivalent.

The 1,000 training queries and 240 evaluation queries remained disjoint throughout the experiment. The judge labels and explanations from the training data were available to the optimizer, but the golden labels of the evaluation queries were not. The final evaluation therefore tests whether the optimized routing rules generalize beyond the cases that produced the optimization signal.

> **[IMAGE PLACEHOLDER — Figure 7.3: Judge-label generation]**
>
> Insert a Training Dashboard screenshot showing the 1,000-query run and the configuration with Stage 1 vector-store write-back disabled.
>
> *Suggested caption: Generation of judge labels on the training dataset with Stage 1 write-back disabled.*

## OPRO-Based Prompt Optimization

The judge-labelled training runs were passed to the Optimization Dashboard, which applies the OPRO-based procedure described in Section 4.4. OPRO treats the Stage 2 system prompt as the optimization variable. In each round, the optimizer proposes candidate prompts based on the existing prompt trajectory, routing examples, and the judge's explanations of previous failures. Each candidate is installed temporarily, evaluated on training cases, and assigned a routing score. The strongest candidate is retained for the next round.

After an optimization run, the resulting prompt was evaluated again through the Training Dashboard. The optimization objective reached 100% on its training cases by the second run, indicating rapid convergence for this prompt and dataset. This training score is not treated as the final result: it reflects performance on data available to the optimization process and can therefore be optimistic. Only the subsequent replay on the fixed 240-query evaluation dataset provides the held-out comparison with the 83% baseline.

<!-- VERIFY BEFORE LATEX CONVERSION: Confirm whether “100% by the second run” refers to the optimizer's internal training cases, a complete 1,000-query Training Dashboard replay, or a validation split. -->

> **[IMAGE PLACEHOLDER — Figure 7.4: Optimization trajectory]**
>
> Insert the Optimization Dashboard screenshot showing the seed prompt, candidate prompts, and convergence to 100% by the second run.
>
> *Suggested caption: OPRO optimization trajectory for the Stage 2 system prompt.*

## Divergence Between Judge Labels and Golden Labels

The synthetic training queries retained their predefined golden labels. This made it possible to evaluate the same Router decisions in two ways: first, by checking whether the selected agent matched the golden label, and second, by checking whether the judge preferred the selected agent's generated answer over the alternative answer. After several optimization runs, the strongest prompt achieved 99% accuracy against the golden labels, while the judge-derived evaluation reported 94% for the same configuration.

| Evaluation signal | Accuracy on the compared training run |
|---|---:|
| Golden agent labels | 99% |
| Judge verdicts | 94% |

The five-percentage-point gap does not necessarily mean that either measurement is internally inconsistent. The two signals measure related but non-identical targets. The golden label grades a closed-set classification decision: it asks whether the Router selected the agent assigned to the query when the dataset was created. The judge instead performs a pairwise assessment of generated answers. Its verdict therefore depends not only on the intended agent class, but also on the particular answers generated for that run and on which alternative the Router placed next in its ranking.

Three mechanisms can consequently produce disagreement:

1. **Ambiguous task boundaries.** Some synthetic queries plausibly fit more than one agent. The golden dataset must nevertheless assign one label, whereas two candidate agents may both return useful answers. The judge can prefer the alternative even when the Router selected the predefined golden agent.
2. **Answer-generation variance.** A correct routing decision does not guarantee that the selected agent produces the better answer in every run. Conversely, an agent that does not match the golden class can occasionally generate a convincing response. The judge evaluates these concrete outputs rather than the routing decision in isolation.
3. **Router-dependent candidate selection.** The judge compares the selected answer with a high-ranked alternative rather than independently classifying the query across all eight agents. If the correct agent is absent from the compared candidates, the judge cannot recover it. As the Router prompt changes, the candidate pairs presented to the judge change as well.

Residual judge error and known LLM-judge biases may add further disagreement. However, the experiment does not support attributing the complete five-point difference to judge error alone. In particular, the judge's separately measured agreement with ground truth belongs to a different evaluation setup and should not be used to “correct” the 94% value mechanically.

Despite the difference in absolute values, judge-assessed accuracy tracked golden-label accuracy across the optimization runs: configurations with higher golden-label accuracy also received higher judge-assessed accuracy. The judge signal was therefore useful for ranking prompt candidates and steering optimization, even though it was not a calibrated estimate of absolute Router accuracy. The 94%-rated prompt was the best-performing candidate according to the signal available to the optimization pipeline and was consequently selected for deployment.

This result demonstrates a positive system-level feedback loop. Judge explanations guided the optimizer toward a stronger Router prompt; the stronger prompt in turn produced better routing decisions and more suitable candidate comparisons in subsequent runs. Strictly speaking, the judge itself was not retrained and did not improve its parameters. The observed flywheel concerns the behavior of the combined Router–judge–optimizer system, not autonomous learning by the judge model.

In a production environment, golden labels are unavailable for ordinary traffic, so the judge becomes the operational reference signal. If the same discrepancy occurred in production, monitoring would report 94% even though a later human-labelled audit might estimate performance closer to 99%. This example should not be interpreted as a stable five-point correction factor: without periodically sampled human labels, neither the direction nor the size of the gap can be assumed to remain constant. The practical implication is that judge-based monitoring can guide optimization, but it should be calibrated periodically against independently labelled production samples.

> **[IMAGE PLACEHOLDER — Figure 7.5: Judge and golden-label comparison]**
>
> Insert a screenshot or chart comparing judge-assessed and golden-label accuracy across optimization runs. It should make both the 99% versus 94% endpoint and the shared upward trend visible.
>
> *Suggested caption: Golden-label and judge-assessed Router accuracy across optimization runs.*

## Final Evaluation and Deployment

The selected prompt was saved as a new Stage 2 prompt version and deployed in the showcase application. Re-running the Stage 2-only configuration on the same fixed 240-query evaluation dataset produced 100% routing accuracy, compared with 83% for the original prompt. Because the dataset and routing stage remained unchanged, this 17-percentage-point improvement can be attributed to the optimized Stage 2 prompt within the experimental setting.

The 100% result is not a typographical error in the final presentation materials. It refers specifically to the optimized **Stage 2-only** configuration. It must be distinguished from the final **two-stage** configuration, which reached 98% on the project evaluation while resolving 78% of queries through Stage 1 and thereby avoiding the corresponding Stage 2 LLM calls. The two-percentage-point reduction was the accepted trade-off for 196 ms lower average latency per query and 78% fewer LLM calls. These configurations answer different empirical questions: the Stage 2-only comparison isolates the effect of prompt optimization, whereas the two-stage result evaluates the accuracy–efficiency trade-off of the complete Router.

| Configuration | Routing stages | Accuracy | Interpretation |
|---|---|---:|---|
| Original prompt | Stage 2 only | 83% | Baseline |
| Optimized prompt | Stage 2 only | 100% | Isolated effect of prompt optimization |
| Optimized full Router | Stage 1 + Stage 2 | 98% | Deployed accuracy–efficiency trade-off |

The result establishes that the implemented pipeline can transform judge feedback into a Stage 2 prompt that generalizes to the held-out synthetic evaluation set. At the same time, 100% accuracy on 240 synthetic queries does not imply error-free production performance. The evaluation set is finite, and synthetic data can only approximate the language, ambiguity, and distribution shifts of real broker traffic. The empirical finding should therefore be read as evidence that the optimization mechanism works under controlled conditions, while validation on independently labelled production data remains necessary.

> **[IMAGE PLACEHOLDER — Figure 7.6: Final Stage 2 evaluation]**
>
> Insert the Evaluation Dashboard screenshot for the optimized Stage 2-only prompt, showing 100% accuracy on the fixed 240-query dataset.
>
> *Suggested caption: Held-out evaluation of the optimized Stage 2 prompt on the fixed 240-query dataset.*

> **[IMAGE PLACEHOLDER — Figure 7.7: Final configuration comparison]**
>
> Insert a comparison screenshot or result graphic showing 83% for the baseline Stage 2 prompt, 100% for the optimized Stage 2 prompt, and 98% for the optimized two-stage Router, together with the latency and avoided-LLM-call results.
>
> *Suggested caption: Accuracy and efficiency comparison of the baseline, optimized Stage 2-only, and optimized two-stage configurations.*
