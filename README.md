# Bert and the Wheel of Worlds

- Trello: https://trello.com/b/hsYqw988/bert-and-the-wheel-of-worlds
- Kickoff deck: https://docs.google.com/presentation/d/1P9shXLOH1md1ml9tir9fROoDRZTsCGlZgTBWd0T4pBw/edit?usp=sharing
- Github: https://github.com/markguinn/wheel-of-worlds
- Playable build: https://markguinn.github.io/wheel-of-worlds/

## Contributing

Let's make something fun together! A few notes that might help:

- It's fine to just push to the main branch. No pull requests or code review needed.
- You don't have to stick to the Trello cards. Creativity is welcome.
- If you're working on a level or file that might be prone to git conflicts, it can be helpful to let folks knw in Discord and push your work often, even if you're not totally done.
- Posting screenshots or short videos of work-in-progress is a great way to generate excitement and also get early feedback.
- You can always check that the game is playable here: https://markguinn.github.io/wheel-of-worlds/ (it gets rebuilt every time a commit is pushed)
- If you've got `psd` or `apsrite` or other source files, checking them into the repo in the `_source_assets` folder is helpful if we need to make changes or variants down the line.
- We're using Godot 4.6.1. Using the same version will make things easier.
- Let's try to follow the [GDScript style guide](https://docs.godotengine.org/en/4.6/tutorials/scripting/gdscript/gdscript_styleguide.html)
- Set your editor to use tabs instead of spaces.

## Folder Structure

- `_references` - images and resources to help zero in on the style we're going for
- `_source_assets` - psd files, etc
- `_temp_replace_me_please` - put placeholder sounds, images, music, etc here if you want others to replace them with better assets in the future
- `actors` - these are scenes and scripts for the major characters of the game
- `common` - this is the spot for scripts or even scenes that might be reused in lots of different places (shared behaviors, etc)
- `globals` - these are the global singleton nodes defined in the project (`GameManager` etc)
- `props` - smaller nodes to flesh out the scenes. if something is unique to a stage, it can go there as well (e.g. a tree or a squirrel or something)
- `screens` - UI screens (title screen, etc)
- `stages` - these are the main worlds you travel through
