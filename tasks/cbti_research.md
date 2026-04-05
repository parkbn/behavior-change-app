# CBT-I Research Reference: Digital Sleep Coaching System

## Compiled: 2026-04-02
## Purpose: Evidence-based reference for building a production digital sleep coaching system

---

## 1. Core CBT-I Components (5-6 Standard Modules)

CBT-I consists of **two core components** and **two to three adjunctive components**:

### Core Components

**A. Sleep Restriction Therapy (SRT)**
- The most impactful single component
- Based on the principle that the primary perpetuating factor for chronic insomnia is *sleep extension* -- patients compensate for lost sleep by spending excessive time in bed, which fragments sleep and weakens the bed-sleep association
- Builds homeostatic sleep drive by compressing time in bed to match actual sleep time
- Produces consolidated, efficient sleep that is then gradually expanded

**B. Stimulus Control Therapy (SCT)**
- Addresses maladaptive conditioning (stimulus dyscontrol) where the bed/bedroom has become associated with wakefulness rather than sleep
- Re-establishes the bed as a cue for rapid sleep onset
- Six specific behavioral directives (detailed in Section 5)

### Adjunctive Components

**C. Sleep Hygiene Education (SH)**
- Lifestyle and environmental factors that promote or hinder sleep
- Minimal efficacy as standalone treatment -- must be combined with core components
- Typically delivered as a one-page handout covering caffeine, alcohol, exercise timing, napping, bedroom environment

**D. Cognitive Therapy (CT)**
- Identifies and restructures dysfunctional beliefs about sleep
- Addresses catastrophizing, unrealistic expectations, and misattributions
- Uses Socratic questioning, thought records, and decatastrophization

**E. Relaxation Training (RT)**
- Progressive muscle relaxation (PMR), diaphragmatic breathing, body scan
- Targets somatic and cognitive hyperarousal
- Evidence supports PMR as having the strongest standalone evidence for insomnia

---

## 2. Session Structure and Delivery Protocol

### Standard Format
- **Total sessions**: 6-8 sessions
- **Session 1 duration**: 60-90 minutes (assessment/intake)
- **Sessions 2-8 duration**: 30-60 minutes each
- **Frequency**: Weekly (preferred) or bi-weekly
- **Delivery**: Individual, group, in-person, telehealth, or digital

### Session-by-Session Protocol

| Session | Focus | Key Tasks |
|---------|-------|-----------|
| **Intake** | Assessment and orientation | Presenting complaint, comorbidity screen, start 2-week sleep diary, assessment battery (ISI, DBAS-16), introduce sleep diary format |
| **Session 1** | Sleep education + core behavioral interventions | Review 2-week sleep diary, teach 3P Model (Spielman), introduce sleep restriction and stimulus control, calculate initial sleep window, set prescribed time in bed (PTIB) |
| **Session 2** | Titration + sleep hygiene | Review diary, calculate sleep efficiency, first titration decision, introduce sleep hygiene education, address adherence barriers |
| **Session 3** | Titration + relaxation training | Review diary, titrate sleep window, introduce PMR or breathing exercises, continue adherence strategies |
| **Session 4** | Titration + cognitive therapy I | Review diary, titrate, introduce cognitive restructuring rationale, identify dysfunctional sleep beliefs, begin thought challenging |
| **Session 5** | Titration + cognitive therapy II | Review diary, titrate, continue cognitive work (Socratic questioning, decatastrophization), address remaining adherence issues |
| **Session 6** | Titration + integration | Review diary, titrate, integrate all components, address any remaining barriers |
| **Session 7-8** | Relapse prevention | Review overall progress, discuss maintenance strategies, plan for setbacks, discuss schedule flexibility, schedule 3-month follow-up |

### Key Principle: Every Session Includes
1. Sleep diary review
2. Sleep efficiency calculation
3. Titration decision (increase/maintain/decrease sleep window)
4. Adherence troubleshooting

### Early Termination
Treatment can end before session 8 if significant improvement occurs and both patient and provider agree.

---

## 3. Sleep Diary / Data Tracking

### The Consensus Sleep Diary (2012 Standard)

The standardized sleep diary captures these variables nightly:

**Primary Variables (patient-reported each morning)**

| Variable | Definition | How Collected |
|----------|-----------|---------------|
| **Time to Bed (TTB)** | Clock time the patient got into bed | Self-report |
| **Sleep Onset Latency (SOL)** | Minutes from lights-out to falling asleep | Self-report estimate |
| **Number of Awakenings (NWAK)** | Count of times woken during the night | Self-report |
| **Wake After Sleep Onset (WASO)** | Total minutes awake during the night (excluding SOL) | Self-report estimate |
| **Final Wake Time** | Clock time of final morning awakening | Self-report |
| **Time Out of Bed (TOB)** | Clock time of getting out of bed | Self-report |
| **Sleep Quality** | Subjective rating (1-5 or 1-10 scale) | Self-report |
| **Naps** | Daytime nap duration and timing | Self-report |
| **Medications/substances** | Sleep medications, alcohol, caffeine | Self-report |

**Derived Metrics (calculated from diary data)**

| Metric | Formula | Clinical Threshold |
|--------|---------|-------------------|
| **Total Sleep Time (TST)** | TIB - SOL - WASO | Varies by age; typically 7-9 hrs for adults |
| **Time in Bed (TIB)** | TOB - TTB | Target: gradually approach desired TST |
| **Sleep Efficiency (SE%)** | (TST / TIB) x 100 | Target: >= 85% |
| **Sleep Onset Latency (SOL)** | Direct report | Healthy: < 20 min |
| **Wake After Sleep Onset (WASO)** | Direct report | Healthy: < 30 min |

### Sleep Efficiency Calculation (Two Methods)

**Standard Method (most common, use this for digital system):**
```
SE% = (Total Sleep Time / Time in Bed) x 100
```
Example: TST = 6 hours, TIB = 8 hours --> SE = 75%

**Alternative DSE Method:**
```
SE% = TST / (SOL + TST + WASO + TASAFA) x 100
```
Where TASAFA = time attempting to sleep after final awakening

### Important Notes for Digital Implementation
- Fitness trackers/wearables do NOT replace sleep diaries -- subjective report is the standard
- Sleep diaries should be completed each morning within 30 minutes of rising
- Minimum 1-week baseline before calculating initial sleep window (2 weeks preferred)
- Weekly averages are used for titration decisions, not individual nights

---

## 4. Sleep Restriction Therapy: Specific Protocol

### Step-by-Step Implementation

**Step 1: Establish Baseline**
- Collect minimum 1-2 weeks of sleep diary data
- Calculate average Total Sleep Time (TST) across the baseline period

**Step 2: Set Initial Sleep Window**
- Prescribed Time in Bed (PTIB) = average TST from baseline
- **CRITICAL SAFETY FLOOR: Never set PTIB below 4.5 hours (270 minutes)**
- If average TST < 4.5 hours, set PTIB to 4.5 hours

**Step 3: Set Fixed Wake Time**
- Patient chooses a wake time they can maintain 7 days/week (including weekends)
- This becomes the anchor -- it does not change during treatment
- Consider work schedule, lifestyle, and realistic adherence

**Step 4: Calculate Bedtime**
- Prescribed Bedtime = Fixed Wake Time - PTIB
- Example: Wake time 6:30 AM, PTIB 5.5 hours --> Bedtime = 1:00 AM
- Patient must NOT get into bed before this time, even if sleepy

**Step 5: Weekly Titration (the core algorithm)**

Calculate weekly average Sleep Efficiency:
```
Weekly Avg SE% = (Avg TST / Avg TIB) x 100
```

**Titration Rules:**

| Weekly Avg SE% | Action | Rationale |
|----------------|--------|-----------|
| **> 90%** | Increase PTIB by 15 minutes | Sleep is highly consolidated; safe to expand |
| **85-90%** | Maintain current PTIB | In the target zone; hold steady |
| **< 85%** | Decrease PTIB by 15 minutes | Sleep still fragmented; increase sleep drive |

**Alternative titration schedule used by some protocols:**
- SE >= 85%: increase by 15-30 min
- SE 80-85%: maintain
- SE < 80%: decrease by 15-30 min

**Step 6: Repeat Weekly**
- Each adjustment is held for at least 1 full week before the next titration
- Continue until patient reaches desired TST with SE >= 85%
- Typical endpoint: 7-8 hours TIB with 85%+ efficiency

### Critical Rules During Sleep Restriction
- NO napping (preserves homeostatic sleep drive)
- Fixed wake time every day, including weekends
- No going to bed before prescribed bedtime
- Get out of bed at prescribed wake time regardless of sleep quality
- Expect increased daytime sleepiness in the first 1-2 weeks (this is normal and means it's working)

### Sleep Compression (Alternative for High-Risk Patients)
- Gentler alternative to abrupt sleep restriction
- Gradually reduces TIB by 15-30 minutes per week until TIB matches TST
- Less effective than sleep restriction (failed non-inferiority trial, 2025)
- Use when sleep restriction is contraindicated (epilepsy, bipolar, fall risk)
- Better adherence but slower results

---

## 5. Stimulus Control: Specific Patient Instructions

### The Six Rules of Stimulus Control

Present these to patients as behavioral prescriptions:

**Rule 1: Go to bed only when sleepy**
- Distinguish between "sleepy" (heavy eyelids, nodding off) and "tired" (fatigued but alert)
- Being tired is not the same as being sleepy
- If not sleepy at prescribed bedtime, stay up until sleepy

**Rule 2: Use the bed only for sleep and sex**
- No reading, watching TV, scrolling phone, eating, working, or worrying in bed
- This breaks the bed-wakefulness association
- Sex is the sole exception

**Rule 3: If unable to fall asleep within ~15-20 minutes, get out of bed**
- Do NOT clock-watch -- estimate the time
- Go to another room
- Engage in a quiet, non-stimulating activity (reading a physical book with dim light, light stretching)
- Return to bed only when sleepy again

**Rule 4: Repeat Rule 3 as many times as necessary throughout the night**
- Applies to both initial sleep onset and middle-of-night awakenings
- Each time you are awake in bed for ~15-20 minutes, get up

**Rule 5: Set an alarm and get up at the same time every morning**
- Regardless of how much sleep you got
- This is the anchor of the entire program
- No "sleeping in" on weekends

**Rule 6: Do not nap during the day**
- Napping reduces homeostatic sleep drive
- If patient absolutely must nap (safety concern), limit to 20 minutes before 2 PM

### Rationale to Communicate to Patient
"Your bed has become associated with being awake and frustrated. These rules will retrain your brain to associate the bed with sleeping quickly and easily. It will feel difficult at first, but within 2-3 weeks, your brain will learn the new association."

---

## 6. Cognitive Techniques

### Common Dysfunctional Beliefs About Sleep (DBAS Domains)

**Domain 1: Consequences of Insomnia (Catastrophizing)**
- "Insomnia is destroying my ability to enjoy life"
- "I'm worried that chronic insomnia may have serious consequences on my health"
- "I'm concerned that I can't function well the next day if I don't sleep"
- "A poor night's sleep disrupts my entire week"

**Domain 2: Worry/Helplessness About Insomnia**
- "I have no control over my sleep"
- "My sleep is unpredictable and I never know how I'll sleep"
- "I am unable to cope with the negative consequences of disturbed sleep"
- "I feel that insomnia is basically the result of a chemical imbalance"

**Domain 3: Sleep Expectations (Unrealistic Standards)**
- "I need 8 hours of sleep to feel refreshed and function well"
- "I need to catch up on sleep lost by sleeping longer the next day"
- "If I don't sleep well, I should stay in bed and try harder"

**Domain 4: Medication Beliefs**
- "Taking sleeping pills is the only solution"
- "Medication is probably the only thing that will help my sleep"

### Cognitive Restructuring Protocol

**Step 1: Identify the Thought**
Use a thought record / sleep thought diary:
- Situation: "Lying in bed at 2 AM"
- Automatic thought: "I'll never fall asleep. Tomorrow will be ruined."
- Emotion: Anxiety (8/10)

**Step 2: Examine the Evidence (Socratic Questioning)**
Key questions to ask:
- "What is the evidence that tomorrow will be completely ruined?"
- "Have you had bad nights before? How did the next day actually go?"
- "What is the worst that could realistically happen? How would you cope?"
- "Is there a difference between a bad day and a ruined day?"
- "How many hours of sleep do you actually need to function adequately (not optimally)?"

**Step 3: Generate Alternative Thought**
- "I've had bad nights before and still managed the next day"
- "One bad night is uncomfortable but not dangerous"
- "My body will make up for lost sleep naturally -- I don't need to force it"
- "I can function adequately on less sleep than I think"

**Step 4: Rate Belief and Emotion**
- New belief strength: 6/10
- New emotion: Mild concern (4/10)

### Key Cognitive Reframes for Digital Delivery

| Distortion | Reframe |
|-----------|---------|
| "I need 8 hours or I can't function" | "Most adults function well on 6-7 hours. My minimum functional threshold is probably lower than I think." |
| "I haven't slept in days" | "Research shows people with insomnia underestimate their sleep. You likely slept more than you think." |
| "If I don't sleep tonight, tomorrow is ruined" | "You've survived bad nights before. Discomfort is not danger." |
| "I'll never be a good sleeper" | "Insomnia is a learned pattern, and learned patterns can be unlearned. CBT-I has a 70-80% response rate." |
| "I should try harder to sleep" | "Sleep is a natural process you can't force. Trying harder creates arousal that prevents sleep." |
| "Something is fundamentally wrong with me" | "Your sleep system is intact. It's been hijacked by habits and worry, both of which are fixable." |

---

## 7. Relaxation Techniques

### Evidence Ranking for Insomnia

1. **Progressive Muscle Relaxation (PMR)** -- strongest evidence, AASM recommended as standard treatment (2006)
2. **Diaphragmatic/slow breathing** -- strong evidence, easy to teach digitally
3. **Body scan meditation** -- moderate evidence, overlaps with mindfulness
4. **Autogenic training** -- moderate evidence, AASM recommended
5. **Guided imagery** -- moderate evidence, useful for cognitive arousal
6. **Mindfulness meditation** -- growing evidence, addresses cognitive component differently (acceptance vs. disputation)

### Progressive Muscle Relaxation Protocol (16 Muscle Groups -> 7 -> 4)

**Full Version (16 muscle groups, ~20 minutes):**
1. Right hand and forearm (make a fist)
2. Right upper arm (bicep curl)
3. Left hand and forearm
4. Left upper arm
5. Forehead (raise eyebrows)
6. Eyes and cheeks (squint tightly)
7. Mouth and jaw (press lips together)
8. Neck (press head back or forward)
9. Shoulders (shrug up to ears)
10. Chest (deep breath, hold)
11. Stomach (tighten abdominal muscles)
12. Upper back (pull shoulder blades together)
13. Right thigh (press down or extend leg)
14. Right calf (point toes up)
15. Right foot (curl toes)
16. Left thigh, calf, foot (same sequence)

**Instruction for each group:**
- Tense the muscle group for 5-7 seconds
- Release and notice the contrast for 15-20 seconds
- Focus attention on the sensation of relaxation
- Move to next group

**Abbreviated versions**: Once learned, condense to 7 then 4 muscle groups, then eventually "relaxation by recall" (no tensing needed).

### Diaphragmatic Breathing (4-7-8 Technique)
- Inhale through nose for 4 counts
- Hold for 7 counts
- Exhale through mouth for 8 counts
- Repeat 4 cycles
- Alternative: simple slow breathing (4 in, 6 out)

### Implementation Notes for Digital Delivery
- Audio-guided instructions are most effective
- Start with PMR in session 3 or 4
- Practice daily, not just at bedtime (to avoid becoming a "sleep effort" tool)
- 2-week minimum practice period before expecting sleep benefits
- Meta-analyses show PMR rivals mindfulness and slow breathing for lowering cortisol and blood pressure within 2 weeks

---

## 8. Digital CBT-I: Platform Analysis and Design Patterns

### Major Digital CBT-I Products

**Sleepio (Big Health) -- SleepioRx**
- Web and app-based, animated virtual therapist ("The Prof")
- 6 sessions delivered over ~6-12 weeks
- 26 clinical trials including 18 RCTs
- Up to 76% of patients achieve healthy sleep post-treatment
- Uses daily sleep diary for personalization
- Dynamic content adjustment based on user progress
- FDA-cleared as prescription digital therapeutic

**Somryst (Pear Therapeutics)**
- FDA-cleared prescription digital therapeutic (first for insomnia, 2020)
- 6 core sessions (9 weeks total)
- Personalized sleep scheduling based on diary data
- Significant reductions in ISI, anxiety, and depression scores
- Interactive exercises with animations

**CBT-i Coach (VA/DoD)**
- Free companion app (not standalone treatment)
- Sleep diary tracking
- Guided relaxation exercises
- Educational content on CBT-I principles
- Designed as clinician adjunct, not replacement

### What Works in Digital Delivery

**Engagement Drivers:**
- AI-enabled conversational agents show 3x engagement increase (2.4x higher usage frequency, 3.8x longer usage durations)
- Guided conditions (human or chatbot coaching) show 2x adherence rates vs. unguided
- Personalization based on sleep diary data is critical
- Daily micro-interactions outperform weekly long sessions
- Animations and interactive content maintain engagement

**Design Patterns That Work:**
1. **Daily sleep diary collection** -- brief morning check-in (2-3 minutes)
2. **Automated sleep window calculation** -- removes cognitive burden from patient
3. **Personalized titration recommendations** -- algorithm-driven, presented conversationally
4. **Psychoeducation delivery** -- bite-sized, spaced across sessions
5. **Motivational messaging** -- normalize difficulty, celebrate small wins
6. **Progress visualization** -- sleep efficiency trends, TST graphs
7. **Guided audio exercises** -- PMR, breathing, body scan
8. **Reminders and nudges** -- bedtime alerts, morning diary prompts

**Key Digital Design Decisions:**
- ~50 micro-sessions over 7 weeks (not 6-8 long sessions)
- Dynamic fitting of treatment to user progress and changing needs
- Daily diary is the engine of personalization
- Conversational interface preferred over form-based for engagement
- LLM-powered agents can provide personalized treatment recommendations based on patient feedback

### Comparison: Fully Automated vs. Guided Digital CBT-I

| Feature | Fully Automated | Guided (Human/Chatbot) |
|---------|----------------|----------------------|
| Adherence | ~50% | ~60% |
| Effect size on ISI | Moderate-large | Large |
| Scalability | High | Moderate |
| Cost | Low | Higher |
| Personalization | Algorithm-based | Algorithm + human judgment |
| Engagement | Lower | 2-3x higher |

**Recommendation for your system**: Chatbot-guided delivery with automated sleep algorithms provides the best balance of scalability and engagement.

---

## 9. Motivational Techniques and Adherence

### The Adherence Problem
- Sleep restriction is inherently uncomfortable -- patients feel worse before they feel better
- Treatment adherence: ~60% in-person, ~50% digital
- Sleep restriction adherence is the single biggest predictor of treatment success
- Weeks 1-2 are the highest dropout risk period

### Predictors of Better Adherence
- Higher baseline motivation
- Greater self-efficacy ("I believe I can do this")
- Social support (partner, accountability)
- Fewer dysfunctional beliefs at baseline
- Better early sleep improvement (success breeds adherence)

### Motivational Strategies for Digital Delivery

**1. Pre-Treatment Motivational Enhancement**
- Explore ambivalence about change (MI-style)
- Ask: "What would better sleep mean for your life?"
- Build discrepancy between current sleep and desired sleep
- Assess readiness to change and adjust pacing accordingly

**2. Psychoeducation as Motivation**
- Explain WHY sleep restriction works (sleep drive analogy: "The longer you're awake, the stronger your sleep pressure builds, like a rubber band being pulled back")
- Frame initial discomfort as a positive signal: "Daytime sleepiness in the first week means the treatment is building your sleep drive -- it's working"
- Normalize the difficulty: "Most people find the first 2 weeks the hardest. It gets significantly easier after that."

**3. Weekly Confidence Scaling**
- "On a scale of 0-10, how confident are you that you can stick with your sleep window this week?"
- If < 7: explore barriers and problem-solve
- If >= 7: reinforce and proceed

**4. Specific Adherence Strategies (from clinical research)**

| Barrier | Strategy |
|---------|----------|
| "I can't stay up until 1 AM" | Schedule engaging evening activities; plan what to do during the buffer time |
| "I can't get up at 6 AM when I didn't sleep" | Place alarm across the room; plan immediate morning activity (walk, shower) |
| "I keep falling asleep before my bedtime" | Stay in well-lit area; avoid reclining; schedule social activity |
| "I can't avoid napping" | Reframe sleepiness as success; go for a walk instead; brief cold water on face |
| "Weekends are impossible" | Emphasize that consistency is the treatment; plan weekend morning activities |
| "I want to increase my sleep window faster" | Explain that biological clock restoration takes time; distinguish years of insomnia from weeks of treatment |

**5. Progress Reinforcement**
- Show SE% trend graphs weekly
- Celebrate crossing 85% threshold
- Highlight concrete improvements: "Your SOL went from 45 minutes to 18 minutes in 3 weeks"
- Use comparative framing: "You're now falling asleep faster than the average person"

**6. Accountability Through Daily Check-ins**
- Brief morning diary completion serves dual purpose: data collection + daily engagement
- Evening reminder of bedtime serves as a nudge
- "How did last night go?" -- opens conversation, not just data entry

---

## 10. Contraindications and Safety

### Absolute Contraindications for Sleep Restriction Component

| Condition | Risk | Modification |
|-----------|------|-------------|
| **Bipolar disorder (I or II)** | Sleep deprivation can trigger manic/hypomanic episodes | Exclude sleep restriction; use stimulus control, cognitive therapy, sleep hygiene, relaxation only |
| **Seizure disorder / epilepsy** | Sleep loss lowers seizure threshold | Exclude sleep restriction; use sleep compression if any restriction is attempted |
| **High fall risk (elderly, mobility issues)** | Daytime sleepiness increases fall risk | Use sleep compression instead; slower titration |
| **Untreated obstructive sleep apnea** | Sleep restriction can worsen daytime sleepiness in untreated OSA | Treat OSA first (CPAP), then add CBT-I; or modify protocol with close monitoring |

### Relative Contraindications / Precautions

| Condition | Approach |
|-----------|----------|
| **Parasomnias (sleepwalking, night terrors)** | Sleep restriction may exacerbate; use with caution, exclude SRT if severe |
| **Shift work / highly variable schedule** | Standard CBT-I assumes regular schedule; requires significant adaptation; consider referral |
| **Pregnancy** | Sleep restriction generally not recommended; focus on sleep hygiene, relaxation, cognitive therapy |
| **Active substance abuse** | May complicate assessment and adherence; consider treating substance use first |
| **Severe psychiatric conditions (active psychosis, severe depression with suicidality)** | Stabilize psychiatric condition first; CBT-I can exacerbate mood symptoms via sleep loss |
| **Circadian rhythm disorders (DSPD, ASPD)** | These require circadian interventions (light therapy, chronotherapy), not standard CBT-I |

### Safety Screening for Digital System

**Must-screen before starting sleep restriction:**
1. "Have you ever been diagnosed with bipolar disorder?" -- GATE
2. "Do you have epilepsy or a seizure disorder?" -- GATE
3. "Do you have untreated sleep apnea?" -- GATE
4. "Are you at risk for falls?" -- GATE for older adults
5. "Are you currently pregnant?" -- GATE
6. "Do you drive or operate heavy machinery? How far is your commute?" -- safety counseling

**If any GATE condition is positive:**
- Do NOT implement sleep restriction
- Offer modified CBT-I (stimulus control + cognitive therapy + sleep hygiene + relaxation)
- Recommend clinician referral for supervised treatment
- Document the screening result

### Sleep Compression as Safe Alternative
- Gradually reduces TIB by 15-30 min/week (vs. abrupt restriction)
- Less effective but safer for contraindicated populations
- Better adherence, fewer side effects
- Valid fallback when sleep restriction cannot be used

---

## 11. Evidence Base

### Key Meta-Analyses and Efficacy Data

**Overall CBT-I Efficacy:**
- Treatment effect sizes: 1.0-1.2 (large) on insomnia severity
- ~50% post-treatment symptom reduction
- 70-80% response rate
- 40% full remission rate
- Clinical gains maintained up to 24 months post-treatment
- As effective as sedative-hypnotics acutely (4-8 weeks) and MORE effective long-term (3+ months)

**Digital CBT-I (dCBT-I) Efficacy:**

| Meta-Analysis | N Studies | N Participants | Finding |
|--------------|-----------|----------------|---------|
| Fully automated dCBT-I (2025, npj Digital Medicine) | 29 RCTs | 9,475 | Moderate-large effects on insomnia severity |
| dCBT-I for insomnia + depression (2023, PeerJ) | 7 studies | 3,597 | Short-term SMD: -0.85; long-term SMD: -0.71 |
| Internet-delivered CBT (2024, meta of 154 RCTs) | 154 RCTs | -- | Effects maintained 1+ year post-treatment |

**Sleep Parameter Improvements (dCBT-I):**
- Sleep Onset Latency: 51.66% improvement
- Wake After Sleep Onset: 53.37% improvement
- Sleep Efficiency: significant improvement
- Total Sleep Time: significant improvement

**Digital vs. Therapist-Delivered:**
- dCBT-I comparable to therapist-delivered CBT-I in some analyses
- Therapist-assisted dCBT-I slightly outperforms fully automated
- Both superior to inactive controls
- Digital delivery is a valid alternative when conventional therapy is unavailable

**Regulatory and Policy:**
- Somryst: FDA-cleared (2020) as prescription digital therapeutic for chronic insomnia
- Sleepio: FDA-cleared for insomnia
- CMS (2025): Established national policy and reimbursement codes for FDA-cleared digital mental health treatments

### Key Guideline Recommendations
- **AASM (2021)**: CBT-I recommended as first-line treatment for chronic insomnia in adults
- **ACP (American College of Physicians)**: CBT-I recommended as initial treatment before pharmacotherapy
- **World Sleep Society**: Endorsed AASM behavioral/psychological treatment guidelines

---

## 12. Measurement Tools for Digital Delivery

### Insomnia Severity Index (ISI) -- PRIMARY RECOMMENDED

**Best suited for digital/chatbot delivery.**

- **Items**: 7 questions
- **Scale**: 0-4 Likert per item
- **Total score range**: 0-28
- **Time to complete**: 2-3 minutes
- **Administration frequency**: Baseline, weekly or bi-weekly, post-treatment, follow-up

**The 7 Items:**
1. Difficulty falling asleep (severity)
2. Difficulty staying asleep (severity)
3. Problems waking up too early (severity)
4. Satisfaction with current sleep pattern
5. Interference with daily functioning
6. Noticeability of sleep problems by others
7. Distress/worry caused by sleep difficulties

**Scoring Interpretation:**

| Score | Category | Clinical Action |
|-------|----------|----------------|
| 0-7 | No clinically significant insomnia | No treatment needed / treatment success |
| 8-14 | Subthreshold insomnia | Monitor; may benefit from sleep hygiene |
| 15-21 | Moderate clinical insomnia | CBT-I indicated |
| 22-28 | Severe clinical insomnia | CBT-I indicated; consider comorbidity assessment |

**Clinically Meaningful Change**: Reduction of >= 8 points = treatment response; >= 5 points = minimally important difference

**Digital Implementation**: Each item can be presented as a single chatbot question with a 5-point response scale. Total takes <2 minutes. Ideal for weekly tracking.

### Dysfunctional Beliefs and Attitudes About Sleep (DBAS-16)

- **Items**: 16 statements
- **Scale**: 0-10 agreement scale per item
- **Scoring**: Sum all items, divide by 16 for average score
- **Higher scores** = more dysfunctional beliefs
- **No established clinical cutoff** (normative data limited)
- **Use**: Baseline and post-treatment to measure cognitive change
- **Four subscales**: Consequences, Worry/Helplessness, Sleep Expectations, Medication

**Four Factor Domains with Sample Items:**
1. **Consequences of insomnia**: "Insomnia is destroying my ability to enjoy life"
2. **Worry/helplessness**: "I have no control over my sleep"
3. **Sleep expectations**: "I need 8 hours of sleep to function"
4. **Medication**: "Medication is probably the only thing that will help"

**Digital Implementation**: Can be delivered as a chatbot questionnaire but is longer (16 items at 0-10 scale). Best used at baseline and post-treatment rather than weekly. Could deliver 4 items per session across 4 sessions.

### Pittsburgh Sleep Quality Index (PSQI)

- **Items**: 19 questions across 7 domains
- **Domains**: Subjective quality, latency, duration, efficiency, disturbances, medication use, daytime dysfunction
- **Score range**: 0-21 (each domain 0-3)
- **Clinical cutoff**: > 5 indicates poor sleep quality
- **Time frame**: Past 30 days
- **Digital suitability**: MODERATE -- 19 items is lengthy for chatbot; better suited for baseline/endpoint only
- **Note**: ISI is preferred over PSQI for tracking treatment response in CBT-I

### Recommended Assessment Strategy for Digital System

| Timepoint | Tool | Purpose |
|-----------|------|---------|
| **Screening** | ISI (7 items) + safety screen | Determine eligibility and severity |
| **Baseline** | ISI + DBAS-16 + sleep diary | Full assessment before treatment |
| **Weekly** | Sleep diary (daily) + ISI (weekly) | Track progress, drive titration |
| **Mid-treatment** | ISI + brief adherence check | Assess response, adjust approach |
| **Post-treatment** | ISI + DBAS-16 | Measure outcomes |
| **Follow-up (1, 3, 6 months)** | ISI | Monitor maintenance of gains |

---

## 13. The 3P Model (Spielman) -- Psychoeducation Framework

### Core Concept for Patient Education

The 3P model is the theoretical backbone of CBT-I and should be taught in Session 1 of any digital program.

**Predisposing Factors** (vulnerability traits -- always present)
- Genetics (family history of insomnia)
- Personality (anxiety-prone, perfectionist, ruminator)
- Age and sex
- Hyperarousal tendency
- These make someone MORE LIKELY to develop insomnia but don't cause it alone

**Precipitating Factors** (the trigger)
- Stressful life event (job loss, divorce, illness, new baby)
- Medical condition onset
- Schedule change
- Trauma
- These push someone over the "insomnia threshold"
- Acute insomnia typically resolves when the trigger resolves

**Perpetuating Factors** (what keeps insomnia going after the trigger is gone)
- Spending too much time in bed (sleep extension)
- Irregular sleep schedule
- Napping to compensate
- Using bed for non-sleep activities (phone, TV, worrying)
- Catastrophizing about consequences of poor sleep
- Clock-watching
- Using alcohol or medications as sleep aids
- These are the targets of CBT-I

### How to Explain to Patients (Digital Script)

"Most people with chronic insomnia can point to a time when their sleep problems started -- maybe a stressful period at work, a health scare, or a major life change. That's the trigger.

The interesting thing is: the trigger usually goes away, but the insomnia doesn't. Why?

Because during that stressful time, you developed habits to cope -- staying in bed longer, napping during the day, scrolling your phone in bed, worrying about sleep. These habits made sense at the time, but they accidentally trained your brain to associate the bed with being awake.

The good news: since these are learned habits, they can be unlearned. That's exactly what this program does."

---

## 14. Implementation Recommendations for Digital Sleep Coaching System

### Architecture Recommendations

1. **Daily sleep diary** as the data backbone -- every personalization decision flows from this
2. **Automated SE% calculation and titration engine** -- the core algorithm
3. **Safety screening gate** before any sleep restriction
4. **ISI as primary outcome measure** -- administer at baseline, weekly, and post-treatment
5. **Conversational delivery** -- chatbot interface with LLM for personalization, empathy, and Socratic questioning
6. **Structured session progression** -- 6-8 modules delivered over 6-9 weeks
7. **Audio-guided relaxation** -- PMR and breathing exercises
8. **Progress dashboards** -- SE% trends, SOL/WASO improvements, ISI scores over time

### Session Flow for Chatbot

```
Week 0:     Screening (ISI + safety) --> Start sleep diary
Week 1:     Baseline diary collection (7+ nights)
Week 2:     Session 1: 3P model + sleep restriction + stimulus control
Week 3:     Session 2: Titration + sleep hygiene
Week 4:     Session 3: Titration + relaxation (PMR intro)
Week 5:     Session 4: Titration + cognitive therapy I
Week 6:     Session 5: Titration + cognitive therapy II
Week 7:     Session 6: Titration + integration
Week 8-9:   Session 7: Relapse prevention + maintenance plan
```

### Daily Interaction Pattern
- **Morning (within 30 min of waking)**: Sleep diary entry (2-3 min conversational)
- **Evening (1 hour before prescribed bedtime)**: Bedtime reminder + optional relaxation exercise
- **Weekly**: Module delivery (10-15 min) + ISI check-in + titration review

---

## Sources

- [CBT-I: A Primer (PMC, 2023)](https://pmc.ncbi.nlm.nih.gov/articles/PMC10002474/)
- [Sleep Restriction and CBTI (Stanford Health Care)](https://stanfordhealthcare.org/medical-treatments/c/cognitive-behavioral-therapy-insomnia/procedures/sleep-restriction.html)
- [Stimulus Control and CBTI (Stanford Health Care)](https://stanfordhealthcare.org/medical-treatments/c/cognitive-behavioral-therapy-insomnia/procedures/stimulus-control.html)
- [CBT-I FAQs (Center for Deployment Psychology)](https://deploymentpsych.org/content/faqs-cognitive-behavioral-therapy-insomnia-cbt-i)
- [CBT-I Components (UPenn CBTI Program)](https://www.med.upenn.edu/cbti/assets/user-content/documents/2.2%20COMPONENTS%20OF%20CBT-I.pdf)
- [DBAS-16 Validation (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC2082102/)
- [ISI Psychometric Indicators (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC3079939/)
- [Changes in Dysfunctional Beliefs After CBT-I: Meta-analysis (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC7012685/)
- [Digital CBT-I Platforms and Characteristics (AASM)](https://aasm.org/digital-cognitive-behavioral-therapy-for-insomnia-platforms-and-characteristics/)
- [Fully Automated Digital CBT-I Meta-analysis (npj Digital Medicine, 2025)](https://www.nature.com/articles/s41746-025-01514-4)
- [dCBT-I for Insomnia and Depression Meta-analysis (PeerJ, 2023)](https://peerj.com/articles/16137/)
- [AI-Enhanced CBT-I: Neurocognitive Mechanisms (MDPI, 2025)](https://www.mdpi.com/2077-0383/14/7/2265)
- [LLM-based CBT-I: Future of Insomnia Treatment (ScienceDirect, 2025)](https://www.sciencedirect.com/science/article/pii/S2590142725000205)
- [AI Conversational Agent Increases CBT Engagement (Nature Communications Medicine, 2025)](https://www.nature.com/articles/s43856-025-01321-8)
- [Adherence to CBT-I: Systematic Review (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC3720832/)
- [Adherence to Sleep Restriction Therapy (Wiley, 2023)](https://onlinelibrary.wiley.com/doi/10.1111/jsr.13975)
- [Sleep Compression vs. Sleep Restriction Non-inferiority Trial (SLEEP, 2025)](https://academic.oup.com/sleep/article/48/8/zsaf093/8109686)
- [Relaxation for Insomnia (UPenn CBTI Program)](https://www.med.upenn.edu/cbti/assets/user-content/documents/Lichstein_RelaxationforInsomnia-BTSD.pdf)
- [AASM Clinical Practice Guideline for Chronic Insomnia (PMC, 2021)](https://pmc.ncbi.nlm.nih.gov/articles/PMC7853203/)
- [Somryst Safety and Efficacy Profile (PubMed)](https://pubmed.ncbi.nlm.nih.gov/33226269/)
- [SleepioRx Clinical Evidence (Big Health)](https://www.bighealth.com/sleepio-rx)
- [Measuring Sleep Efficiency: Denominator Discussion (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC4751425/)
- [Sleep Foundation: CBT-I Overview](https://www.sleepfoundation.org/insomnia/treatment/cognitive-behavioral-therapy-insomnia)
- [3P Model Natural History of Insomnia (PMC, 2022)](https://pmc.ncbi.nlm.nih.gov/articles/PMC8826168/)
- [Edinger CBT-I Treatment Manual (UNC)](https://www.med.unc.edu/neurology/wp-content/uploads/sites/716/2018/05/jdedingrCBTManual.pdf)
