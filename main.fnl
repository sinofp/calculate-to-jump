; {{{ Global
(local font (love.graphics.newFont "assets/PublicPixel.woff" 30))
(local screen-width (love.graphics.getWidth))
(local screen-height (love.graphics.getHeight))
; }}}

; {{{ Intro
(local Intro
  (let [x (* 0.1 screen-width)]
    {: x
     :y screen-height
     :y-stop (* 0.4 screen-height)
     :w (- screen-width x)
     :text (.. "The world is falling.\n"
               "You need to JUMP to survive.\n"
               "However, in order to jump,\n"
               "you need to CALCULATE first.")
     :speed 50}))

(fn Intro.update [dt]
  (when (< Intro.y-stop Intro.y)
    (let [dist (* Intro.speed dt)
          newY (- Intro.y dist)]
      (set Intro.y newY))))

(fn Intro.draw []
  (love.graphics.printf Intro.text Intro.x Intro.y Intro.w))
; }}}

; {{{ Love
(fn love.load []
  (love.graphics.setFont font))

(fn love.update [dt]
  (Intro.update dt))

(fn love.draw []
  (Intro.draw))

(fn love.keypressed [key]
  (love.event.quit))
; }}}
