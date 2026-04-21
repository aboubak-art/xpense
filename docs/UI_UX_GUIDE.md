# Xpense - UI/UX Design Guide

## Design Philosophy

**"Calm Control"** — Financial tracking should feel grounding, not stressful. Every interaction reinforces the user's sense of agency over their money. The app breathes: generous whitespace, purposeful motion, and tactile feedback make managing finances feel effortless.

---

## Color System

### Primary Palette
```
Primary Brand:    #FF6B6B (Coral Red) — Energy, action, warmth
Primary Dark:     #E85555
Primary Light:    #FF8585

Secondary:        #4ECDC4 (Teal) — Balance, trust, calm
Secondary Dark:   #3DBDB5
Accent:           #FFD93D (Gold) — Achievements, milestones
```

### Semantic Colors
```
Success:    #58D68D (Green)
Warning:    #F39C12 (Orange)
Danger:     #E74C3C (Red)
Info:       #3498DB (Blue)

Background Light: #F8F9FA
Surface Light:    #FFFFFF
Text Primary:     #2C3E50
Text Secondary:   #7F8C8D
Border Light:     #E9ECEF

Background Dark:  #1A1A2E
Surface Dark:     #16213E
Text Primary D:   #ECF0F1
Text Secondary D: #BDC3C7
Border Dark:      #2C3E50
```

### Category Colors
Each category has a distinct, accessible color:
- Food: #FF6B6B, Transport: #4ECDC4, Shopping: #45B7D1, Entertainment: #96CEB4
- Bills: #FFEAA7, Health: #DDA0DD, Travel: #98D8C8, Education: #F7DC6F
- Personal: #BB8FCE, Gifts: #85C1E9, Income: #58D68D

All colors meet WCAG AA contrast against both light and dark backgrounds.

---

## Typography

### Font Family
- **Primary**: Inter (Google Fonts) — Clean, excellent number rendering
- **Monospace**: SF Mono / Roboto Mono — For amounts, codes

### Type Scale
```
Display Large:   48sp / Bold    — Total balance, hero numbers
Display Medium:  36sp / Bold    — Section headers
Display Small:   24sp / SemiBold — Card titles
Headline Large:  20sp / SemiBold — Page titles
Headline Medium: 18sp / Medium   — List item titles
Headline Small:  16sp / Medium   — Form labels
Body Large:      16sp / Regular  — Primary body text
Body Medium:     14sp / Regular  — Secondary text, descriptions
Body Small:      12sp / Regular  — Captions, timestamps
Label:           11sp / Medium   — Badges, chips, tags
```

### Number Display
- Amounts: Tabular figures (`fontFeatures: [FontFeature.tabularFigures()]`)
- Currency symbol: Slightly smaller (80% size) than amount
- Decimal places: Always show 2 for standard currencies

---

## Spacing System

Base unit: 4dp
```
xs:   4dp
sm:   8dp
md:   16dp
lg:   24dp
xl:   32dp
xxl:  48dp
xxxl: 64dp
```

### Layout Grid
- Margins: 16dp (mobile), 24dp (tablet)
- Gutter: 16dp
- Max content width: 600dp (phones in landscape/tablets center content)

---

## Component Library

### Buttons

**Primary Button**
- Height: 56dp
- Border radius: 16dp
- Background: Primary color
- Text: White, 16sp SemiBold
- Press: Scale to 0.96, darken 10%
- Haptic: Light impact on press

**Secondary Button**
- Height: 48dp
- Border radius: 12dp
- Background: Surface with 1dp primary border
- Text: Primary color

**FAB (Floating Action Button)**
- Size: 64dp
- Shape: Circle
- Background: Primary
- Icon: Add (white), 24dp
- Shadow: Elevation 6
- Press: Scale 0.9, spring animation
- Haptic: Medium impact + subtle success on release

### Cards

**Expense Card**
- Background: Surface
- Border radius: 16dp
- Padding: 16dp
- Shadow: Elevation 1 (light), Elevation 2 (dark mode)
- Layout: [CategoryIcon 40dp] [16dp gap] [Title + Subtitle] [Spacer] [Amount]
- Amount color: Expense = Text Primary, Income = Success color
- Press: Scale 0.98, background tint

**Dashboard Card**
- Background: Surface with subtle gradient overlay
- Border radius: 20dp
- Padding: 20dp
- Shadow: Elevation 2

### Inputs

**Amount Keypad**
- Custom numeric keypad, not system keyboard
- Keys: 56dp touch targets
- Active key: Scale 0.9 + primary color ripple
- Haptic: Light impact per keypress, medium on operator
- Display: Large format, animates on digit entry (scale bounce)

**Text Fields**
- Border radius: 12dp
- Filled style: Background Surface variant
- Focus: Primary color border, subtle glow
- Error: Danger color with shake animation
- Haptic: Light impact on focus

### Progress Indicators

**Budget Ring**
- Size: 120dp (dashboard), 80dp (list)
- Stroke width: 12dp
- Background track: Surface variant at 30% opacity
- Progress: Category color
- Animation: Spring curve, 800ms duration
- Haptic: Subtle pulse when crossing 80%, stronger at 100%

**Linear Progress**
- Height: 8dp
- Border radius: 4dp
- Segments: Color-coded by spend level
  - 0-50%: Success
  - 50-80%: Primary
  - 80-100%: Warning
  - 100%+: Danger with pulsing animation

---

## Animations & Motion

### Timing
```
Quick:     150ms — Micro-interactions (button press, checkbox)
Standard:  300ms — UI transitions (page push, modal)
Emphasis:  500ms — Celebratory animations
Slow:      800ms — Complex transitions (charts, hero animations)
```

### Curves
```
Standard:     Curves.easeInOutCubic
Decelerate:   Curves.decelerate  — Content appearing
Accelerate:   Curves.easeInCubic  — Content leaving
Spring:       Spring(damping: 0.7, stiffness: 100) — Interactive elements
Bounce:       Curves.elasticOut   — Celebrations
```

### Key Animations

**Page Transitions**
- Push: Slide from right + fade in, 300ms, decelerate
- Pop: Slide to right + fade out, 250ms, accelerate
- Modal: Slide from bottom, 400ms, spring curve

**Hero Animations**
- FAB → Add Expense: FAB morphs into amount input field background
- Category icon → Category detail: Icon scales and translates to header
- Expense card → Expense detail: Card expands to fill screen

**Number Animations**
- Count-up on dashboard totals: 800ms, Curves.decelerate
- Amount entry: Scale 1.1 → 1.0 bounce per digit

**Success States**
- Expense saved: Brief confetti burst (3-5 particles), success haptic
- Budget milestone: Circular ripple from budget ring, achievement badge pops
- Streak maintained: Flame icon wobble animation

**Loading States**
- Skeleton screens: Shimmer gradient, never show spinner on first load
- Pull to refresh: Elastic overscroll + custom refresh indicator
- Sync: Subtle pulsing cloud icon in app bar

---

## Haptic Feedback System

Haptics are not optional decoration — they are essential feedback. Every action that changes state or confirms input produces tactile response.

### Haptic Mapping

| Interaction | Haptic | Intensity |
|-------------|--------|-----------|
| FAB press | Impact (medium) | Medium |
| Keypad digit | Impact (light) | Light |
| Keypad operator | Impact (medium) | Medium |
| Category select | Impact (light) | Light |
| Save expense | Notification (success) | Medium |
| Delete | Notification (warning) + selection | Medium |
| Budget 80% | Impact (medium) | Medium |
| Budget 100% | Notification (error) | Strong |
| Pull-to-sync | Impact (light) | Light |
| Error/Invalid | Notification (error) | Medium |
| Scroll snap | Impact (light) | Light |
| Switch toggle | Impact (light) | Light |
| Long press start | Impact (medium) | Medium |
| Achievement | Notification (success) + custom pattern | Strong |
| Biometric fail | Notification (error) | Strong |

### Platform Implementation
- iOS: `HapticFeedback` with specific generators (`lightImpact`, `mediumImpact`, `heavyImpact`, `selection`, `notification`)
- Android: `HapticFeedbackConstants` with fallback to vibration
- Respect system settings: If system haptics disabled, app haptics disabled

### Custom Patterns
- **Milestone**: Medium impact → 100ms pause → Light impact → 100ms → Success notification
- **Over Budget**: Heavy impact → 50ms → Heavy impact (double warning)

---

## Iconography

### Style
- Outlined icons for actions and navigation
- Filled icons for selected states and category icons
- Stroke width: 1.5dp
- Size: 24dp (standard), 20dp (dense), 32dp (featured)

### Icon Set
- Material Symbols (Flutter) with custom additions
- All icons tested at small sizes for clarity

---

## Gestures

### Core Gestures
- **Swipe left on expense**: Edit (reveals edit button with spring animation)
- **Swipe right on expense**: Delete (reveals delete button, red background)
- **Long press on expense**: Multi-select mode
- **Pull down on dashboard**: Sync + refresh
- **Pinch on chart**: Zoom time range
- **Double tap on total**: Toggle between show/hide amount (privacy)

### Gesture Feedback
- Every gesture trigger point has haptic confirmation
- Visual affordances: Background color reveals during swipe, scale on long press
- Reversible: Swipe back to cancel, release threshold for commit

---

## Accessibility

### Requirements
- All touch targets minimum 44x44pt
- Color not sole indicator of state (icons + text + pattern)
- Screen reader labels for all interactive elements
- Focus management: Logical tab order, trap focus in modals
- Reduce motion: Respect `MediaQuery.of(context).disableAnimations`
- High contrast: Test all colors against WCAG AA

### Screen Reader Patterns
- Expense card: "Dining, 45 dollars, Starbucks, Today at 3 PM"
- Budget ring: "Food budget, 65 percent used, 325 of 500 dollars"
- Chart: "Spending trend, highest point 120 dollars on March 15"

---

## Responsive Behavior

### Breakpoints
```
Compact:   <600dp  (phones portrait)
Medium:    600-840dp (phones landscape, small tablets)
Expanded:  >840dp   (tablets, foldables open)
```

### Adaptive Layouts
- **Compact**: Bottom navigation, single column, bottom sheets
- **Medium**: Navigation rail, 2-column dashboard, side sheets
- **Expanded**: Permanent navigation drawer, 3-column layout, persistent detail pane

### Tablet Optimizations
- Dashboard: Side-by-side stats cards
- Expense list: Master-detail with persistent detail pane
- Analytics: Larger charts with more data points visible
- Add expense: Side panel instead of full-screen modal

---

## Empty States

### Design Principles
- Illustration + Headline + Description + Action
- Tone: Encouraging, never apologetic
- Animation: Gentle floating/breathing on illustration

### Examples
- **No expenses**: Illustration of empty wallet + "Start tracking" + FAB highlighted
- **No budgets**: Illustration of target + "Set your first budget" + CTA button
- **No connection**: Illustration of cloud + "You're offline" + "Changes will sync when connected"
- **Search no results**: Illustration of magnifying glass + "No expenses found" + "Clear filters"

---

## Error States

### Patterns
- Inline validation: Field-level with shake animation
- Snackbar: Non-blocking errors with action (retry, dismiss)
- Full-screen: Critical errors with retry button
- Offline banner: Persistent but dismissible, slides from top

### Haptics
- All errors: Warning or error notification haptic
- Shake animation synced with haptic pulse
