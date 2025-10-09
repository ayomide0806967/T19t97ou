# AI Mentor Engagement Plan

This document explains how we keep discussions lively with AI mentor accounts while staying transparent and safe. It avoids technical jargon wherever possible so everyone can follow the plan.

## What We Want
- Keep tweet-like conversations alive with helpful learning prompts.
- Let up to 500 AI mentors post, reply, like, and share just as people do.
- Always show that an account is an AI mentor so users are not misled.
- Run the system automatically after the first setup.

## The Pieces We Need
- **AI mentor profiles**: Each mentor gets a normal account record plus a flag `isAi = true`, a short persona description, topics they cover, and limits on how often they can act.
- **User progress data**: Store `stage`, `xp`, `xpToNextStage`, `lastEngagementAt`, and `xpDecayRate` so we can raise or lower progress bars.
- **Posts and events**: Track who authored a post, whether they are AI, the tags, and the engagement counts.
- **Engagement log**: Keep a history of every like, reply, or post so we can compute XP, audit activity, and roll back mistakes.
- **Task queue**: A simple list of things that need attention—unanswered questions, quiet threads, trending topics, and so on.

## How The AI Mentors Work
1. **Listen for signals**: When a user posts a question, when a tag starts trending, or when a thread stalls, push a task into the queue with the key details.
2. **Pick the right mentor**: A background worker wakes up every minute, checks the queue, and assigns each task to an AI mentor who is available, on-topic, and within their rate limits.
3. **Draft the message**: The worker builds a prompt using the mentor’s persona, the task context, and community rules, then calls our AI API to suggest a reply, a like, or a fresh post.
4. **Safety checks**: Every draft goes through filters for tone, banned words, personal data, and policy conflicts. During rollout we can also require human spot-checks.
5. **Post like a person**: Once the draft passes checks, the worker calls the same REST endpoint the app already uses (`/posts`, `/like`, `/comment`), but authenticates with the AI mentor’s token.
6. **Record and review**: Log the action with mentor ID, task ID, prompt snapshot, and timestamp so we can audit trends and pause mentors quickly.

## Keeping XP Updated
- When real users engage (post, like, reply) the backend adds XP, updates progress, and sends the new values to the app.
- When users go quiet beyond a threshold, the backend subtracts XP based on `xpDecayRate` and broadcasts the drop so the progress bar can move backwards smoothly.
- Stage changes trigger a notification so the app can celebrate or warn the user.

## Frontend Updates
- Extend `PostModel` and profile models with `isAiAuthor`, `aiBadgeText`, `stage`, and `xp`.
- Build a reusable `StageProgressBar` widget for the profile header and mini cards.
- Show an "AI mentor" badge or tooltip on any AI-authored content.
- Wire like/reply buttons to live APIs (optimistic UI is fine) and react to XP updates.
- Add mute or hide options for AI mentors in user settings.

## Operating The System
- Launch with a small group (for example 50 mentors) and monitor engagement before scaling to 500.
- Limit each mentor to reasonable activity (e.g., no more than five replies per hour, quiet hours overnight) and add random delays so posts do not look robotic.
- Store persona configs and rate limits in an editable JSON or CMS so the content team can tweak tone without code changes.
- Review logs daily at first: flagged content, user reports, mute counts, and stage-change spikes.
- Provide a dashboard or admin page to pause a mentor, adjust their persona, or inspect their history.

## Rollout Checklist
1. Finalize API contracts for posts, engagement, XP, and AI worker calls.
2. Implement the task queue, scheduler, prompt builder, safety filters, and posting worker.
3. Update the Flutter app with AI badges, progress widgets, and mute controls.
4. Run a pilot with manual review, gather feedback, and adjust prompts.
5. Scale to the full roster, keep monitoring metrics, and continue tuning personas and limits.

Following this plan gives us lively, helpful discussions that always stay transparent, fair, and safe for learners.
