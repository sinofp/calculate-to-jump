# Calculate to jump!

The world is falling.
You need to JUMP to survive.
However, to jump, you need to CALCULATE first.

## Run the game from source

You must install [LÖVE](https://love2d.org/) to run this game.

After installation, change to the directory with the main.fnl file.
Then run `love .` to start the game.

## How to play

The right pane will show a question, you need to remember the answer.
When the next question shows up, you need to input the answer to the previous question (the answer is from 0 to 9).

If you input the correct answer, you can jump one more time.
Otherwise, you lose one opportunity to jump.

The level in the left pane is continuously falling, if the character falls below the screen, the game is over.

Use number keys to input the answer.
Use A, and D to move left and right.
Use W to jump.

## Credit

main.fnl, conf.lua and main.lua is licensed under the BSD 2-Clause "Simplified" License.
See LICENSE for details.

Files in the assets and lib folder are not my creation, see the following table for details.

| Name | License | Author |
| ---- | ------- | ------ |
| [Public Pixel Font](https://opengameart.org/content/public-pixel-font) | CC0 | GGBot |
| [1-Bit Platformer Pack](https://kenney-assets.itch.io/1-bit-platformer-pack) | CC0 | Kenney |
| [1-Bit 16px Iconset](https://1bityelta.itch.io/iconset) | Do what you want with it | Yelta |
| [SFX: The Ultimate 2017 8 Bit Mini Pack](https://opengameart.org/content/sfx-the-ultimate-2017-8-bit-mini-pack) | CC0 | phoenix1291 |
| [5 Chiptunes (Action)](https://opengameart.org/content/5-chiptunes-action) | CC0 | Juhani Junkala |
| [Fennel](https://github.com/bakpakin/Fennel) | MIT | Calvin Rose and contributors |
| [Anim8](https://github.com/kikito/anim8) | MIT | Enrique García Cota |
| [bump.lua](https://github.com/kikito/bump.lua) | MIT | Enrique García Cota |

The gaming mechanism is inspired by _NS-Shaft_ and _Dr Kawashima's Devilish Brain Training_.
