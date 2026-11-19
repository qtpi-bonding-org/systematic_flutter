# UI framework: what gp wants

The goals behind `docs/plans/2026-11-19-boundary-spike.md` and `2026-11-19-boundary-framework.md`. Plans change; these should not, unless gp changes them.

## Goals

1. **See all my UI in one place.** One page: widgets on top, screens below. Every state of every widget and screen is visible (loading, empty, error, full, dark, light), not one at a time.
2. **Change the look live.** Colours, fonts and sizes change from a panel on that page, and everything updates at once.
3. **Big changes through an agent, seen fast.** I tell the agent "make the tiles denser" and see it on the page through hot reload. No per-widget editor.
4. **Real code is the design.** The page shows the app's real widgets, not copies. No design file to keep in sync (the Figma/Paper problem).
5. **Widgets take fake data.** Every widget, and every screen, renders from plain data I can make up, with no backend, no fake repositories, no cubit wiring. The UI is fully decoupled from the data layer.
6. **A screen is a real type** (nice to have). A screen is a complete thing built from widgets. Routing can only go to a screen. Tooling tells screens from widgets by type, not by name or folder.
7. **No argument chains.** Data never passes through a widget on its way somewhere else. Each widget's arguments describe only itself.
8. **Enforced by structure, not habit.** Types and lints make the wrong way fail a check, so the design survives agents and time. A convention that relies on remembering is not enough.
9. **Solved once.** It lives in `systematic_flutter`, so every app (Episutra first) gets it and I never fight this again.
10. **Names say the role.** One name per kind of thing (`*Screen`, `*Adapter`, `*View`, primitives); a name never lies about what the class does.
11. **Only what changed redraws.** A change rebuilds only the widgets whose data changed, never a whole screen or region. Typing, scrolling, graph panning and streaming stay as fast as today, and this is checked by tests, not assumed.

## Not goals

- A visual drag-and-drop editor or per-widget property panels.
- Switching state library (Riverpod) or rewriting in Elm style. Cubits stay.
- Mobile, web or localisation work as part of this.

## Constraints

- Adopted gradually: the lint ratchet lets existing code migrate a piece at a time.
- Breaking changes are fine; apps pin refs and move when they choose.
- Tested on a small spike before it touches Episutra.

## How I will know it worked

I open one page, see every widget and screen of Episutra in all its states, change a colour and watch it everywhere, ask an agent for a change and see it land, and adding a new screen to that page costs me nothing but writing the screen.
