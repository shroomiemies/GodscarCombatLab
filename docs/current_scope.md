# Godscar Combat Lab — Updated Systems Scope and Implementation Roadmap

## Core Goal

The combat lab is not a vertical slice of the full game. It is an experimental testbed to answer one question:

**Can this combat system support grounded, dangerous, Outward-inspired melee while also leaving room for late-game Godscar-style system mastery involving mobility, anchors, weak points, wounds, terrain, and moving constructs?**

The lab should prove feel and function, not balance, progression, story, crafting, or final content.

---

# Current Implementation Status

Legend:

* ~~Completed~~ = implemented enough for the current lab stage
* **Partially complete** = foundation exists, but polish or major features remain
* **Deferred** = intentionally later

## Completed / Substantially Implemented So Far

* ~~Godot project setup~~
* ~~Git/version-control workflow~~
* ~~Core folder structure~~
* ~~Test arena~~
* ~~Player scene~~
* ~~Camera rig~~
* ~~Basic third-person movement~~
* ~~Camera-relative unlocked facing~~
* ~~Lock-on targeting~~
* ~~Target-relative facing~~
* ~~Lock-on camera yaw control~~
* ~~MovementFrame world-space stub~~
* ~~Mixamo placeholder character import~~
* ~~AnimationTree locomotion setup~~
* ~~Walk/jog/run blend setup~~
* ~~Jump / fall / landing movement-state foundation~~
* ~~Air acceleration fix: air control now limits velocity delta rather than bleeding horizontal speed~~
* ~~CombatController~~
* ~~AttackData resource~~
* ~~Startup / active / recovery phases~~
* ~~Movement lock strength~~
* ~~Local attack displacement~~
* ~~Locomotion velocity separated from attack motion velocity~~
* ~~Visible simple HitVolumeData debug meshes~~
* ~~Swept WeaponTraceData debug visualization~~
* ~~Swept convex trace hit detection~~
* ~~TrainingDummy Hurtbox~~
* ~~HitResult object~~
* ~~Hit once per actor per attack~~
* ~~Flexible weapon trace modes: horizontal arc, vertical arc, linear, thrust~~
* ~~Trace origin bias by weapon style / hand channel~~
* ~~Intent-based combo buffering~~
* ~~Basic sword combo chain~~
* ~~Neutral strong attack~~
* ~~Basic-to-strong branching~~
* ~~Hold-to-charge strong attack~~
* ~~Strong attack release timing during combo~~
* ~~WeaponStyleData~~
* ~~WeaponLoadoutController~~
* ~~Weapon style attack-set selection~~

## Important Current Limitations

* Attack animations are not yet properly connected to attack data.
* Hit pause is not implemented yet.
* Target reactions are not implemented yet.
* Stamina cost and recovery are not implemented yet.
* Stability damage and recovery are not implemented yet.
* Movement curves are still represented by simple local displacement, not full authored curves.
* Weapon style selection exists, but only sword is currently meaningful unless placeholder styles are added.
* Enemy behavior is still minimal.
* No real damage model exists yet.
* Injury/triage is not started.
* Push sprint and obstacle negotiation are not started.
* Local reference / moving platform behavior is only stubbed.

---

# Design Pillars

## 1. Weapon Style Determines Movement Identity

Weapons are not just damage/reach/speed profiles. Each weapon style should move the player differently during attacks.

Current weapon identities:

| Weapon Style | Combat Role                                                                      |
| ------------ | -------------------------------------------------------------------------------- |
| Sword        | Lateral combat, circling pressure, flow around quick enemies and large threats   |
| Axe          | Forward combat, stagger chase, punishing openings, sweeping through adds         |
| Mace         | Stationary/rooted combat, high impact, large/tough enemy punishment              |
| Spear        | Defensive spacing, probing strikes, distance management                          |
| Polearm      | Area combat, sweeping strikes, space denial                                      |
| Dagger       | Assassin combat, close-range execution, high-risk punish                         |
| Shield       | Warding combat, mobile barrier, protected advance, bashing openings              |
| Urumi/Whip   | Later maybe; committed in-and-out probing, delayed punishment, high anticipation |

The first lab should not implement every style immediately. It should prove the system using strong contrasts first.

Recommended first weapon order, updated:

1. Sword
2. Axe or Spear
3. Mace
4. Remaining of Axe/Spear
5. Polearm
6. Dagger
7. Shield
8. Urumi/Whip only if earlier systems are stable

Reason for the adjustment: sword is already the foundation, and axe/spear are the clearest next tests for the current movement model. Axe validates forward chase displacement. Spear validates thrust traces and spacing. Mace can follow once impact/stability systems exist.

---

## 2. Element Determines Magical Behavior and Scaling Bias

The elements should not be separate classes with bespoke systems. They should bias how shared systems behave.

Core elemental identities:

| Element   | Early/Mid Identity                                    | Late Mastery Axis              |
| --------- | ----------------------------------------------------- | ------------------------------ |
| Fire      | Reliable melee damage, simple AoE, charge damage      | Charge/output mastery          |
| Air       | Mobility, disengage, speed management                 | Velocity/precision mastery     |
| Water     | Recovery, stamina/pain support, dungeon endurance     | Recovery/flow/triage mastery   |
| Earth     | Battlefield control, reinforcement, small enemy binds | Anchor/leverage mastery        |
| Arcane    | Identification, clarity, reliability, system literacy | Precision/fundamentals mastery |
| Lightning | Maybe; interrupt/precision/volatility                 | Timing disruption              |
| Ice       | Maybe; control/brittle setup                          | Setup and locking              |

Short principle:

**Weapon style determines how the player moves through melee space. Element determines what the magic does when it gets there.**

---

## 3. Handles Replace Conventional Weapon Inventory

The player can carry:

* Two wands
* Two scepters
* One staff

Each can be used as a melee handle or modified into a spell-bound ranged attack.

The summoned weapon shape/element appears around these handles. This supports fast style swapping in the lab and later personalization in the full game.

Do not build full weapon customization in the lab. Use simple projection profiles and placeholder VFX.

Current implementation note:

The lab now uses **WeaponStyleData** as the test-facing selector for attack sets. This is not the final inventory/equipment system. It is a lightweight lab tool that lets the player select a style and automatically attach the correct default basic/strong attacks.

---

## 4. Player Skill Matters More Than Gear

Mechanical progression is not part of the combat lab, but systems should support future progression through:

* Better player knowledge
* Better use of weapon style
* Better charge timing
* Better triage
* Better terrain use
* Better anchor/velocity/weak-point exploitation
* Better artifact loadout decisions

Gear and artifacts should bias playstyle, not replace mastery.

---

# Major Lab Systems

## A. Core Melee Combat

Required systems:

* ~~Third-person movement~~
* ~~Lock-on / soft lock foundation~~
* ~~Target-relative movement/facing foundation~~
* ~~Attack state machine~~
* ~~Attack phases: startup, active, recovery~~
* ~~Basic attacks~~
* ~~Strong attacks~~
* ~~Basic → strong branch attacks~~
* ~~Intent-based input buffer~~
* ~~Hold/release strong attack charge foundation~~
* Stamina cost and recovery
* Weapon-style movement curves
* ~~Simple local attack displacement~~
* ~~Movement lock strength~~
* ~~Swept melee trace system~~
* ~~Simple hit volume system for bashes/AoE~~
* ~~Hurtbox hit detection~~
* Hit pause / animation freeze
* Target reactions
* Stability damage and recovery
* Debug hitbox/state display

Attack data should define:

* Animation name
* Duration
* Phase timings
* Movement lock
* Local displacement / future movement curve
* Rotation rules
* Simple hitbox definitions
* Swept weapon traces
* Contact profile
* Combo branches
* Strong-branch timing
* Charge rules
* Stamina/stability effects

Avoid root-motion dependency early. Use code/data-authored attack movement curves.

Current discrepancy from original roadmap:

The original roadmap referred broadly to “authored 3D hit volumes.” The current design is more specific and better:

* **HitVolumeData**: boxes/spheres/capsules for bashes, AoE, shield shove, explosions, and simple impact zones.
* **WeaponTraceData**: swept convex weapon traces for melee swings, thrusts, chops, uppercuts, and diagonal slashes.

This should remain the core melee hit detection model.

---

## B. Contact Feel: Impact, Penetration, Carry-Through

Keep this simple.

Initial communication tools:

* Animation freeze / hit pause
* Sound class
* Particles / VFX burst
* Target reaction family
* Optional camera shake

Do not simulate physical penetration.

Contact categories:

| Contact Type  | Readable Feel                                         |
| ------------- | ----------------------------------------------------- |
| Impact        | Stops, staggers, shakes, bursts outward               |
| Penetration   | Pierces, embeds, localized entry/exit effect          |
| Carry-through | Continues, slashes, delayed reaction, lingering trail |
| Deflect       | Skids, sparks, broken trail, rebound                  |
| Crush         | Heavy compression, dust, shockwave                    |

Velocity and platform motion may raise impact tiers, but should not become raw uncapped damage math.

Recommendation:

This should come soon after the first few weapon styles. Without hit pause and target reactions, weapon tuning will be misleading.

---

## C. Local Reference / Moving Platform Support

This must be accommodated early, but not fully implemented at first.

Core abstraction:

**MovementFrame**

Tracks:

* Origin
* Basis
* Up direction
* Linear velocity
* Angular velocity later
* Owning platform/body

Initial version can return world-space defaults.

Combat movement should be authored in local combat space, then resolved through the current movement frame.

Current status:

* ~~MovementFrame stub exists~~
* Moving platform support is not implemented yet.
* Current attack traces use global transforms and should be compatible with later local-reference work, but this must be validated once moving references exist.

Do not initially build full moving platform gameplay. Add later test scenes for:

1. Static arena
2. Translating platform
3. Velocity change platform
4. Slow rotating platform
5. Jump between platforms
6. Platform reference detach/reattach

---

## D. Sprint / Push Sprint

Universal mobility feature available to all players.

Basic design:

* Tap/press sprint gives safe sprint speed.
* Holding/pushing sprint increases speed slowly.
* Unsafe sprint increases stamina drain.
* Unsafe sprint builds instability.
* Releasing sprint smoothly decelerates back toward safe sprint speed.
* Instability first reduces steering/precision, then causes stumbles/falls only at high thresholds.

Recommended model:

* Safe sprint
* Push sprint
* Instability meter
* Stamina drain scaling
* Steering degradation
* Minor stumble
* Major stumble/fall only at high instability

This should be tested before vertical combat because it affects approach speed, recovery distance, attack setup, and how often the player collides with terrain.

---

## E. High-Speed Projectile-Body Movement

Used only for extreme states:

* High-speed magical launch
* Extreme pushed sprint failure/surge
* Long fall
* Ejection/knockback
* Possibly construct impacts

This is separate from normal grounded movement.

ProjectileBodyMode:

* Body may align to velocity.
* Floor is treated as another collision surface.
* Collision outcomes include slide, bounce, tumble, hard impact, anchor opportunity.
* Camera can become more unstable.
* Recovery returns player to upright NormalBodyMode.

Strong recommendation:

Use a separate projectile collision state or collision shape instead of tilting the normal movement capsule permanently.

Must include:

* Swept collision/casts
* Velocity-aligned collision/debug
* Recovery-to-upright fit check
* Last safe position
* Stuck/out-of-bounds recovery

---

## F. Obstacle Negotiation / Traversal Recovery

This should not be a standard RPG clamber system.

Desired principle:

**Movement intent first, recovery debt after.**

Examples:

* Walk into low obstacle → step up
* Sprint into table/ledge → vault/scramble/roll over
* Dodge into low obstacle → roll over if plausible
* Fall past ledge → tumble onto it if clearance exists
* High-speed collision → slide/bounce/tumble/anchor opportunity

Use direction-of-travel casting rather than only character-facing casts.

Avoid marking every climbable surface. Prefer procedural checks:

* Travel direction
* Collision point
* Collision normal
* Obstacle height/shape
* Clearance at destination
* Capsule fit
* Current movement state
* Speed
* Player intent

Allow “NoTraversal” exclusions later if necessary, but default should be permissive.

Traversal outcomes:

* Step up
* Vault
* Scramble
* Tumble over
* Slide
* Bounce
* Hard impact
* Anchor window
* Fall continue

Obstacle negotiation should happen before vertical combat support because it will determine how stairs, ramps, lips, ledges, and clutter feel during weapon movement.

---

## G. Anchor System

Anchoring fits the game strongly.

The player uses magically summoned blades to embed into stone, metal, construct plates, or terrain.

Anchor is not free climbing. It is a temporary state.

AnchorState:

* Attach to collision point
* Store attached surface/body
* Drain stamina/charge
* Limit duration
* Allow look/aim
* Allow jump-off
* Allow off-hand action later
* Eject if strain threshold exceeded

Anchor uses:

* Catching ledges/walls while falling
* Sticking to construct surfaces
* Recovering from high-speed movement
* Creating Earth bind points
* Briefly attacking from a dangerous position

This should be prototyped after core movement/combat and after obstacle recovery exists.

---

## H. Throwing Melee Weapons

Potentially implement earlier than originally planned because it bridges melee, ranged, anchors, and elemental scaling.

Thrown melee weapons should not just be damage projectiles.

Core model:

1. Outbound throw
2. Hit/lodge/embed
3. Remote focus window
4. Recall
5. Weapon unavailable until return

Throwing uses:

* Mid-range pressure
* Temporary remote focus
* Anchor placement
* Recall path effects
* Earth binds
* Water tethers/flow
* Weak-point pokes

Elemental throw bias:

| Element   | Throw Bias                                    |
| --------- | --------------------------------------------- |
| Fire      | Burst at impact, damaging recall trail        |
| Air       | Fast throw/recall, mobility extension         |
| Water     | Tether, flow, pull/push, recovery redirection |
| Earth     | Embed strongly, anchor, bind, claimed ground  |
| Arcane    | Reliable precision, weak-point poke           |
| Lightning | Maybe; interrupt/chain                        |
| Ice       | Maybe; slow/fracture                          |

Minimal prototype:

* Throw one weapon
* Stick to terrain/enemy
* Recall to hand
* Weapon unavailable while away
* Outbound hit
* Recall hit
* Earth landing bind/anchor
* Water recall wave/tether

---

## I. Earth Leverage / Binding

Earth’s late-game mastery axis:

**Earth mages create leverage by binding stable points, embedded weapons, terrain, and construct components.**

Earth should not casually overpower massive constructs. It should make massive things strain against themselves.

Earth mechanics:

* Reinforce damaged limbs
* Create battlefield control
* Bind small enemies with thrown weapons
* Create anchor points
* Bind anchor to terrain
* Bind anchor to anchor
* Pin / slow / torque / rupture

Earth bind outcomes:

| Action           | Effect                                                  |
| ---------------- | ------------------------------------------------------- |
| Pin              | Slow/hold target or component                           |
| Torque           | Twist component, crack armor, expose weak point         |
| Brace            | Reduce knockback, improve guard/stability               |
| Rupture          | Overload bind to crack armor or stagger                 |
| Counter-momentum | Punish charging/moving target by binding against motion |

Minimal lab test:

* Throw weapon into moving plate
* Place second anchor in ground
* Activate Earth bind
* Plate slows/strains
* Threshold causes crack/stagger/rupture

---

## J. Water Recovery / Flow

Water’s late-game mastery axis:

**Water keeps the party functional under pressure.**

Water should not be only “healing numbers.” It controls recovery, continuity, stamina, pain, and movement correction.

Water strengths:

* Soothe pain
* Slow bleeding
* Improve recovery processes
* Restore/boost stamina recovery
* Reduce recovery debt
* Help allies endure dungeon attrition
* Flow/tether movement correction later

Water difficulty:

* Requires coordination
* Requires good positioning
* Must triage before collapse
* Does not prevent instant-kill or severe construct mechanics
* Weaker burst payoff than Fire/Air/Earth

Minimal lab test:

* Pain/stamina/blood loss effects
* Water action reduces pain and improves recovery
* Ally/self triage view
* Position/range requirement later

---

## K. Injury / Recovery / Triage System

This should be included in the lab as a separate module.

Avoid individual wound records. Use per-body-part condition meters.

Body regions:

* Head
* Torso
* Left Arm
* Right Arm
* Left Leg
* Right Leg

Standard body-part values:

* BleedingRate: 0–999
* Structure: 100–0
* Pain: 0–99
* Bandaged: 0–999
* Reinforced: 0–100
* PainMasking: 0–99

Head may also track:

* Vision clarity
* Dizziness
* Focus disruption maybe later

Aggregates:

* Total Pain: 0–999
* Blood: 1000–0

Core rules:

* Pain affects stability and stability recovery.
* Extreme pain can cause collapse.
* Bleeding reduces stamina recovery.
* Severe bleeding causes stamina drain and unconsciousness risk.
* Blood cannot be restored directly.
* Blood recovers naturally over time/rest.
* Low blood is the closest thing to long-term health attrition.
* Structure damage affects limb function.
* Using damaged limbs builds pain.
* Bandaging suppresses bleeding symptoms.
* Reinforcement suppresses structure symptoms.
* Pain masking suppresses symptoms temporarily.
* Underlying causes remain unless truly repaired/rested.

Element healing roles:

| Element | Recovery Role                                                          |
| ------- | ---------------------------------------------------------------------- |
| Fire    | Cauterize bleeding quickly, converting bleeding into pain              |
| Earth   | Reinforce damaged structure; extreme repair possible at huge pain cost |
| Water   | Soothe pain, slow bleeding, improve recovery, reduce pain buildup      |
| Air     | Clear dizziness/sensory disruption, improve stamina recovery           |
| Arcane  | Mask pain, create temporary magical bandages, maybe faster splinting   |

Earth repair note:

* Earth reinforcement is combat viable.
* Earth true structure repair should be extreme, painful, likely unconsciousness-inducing, and not practical in combat.

---

## L. Triage UI

Normal HUD:

Show aggregate abstracted icons only:

* Blood loss
* Pain
* Stability danger
* Stamina recovery impaired
* Limb impaired
* Head/sensory impaired

Healing action on a target opens triage view.

Triage view:

* Paper doll body view
* Body-part status labels
* Abstracted severity, not raw numbers
* Available treatment actions per limb
* Cost preview
* Result preview
* Supplies/charge requirements

Example severity labels:

* None
* Minor
* Moderate
* Severe
* Critical

Example part readout:

* Right Leg: Structure compromised, reinforced weak, pain severe
* Torso: Bleeding heavy, bandaged fading
* Head: Dizzy severe, vision impaired

The medic role should be skill-based:

* Read triage screen quickly
* Prioritize urgent symptoms
* Use supplies efficiently
* Request emergency elemental healing from allies
* Decide what can wait until base/rest

Arcane or Water can fill medic roles naturally; Water is better for dedicated support-healer.

---

## M. Weak Points / Body Regions / Component Damage

This is critical for future constructs.

Do not use a single generic hurtbox.

Every test enemy should eventually support multiple hurt regions.

Humanoid regions:

* Head
* Torso
* Arms
* Legs

Construct test regions:

* Core
* Armor plate
* Left joint
* Right joint
* Weapon arm
* Sensor/head
* Exposed conduit

Component effects:

* Damage multiplier
* Stability multiplier
* Disable threshold
* Armor/break state
* Behavior modifier

Examples:

* Break leg joint → slower turning
* Break sensor → worse tracking
* Break weapon arm → disables attack
* Break armor plate → exposes core

This is needed for long-fight and mini-construct testing.

Current discrepancy:

The current Hurtbox implementation supports hit detection but not body-region identity yet. This should be upgraded before injury, stability, weak points, or construct testing.

---

## N. Charge System

Charge is not full progression, but should be tested.

Core rules:

* ~~Strong attacks can hold and carry charge fraction~~
* Player can accumulate magical charge.
* Charging creates vulnerability.
* Held charge drains stamina based on amount held.
* Skills consume charge.
* No charge means weapon-only combat.
* Charge can be built before combat.
* Mid-combat charge requires ally cover, terrain, distance, or skill.

Prototype one signature charge skill per element:

| Element | Prototype Skill                               |
| ------- | --------------------------------------------- |
| Fire    | Charged AoE or heavy damage strike            |
| Air     | Mobility launch/disengage                     |
| Water   | Pain/stamina recovery pulse                   |
| Earth   | Bind or reinforce                             |
| Arcane  | Weak-point reveal / pain mask / magic bandage |

Current recommendation:

The existing strong-attack charge should remain separate from the later full magical charge economy. It is an attack-local charge fraction. Later elemental systems can read that value, but should not assume it is the same as global spell charge.

---

## O. Artifacts

Do not implement full artifact system in the combat lab.

But design modifier hooks so later artifacts can alter:

* Charge capacity
* Charge stability
* Stamina drain
* Blood/pain recovery
* Anchor strain
* Sprint instability
* Weak-point clarity
* Element scaling
* Weapon style bias
* Throw/recall behavior
* Bind strength
* Water recovery radius

Future artifact placement concept:

* No fixed slots if possible
* Use body regions and simplified occupancy volumes
* Neutral-pose fit checks
* Avoid true mesh clipping detection
* Weight/resonance/interference can limit stacking

Lab should only use debug artifact modifiers if needed.

---

# Test Scenes / Modules

## 1. Core Melee Arena

Purpose:

* Prove basic weapon feel.

Contains:

* Flat arena
* Dummy
* Simple enemy
* Lock-on
* Sword first
* Later mace/spear/axe/polearm/dagger/shield

Success:

* Weapon styles feel different through movement, not just stats.

Current status:

* ~~Flat arena exists~~
* ~~Dummy exists~~
* ~~Lock-on exists~~
* ~~Sword attack framework exists~~
* Simple enemy does not exist yet.

---

## 2. Weapon Identity Arena

Purpose:

* Compare weapons against different enemy types.

Enemies:

* Slow heavy
* Fast circling
* Shielded/armored
* Group of weak adds
* Large tough weak-point enemy

Success:

* Each weapon has a reason to exist.

Recommendation:

Build this after at least sword, axe, spear, and mace have rough attacks. Do not tune weapon identity only against a stationary dummy.

---

## 3. Traversal Chaos Room

Purpose:

* Test obstacle negotiation and projectile-body movement.

Features:

* Low obstacles
* Tables
* Waist/chest ledges
* Shafts
* Protruding ledges
* Angled walls
* Moving platform lip
* Anchorable wall/plate

Tests:

* Dodge into obstacle
* Sprint into obstacle
* Push sprint into obstacle
* Fall past ledge
* Launch into wall
* Anchor catch
* Tumble over obstacle

Success:

* Movement failures become recoverable chaos, not hard stops or soft-locks.

Moved earlier in implementation order because push sprint and obstacle handling will heavily affect later vertical combat tests.

---

## 4. Vertical Combat Arena

Purpose:

* Test ramps, stairs, low/high targets, airborne targets.

Features:

* Ramps
* Stairs
* Platforms
* Elevated dummy
* Lower dummy
* Airborne target

Systems:

* Vertical angle bands
* Aim points
* Hitbox pitch limits
* High/low attack variants later

Success:

* Attacks do not fail awkwardly just because targets are above/below the player.

Current discrepancy:

Flexible trace modes now support vertical arcs, overhead swings, uppercuts, and thrusts earlier than this arena exists. That is good, but vertical target acquisition and aim-point selection are still missing.

---

## 5. Injury / Triage Lab

Purpose:

* Test wound values, blood, pain, healing, and UI.

Features:

* Damage buttons or test attacks
* Paper doll triage UI
* Treatment actions
* Supplies
* Elemental treatment actions
* Debug values

Success:

* Triage is readable, fast enough, and tactically interesting.

---

## 6. Charge / Element Lab

Purpose:

* Test elemental identity and charge economy.

Features:

* Charge accumulation
* Charge stamina drain
* Vulnerability while charging
* One skill per element
* Simple enemy pressure

Success:

* Charge feels powerful but risky.
* Elements feel biased without requiring separate subsystems.

---

## 7. Throw / Recall Lab

Purpose:

* Test thrown melee weapons as remote foci.

Features:

* Throw weapon
* Stick/embed
* Recall
* Outbound/return hits
* Earth anchor/bind test
* Water tether/recall wave test

Success:

* Throwing feels useful without replacing melee or ranged spells.

---

## 8. Moving Platform / Local Reference Lab

Purpose:

* Test MovementFrame and moving reference logic.

Features:

* Translating platform
* Slow rotating platform
* Jump between platforms
* Moving target/plate
* Detach/reattach logic

Success:

* Movement, attacks, anchors, and recovery behave acceptably on moving references.

---

## 9. Endurance Monster Test

Purpose:

* Recreate Dragon’s Dogma-style long fight pressure.

Features:

* Durable enemy
* Multiple weak regions
* Movement across arena
* Simple phase/state changes
* Attrition through wounds/stamina/blood
* Charge opportunities

Success:

* Long fight creates stories instead of repetitive dodge-attack loops.

---

## 10. Mini Construct Test

Purpose:

* Test second difficulty curve without building massive constructs.

Features:

* Large moving plate/arm
* Anchorable surface
* Component weak point
* Dangerous sweep
* Moving reference
* Earth bind/rupture
* Offhand attack from anchor maybe later
* Velocity impact opportunity

Success:

* Advanced system mastery feels possible: anchor, bind, strike weak point, jump away.

---

# Updated Recommended Implementation Order

## Phase 0 — Project Setup

Status: **Mostly complete**

* ~~Folder structure~~
* ~~Input map foundation~~
* ~~Test arena~~
* ~~Debug overlay~~
* ~~Basic character scene~~
* ~~Placeholder model/animations~~
* ~~Git/version control~~
* ~~Basic debug materials~~
* ~~Data resource scripts~~

Stop when:

* Project structure is stable and changes are easy to test/commit.

Remaining recommendation:

Add a lightweight debug overlay soon, but do not overbuild UI yet.

---

## Phase 1 — Basic Movement and Camera

Status: **Partially complete**

* ~~Third-person movement~~
* ~~Camera follow~~
* ~~Lock-on target~~
* ~~Safe sprint~~
* Basic dodge
* ~~MovementFrame stub returning world frame~~
* ~~Debug speed/state display~~
* ~~Air acceleration rather than air speed bleed~~
* ~~Jump/fall/landing state foundation~~

Stop when:

* Player moves cleanly and can lock onto dummy.

Remaining recommendation:

Before calling this phase fully complete, add safe sprint, basic dodge, and speed/state debug display.

---

## Phase 2 — Core Combat Skeleton

Status: **Partially complete, major foundation done**

* ~~Combat state machine~~
* ~~AttackData resource~~
* ~~One sword basic attack~~
* ~~Startup/active/recovery~~
* ~~Intent input buffer foundation~~
* ~~Attack movement displacement~~
* Full attack movement curve
* ~~Simple hitbox active window~~
* ~~Swept weapon trace active window~~
* ~~Dummy receives hit~~
* Hit pause
* Debug hitbox/state display
* Target reaction placeholder

Stop when:

* One attack feels controllable and debuggable.

Current discrepancy:

The original roadmap expected a single “hitbox” system. We now have simple hit volumes plus swept weapon traces. This is better and should remain.

---

## Phase 3 — Sword Combo Prototype

Status: **Partially complete, enough for attack-library prototyping**

* ~~Sword basic 1/2/3 foundation~~
* ~~Strong neutral~~
* ~~Basic 1 → strong~~
* ~~Basic 2 → strong~~
* ~~Basic 3 → strong~~
* ~~Intent-based branch buffering~~
* ~~Hold/release charged strong attack~~
* Stamina cost
* Stability damage
* Hit pause
* Target reactions
* Animation linkage
* Better attack movement curves

Stop when:

* Outward-style basic/strong branching works.

Current status:

The framework works well enough to start building a small attack library, but it is not ready for final feel evaluation until stamina, stability, hit pause, and target reactions exist.

---

## Phase 4 — Weapon Identity Expansion

Status: **Started**

Add in updated order:

1. ~~Sword framework~~
2. ~~Axe or Spear~~
3. ~~Mace~~
4. ~~Remaining of Axe/Spear~~
5. Polearm
6. Dagger
7. Shield

For each:

* Basic chain
* Strong branches
* Movement bias
* Swept trace shape
* Simple contact profile
* Simple VFX placeholder
* Style resource entry

Stop when:

* Sword, axe, spear, and mace feel meaningfully different.

Current recommendation:

Add one rough axe and one rough spear before returning too deeply to movement. Axe validates forward chase. Spear validates thrust spacing. Then movement polish will have better test cases.

---

## Phase 5 — Push Sprint and Instability

Moved up from original Phase 10.

Status: **Not started**

* Hold sprint to exceed safe sprint
* Stamina drain scaling
* Instability buildup
* Steering degradation
* Minor/major stumble
* Smooth release back to safe sprint
* Debug speed/instability readout

Stop when:

* Sprint risk/reward feels useful without random-feeling punishment.

Reason for moving earlier:

Push sprint will affect spacing, attack setup, obstacle collisions, and high-speed recovery. Vertical combat should not be tuned before sprint behavior is known.

---

## Phase 6 — Obstacle Negotiation

Moved up from original Phase 11.

Status: **Not started**

* Direction-of-travel casts
* Auto-step
* Dodge/sprint over low obstacles
* Vault/scramble/tumble outcomes
* Recovery debt
* Debug candidate outcomes

Stop when:

* Obstacles create interesting recoveries instead of hard stops.

Reason for moving earlier:

Obstacle behavior will affect stairs, ramps, ledges, vertical arenas, sprint failures, and later projectile-body movement.

---

## Phase 7 — Vertical Combat Support

Original Phase 5.

Status: **Foundation started through trace flexibility, but arena/system work not started**

* Aim points
* Vertical angle bands
* Attack pitch limits
* 3D hitbox tolerance
* High/low hitbox variants
* Later high/low animation variants only where needed

Stop when:

* Ramps/stairs/elevated targets do not break melee feel.

Current discrepancy:

Trace modes now support vertical/diagonal/thrust shapes, but target selection and vertical aim logic do not yet exist. Do not mistake trace flexibility for completed vertical combat.

---

## Phase 8 — Body Regions and Component Damage

Original Phase 6.

Status: **Not started**

* Multiple hurt regions
* Body-part hit results
* Construct dummy regions
* Region-specific damage/stability modifiers
* Simple disable behavior

Stop when:

* Targeting different regions changes the fight.

Recommendation:

Upgrade Hurtbox to carry region data before injury, weak points, or construct testing.

---

## Phase 9 — Injury Values and Aggregate Attrition

Original Phase 7.

Status: **Not started**

* Body-part condition meters
* Blood aggregate
* Pain aggregate
* Bleeding effects on stamina recovery
* Pain effects on stability recovery/collapse
* Structure effects on limb use
* Head dizziness/vision test

Stop when:

* Wounds affect combat and recovery without needing individual wound records.

Recommendation:

Do not start this before basic stamina/stability exists. Pain and bleeding need something meaningful to modify.

---

## Phase 10 — Triage UI and Healing Actions

Original Phase 8.

Status: **Not started**

* Paper doll triage view
* Severity labels
* Treatment preview
* Manual bandage
* Manual splint/reinforce
* Fire cauterize
* Earth reinforce
* Water soothe
* Air clear dizziness/stamina recovery pulse
* Arcane pain mask/magic bandage

Stop when:

* Triage is readable, fast, and creates meaningful choices.

Recommendation:

Build this after injury values exist, not before. Use debug buttons first, then a paper-doll view.

---

## Phase 11 — Charge and Element Signature Skills

Original Phase 9.

Status: **Attack-local strong charge started; full element charge not started**

* Charge accumulation
* Charge vulnerability
* Held-charge stamina drain
* Skill charge costs
* Fire charged damage/AoE
* Air mobility/disengage
* Water recovery pulse
* Earth bind/reinforce
* Arcane identification/weak-point reveal

Stop when:

* Each element has a distinct, testable playstyle bias.

Current discrepancy:

Strong attack charge exists now, but it is not the full element charge economy. Keep these concepts separate:

* Attack-local strong charge = held release timing and power scaling.
* Global magical charge = broader elemental skill resource.

---

## Phase 12 — Projectile-Body Movement

Original Phase 12.

Status: **Not started**

* Extreme speed threshold
* ProjectileBodyMode
* Velocity-aligned body/collision test
* Swept collision
* Collision outcomes: slide/bounce/tumble/hard impact
* Recovery-to-upright fit check
* Camera projectile mode
* Safety reset

Stop when:

* High-speed movement can be janky but not corrupting, crashing, or soft-locking.

Recommendation:

Do this after push sprint and obstacle negotiation, because those systems will create the first natural high-speed failure cases.

---

## Phase 13 — Anchor System

Original Phase 13.

Status: **Not started**

* Anchor opportunity detection
* Anchor attach
* Stamina/charge drain
* Ejection thresholds
* Jump-off
* Attach to static wall
* Attach to moving plate later

Stop when:

* Anchor catch and release feel useful and readable.

Recommendation:

Anchor should not begin until projectile-body movement or at least high-speed collision recovery exists.

---

## Phase 14 — Throw / Recall

Original Phase 14.

Status: **Not started**

* Throw melee weapon
* Stick/embed
* Recall
* Weapon unavailable while away
* Hit on outbound/return
* Earth anchor/bind use
* Water recall/tether use

Stop when:

* Throwing works as remote focus without replacing melee.

Recommendation:

This can move earlier if the melee loop stabilizes quickly, because it connects Earth, Water, anchor, weak points, and ranged pressure.

---

## Phase 15 — Moving Reference Tests

Original Phase 15.

Status: **MovementFrame stub only**

* Translating platform
* Slow rotating platform
* Platform velocity inheritance
* Detach/reattach
* Anchor on moving plate
* Attack on moving reference

Stop when:

* MovementFrame assumptions are validated enough for future game design.

Recommendation:

Run at least a simple translating-platform test before anchor/construct work becomes serious. Otherwise local-reference assumptions may rot unnoticed.

---

## Phase 16 — Endurance Monster and Mini Construct

Original Phase 16.

Status: **Not started**

* Long-fight enemy
* Multi-region damage
* Wound/triage pressure
* Charge windows
* Moving plate/arm construct test
* Earth bind/rupture
* Anchor weak-point attack
* High-speed impact opportunity

Stop when:

* The lab can produce both grounded survival fights and advanced system-mastery moments.

Recommendation:

Do not combine endurance monster and mini construct too early. First make one long grounded monster, then one simple moving-component construct.

---

# Clear Stopping Point for the Combat Lab

The combat lab is complete when it can answer these questions:

## Core Melee

* Do weapon styles feel different through movement and commitment?
* Does basic → strong branching feel good?
* Are hit traces readable and tunable?
* Does vertical disparity work acceptably?
* Does stamina/stability create pressure without feeling arbitrary?

## Element Identity

* Does Fire feel like output/charge?
* Does Air feel like velocity/mobility?
* Does Water feel like recovery/flow?
* Does Earth feel like leverage/control?
* Does Arcane feel like clarity/reliability?

## Injury and Recovery

* Do wounds create meaningful triage decisions?
* Does Blood work as long-term dungeon attrition?
* Is the triage screen readable under pressure?
* Can a medic role exist without forcing one element?
* Can solo players manage injuries through preparation?

## Advanced Systems

* Can high-speed movement be expressive without breaking the game state?
* Can obstacle recovery produce interesting outcomes?
* Can anchoring work as a temporary, risky, useful state?
* Can throwing weapons serve as remote foci?
* Can Earth bind/leverage and Water recovery/flow create late-game scaling?
* Can moving references be supported without a rewrite?

## Encounter Feel

* Can a long fight create memorable stories instead of repetition?
* Can weak points/components change enemy behavior?
* Can a mini-construct test support advanced, partially emergent solutions?

If the answers are mostly yes, the full game is viable enough to consider.

If the answers are no, the lab should reveal which systems to cut before committing to the full project.

---

# Do Not Build in the Combat Lab

Cut or defer:

* Full progression/crafting
* Full artifact placement system
* Final weapon customization
* Final VFX
* Final sound design
* Full enemy ecology
* Massive constructs
* Mobile base
* Network multiplayer
* LOD/vistas
* Open-world streaming
* Cloth physics
* True physics melee
* Full parkour
* Free climbing
* Full construct climbing
* Procedural dismemberment
* Full arbitrary voxel blade editor
* Full balance pass

---

# Additional Recommendations From Current Implementation Thread

## 1. Keep simple hit volumes and swept traces separate

Do not force every attack into WeaponTraceData.

Use:

* WeaponTraceData for swords, axes, spears, polearms, diagonal cuts, thrusts, uppercuts, overhead swings.
* HitVolumeData for shield bash, mace impact bursts, stomp, AoE, explosions, anchor shock, and magic pulses.

## 2. Build one rough axe and one rough spear before deep movement polish

Sword alone will not reveal enough movement problems.

Axe should test:

* forward displacement
* chase behavior
* strong attack pursuit

Spear should test:

* long narrow thrusts
* spacing
* backstep or retreating strong attacks

## 3. Add hit pause and target reactions before judging weapon feel

Right now the attack system can detect hits, but it cannot communicate impact.

Before serious tuning, add:

* short hit pause
* target flinch placeholder
* debug contact category
* simple hit sound placeholder if convenient

## 4. Add stamina before stability, and stability before injury

Recommended dependency:

1. Stamina
2. Stability
3. Pain/blood/limb structure
4. Triage

Stamina gives immediate combat pressure. Stability gives contact meaning. Injury then has values worth modifying.

## 5. Do not overbuild animations yet

The current attack data can carry animation names, but animation polish should wait until:

* weapon traces are stable
* movement bias is stable
* hit pause/reaction exists
* basic weapon identity is proven

Otherwise animation retargeting/polish may be wasted.

## 6. Treat strong attack charge as local, not global

The current strong charge system should stay as an attack-local mechanic:

* hold strong
* delay release
* increase charge fraction
* time movement/dodge

The later element charge system should be broader and should not be hard-coupled to this.

## 7. Keep WeaponStyleData as lab equipment, not final inventory

WeaponStyleData is currently doing the right job: selecting attack sets for testing.

Do not turn it into full equipment/customization yet. Later, handles, elements, artifacts, and projection profiles can feed into style selection.

## 8. Add debug displays before complex systems

Useful near-term debug display:

* movement state
* combat state
* current attack id
* attack time
* buffered input
* charge fraction
* current weapon style
* speed
* grounded/airborne
* lock-on target
* hit count this attack

This will pay off quickly as attacks and movement become more complex.

---

# Final Guiding Principle

The combat lab should prove this:

**A player begins by surviving grounded melee through spacing, stamina, wounds, and weapon identity. Later, the same player can master charge, velocity, anchors, weak points, triage, terrain, and moving references to create spectacular, system-driven solutions.**

If the lab can support both curves, it is pointing in the right direction.
