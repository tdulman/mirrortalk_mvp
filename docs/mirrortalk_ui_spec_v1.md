# MirrorTalk UI Spec V1

Status: Draft for implementation on `phase-9-polish`

## Product Principle

MirrorTalk turns the phone from a distraction surface into a private mirror.
The interface should make it easy to pause, speak honestly, and return to life
with one small commitment.

The app is not a social feed, not a coaching platform, and not a dopamine habit
game. It is a quiet self-talk ritual for morning intention, evening reflection,
and weekly review.

## Research Basis

- Apple platform design favors clarity, deference, depth, legibility, and
  system-native behavior. MirrorTalk should feel natural on iOS without copying
  every Apple component literally.
- Apple San Francisco is suitable as the default system type family. It is
  legible, familiar to iOS users, and supports the future localization plan.
- Minimalism means removing nonessential noise, not removing useful context.
  MirrorTalk should show only what helps the current ritual.
- Progressive disclosure should hide advanced settings, archive details,
  retention behavior, and diagnostics until the user needs them.
- Accessibility is part of the premium feel. Body text and controls should meet
  WCAG AA contrast targets, with 4.5:1 as the default text contrast bar.

Reference sources:
- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- Apple Fonts: https://developer.apple.com/fonts/
- Nielsen Norman Group, Aesthetic and Minimalist Design: https://www.nngroup.com/articles/aesthetic-minimalist-design/
- Nielsen Norman Group, Progressive Disclosure: https://www.nngroup.com/articles/progressive-disclosure/
- WCAG contrast guidance: https://www.w3.org/WAI/WCAG22/quickref/#contrast-minimum

## Visual Mood

Keywords:
- calm
- private
- cinematic
- minimal
- grounded
- humane
- reflective

Avoid:
- loud gradients
- streak addiction visuals
- social media framing
- dense dashboards
- nested cards
- decorative blobs or generic illustrations
- shame-based copy
- celebratory noise after every action

## Color Tokens

The palette should feel warm, quiet, and slightly cinematic. It should not read
as a single-color green app.

| Token | Hex | Use |
| --- | --- | --- |
| `mtBackground` | `#F7F4EF` | Primary app background |
| `mtSurface` | `#FFFDFC` | Sheets, panels, input surfaces |
| `mtSurfaceMuted` | `#ECE7DE` | Subtle grouped areas |
| `mtInk` | `#1D1D1F` | Primary text |
| `mtInkMuted` | `#6E6A64` | Secondary text |
| `mtPrimary` | `#2F5D50` | Primary actions, selected state |
| `mtPrimaryPressed` | `#24483E` | Pressed primary actions |
| `mtAccent` | `#B9854D` | Rare warmth: reflection highlights |
| `mtSuccess` | `#587B5F` | Done states, calm progress |
| `mtWarning` | `#B7791F` | Retention/permission warnings |
| `mtDanger` | `#A4473F` | Destructive actions |
| `mtBorder` | `#DDD6CC` | Dividers, input borders |

Rules:
- Background should be warm off-white, not pure white.
- Primary green should be used sparingly so it keeps meaning.
- Accent amber is for emphasis, not decoration.
- Streak UI should use `mtSuccess`, not fire/red/orange addiction cues.
- Destructive actions must be visibly distinct and confirmed.

## Typography

Use the platform system font. On iOS this maps to San Francisco.

| Role | Size | Weight | Notes |
| --- | ---: | --- | --- |
| Display | 34 | 700 | Rare. First-run manifesto or major ritual prompt only |
| Screen title | 28 | 700 | Main screen headings |
| Section title | 20 | 600 | Today, Journal, Privacy |
| Body | 17 | 400 | Main readable copy |
| Body strong | 17 | 600 | Inline emphasis |
| Secondary | 15 | 400 | Captions and helper copy |
| Label | 13 | 500 | Metadata, chips, small statuses |

Rules:
- Do not scale fonts with viewport width.
- Letter spacing stays at 0.
- Prefer short, direct labels.
- Long reflective prompts may use body text, not headline styling.
- Support Dynamic Type later; do not hard-code tiny text for critical actions.

## Spacing And Radius

Spacing tokens:
- `space4`: 4
- `space8`: 8
- `space12`: 12
- `space16`: 16
- `space20`: 20
- `space24`: 24
- `space32`: 32

Layout:
- Screen horizontal padding: 20 on iPhone.
- Major vertical gaps: 24 or 32.
- Related controls: 8 or 12.
- Dense dashboards are not allowed on the primary screen.

Radius:
- Cards and repeated list surfaces: 8.
- Input fields: 8.
- Buttons: 8.
- Full-width bottom sheets may use the platform default top radius.

## Component Rules

### Primary Action

There should usually be one main action per screen.

Preferred labels:
- `Start Mirror Talk`
- `Save Reflection`
- `Use Transcript`
- `Review This Week`

Avoid generic labels when context matters:
- Avoid `Add` when the action is a ritual.
- Avoid `Submit`.
- Avoid `Continue` unless progression is obvious.

### Cards

Cards are for repeated entries or focused tools. Do not put cards inside cards.
Page sections should be unframed or separated by spacing and dividers.

### Chips

Chips are for low-commitment filters such as Today, Week, Month, All. They
should not become the main navigation system.

### Inputs

Inputs should feel like prompts, not forms. Use labels that invite reflection:
- `Today I will...`
- `Because...`
- `What did I notice?`

Avoid:
- unnecessary duration fields
- technical labels
- placeholder-only meaning

### Feedback

Feedback should be quiet:
- small haptic taps for selection
- snackbars for saved/deleted states
- no confetti
- no loud streak celebration

## Screen Direction

### Today

Purpose: orient the user to the next meaningful self-talk ritual.

Priority order:
1. Current ritual prompt: morning, evening, or weekly review.
2. Primary action: `Start Mirror Talk`.
3. Today's intention and three gentle goals.
4. Calm streak/progress summary.
5. Recent reflections.

### Mirror Talk Recording

Purpose: make the camera feel like a private mirror.

Rules:
- Full-screen camera preview.
- Minimal overlay.
- Prompt visible but not dominant.
- Recording duration can be visible, but not competitive.
- No social camera affordances such as filters, likes, stickers, or share-first UI.

Prompt modes:
- First run: identity manifesto.
- Morning: intention plus because statement.
- Evening: accomplishment, obstacle, next commitment.
- Weekly: rewind, pattern, next week.

### Journal

Purpose: preserve the story without becoming a feed.

Each entry should show:
- ritual type
- date/time
- transcript preview
- video availability state
- tags or goals only when useful

Video states:
- `Available`: local video can be played.
- `Expires soon`: local video remains but retention will remove it soon.
- `Expired`: transcript and metadata remain; video is gone.

### Entry Detail

Purpose: let the user revisit and refine a reflection.

Must support:
- video playback when available
- permanent transcript
- editable tags
- save action
- calm expired-video message

### Settings

Purpose: privacy and rhythm, not configuration overload.

Top-level sections:
- Reminders
- Video retention
- Privacy
- Feedback
- About

Default retention:
- Transcript remains indefinitely.
- Local video is retained for 7 days by default.
- Future cloud archive is a possible paid feature, but not part of MVP.

## Copy Voice

Tone:
- calm
- direct
- self-compassionate
- non-clinical
- non-hype

Use:
- `Notice what happened.`
- `Keep the reflection. Let the video fade.`
- `What made this matter today?`
- `One honest minute is enough.`

Avoid:
- `Crush your goals`
- `Don't break the streak`
- `You failed`
- `Level up`
- `Unlock`

## Localization Rule

New user-facing strings should be written so they can move into Flutter
localization files. Avoid hard-coded string composition that will be hard to
translate later.

Good:
- one complete sentence per string
- clear keys based on meaning
- no embedded grammar assumptions

Bad:
- joining sentence fragments in code
- relying on English word order
- mixing user-facing strings with business logic

## Implementation Order

1. Stabilize analyzer and tests.
2. Add theme tokens in code.
3. Add localization foundation with English strings.
4. Redesign Today around the Mirror Talk ritual.
5. Restore iOS-first video recording.
6. Update Journal and Entry Detail for permanent transcript plus temporary video.
7. Refine Settings around reminders, retention, and privacy.

