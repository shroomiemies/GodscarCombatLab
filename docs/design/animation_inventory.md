# Animation Inventory

## Player Placeholder: Mixamo Blue Male

Base model:
- File: res://art/characters/player_placeholder/mixamo_blue_male/model/...
- CharacterModel visual correction:
  - Position: 0, 0, 0
  - Rotation: 0, 180, 0
  - Scale: 0.9, 0.9, 0.9

Base model:
- File: res://art/characters/player_placeholder/mixamo_blue_male/model/Y Bot.fbx

Imported scene structure:
- Skeleton3D: CharacterModel/Skeleton3D
- Visual/skinned mesh nodes:
  - CharacterModel/Skeleton3D/Alpha_Surface
  - CharacterModel/Skeleton3D/Alpha_Surface/Alpha_Surface
  - CharacterModel/Skeleton3D/Alpha_Joints
  - CharacterModel/Skeleton3D/Alpha_Joints/Alpha_Joints
- AnimationPlayer:
  - CharacterModel/AnimationPlayer
- Animations:
  - Take 001
  - mixamo_com

Notes:
- The model does not import as one singular mesh node.
- Treat the visible body as a group of skinned visual nodes under Skeleton3D.
- Gameplay collision remains on Player/BodyCollision, not on the imported mesh.