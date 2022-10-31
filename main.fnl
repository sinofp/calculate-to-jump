; {{{ Global
(local font (love.graphics.newFont :assets/PublicPixel.woff 30))
(local screen-width (love.graphics.getWidth))
(local screen-height (love.graphics.getHeight))
(local right-icon (love.graphics.newImage :assets/tick_256.png))
(local wrong-icon (love.graphics.newImage :assets/cross_256.png))
(local tile-map
       (love.graphics.newImage :assets/monochrome_tilemap_transparent.png))

(local lume (require :lib.lume))
(local tick (require :lib.tick))
(local fun (require :lib.fun))
(local anim8 (require :lib.anim8))
(local bump (require :lib.bump))

(math.randomseed (os.time))
; }}}

; {{{ Intro
(local Intro (let [x (* 0.1 screen-width)]
               {: x
                :y screen-height
                :y-stop (* 0.4 screen-height)
                :w (- screen-width x)
                :text (.. "The world is falling.\n" "You need to JUMP to survive.
" "However, in order to jump,
"
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

; {{{ Queue
(local Queue {})

(fn Queue.new []
  (setmetatable {:first 1 :last 0} {:__index Queue}))

(fn Queue.push [self value]
  (set self.last (+ 1 self.last))
  (tset self self.last value))

(fn Queue.empty [self]
  (< self.last self.first))

(fn Queue.front [self]
  (when (self:empty)
    (error "Queue is empty"))
  (. self self.first))

(fn Queue.pop [self]
  (when (self:empty)
    (error "Queue is empty"))
  (tset self self.first nil)
  (set self.first (+ 1 self.first)))

; }}}

; {{{ Calc
(local Calc {:queue (Queue.new)
             :n 1
             :delay/s 1
             :start false
             :reveal false
             :reveal-time 0.5
             :reveal-content "? ? ? = ?"
             :correct true})

(fn Calc.gen-rand-int [max]
  (-> max
      lume.random
      lume.round))

(fn Calc.flip-coin []
  (< 0.5 (lume.random)))

(fn Calc.update-question []
  (let [a (Calc.gen-rand-int 9)
        b (Calc.gen-rand-int (- 9 a))
        [min mid max] (lume.sort [a b (+ a b)])
        [x y] (if (Calc.flip-coin) [min mid] [mid min])
        op (Calc.flip-coin)
        qa (if op {:q (.. x " + " y) :a max} {:q (.. max " - " x) :a y})]
    (Calc.queue:push qa)
    (set Calc.display qa.q)))

(for [i 0 Calc.n]
  (tick.delay (fn []
                (Calc.update-question)) (* i Calc.delay/s)))

(tick.delay (fn []
              (set Calc.start true)) (* Calc.n Calc.delay/s))

(fn Calc.update [dt]
  (tick.update dt))

(fn Calc.draw []
  (love.graphics.print Calc.display)
  (let [prev-n (Calc.queue:front)]
    (love.graphics.print (if Calc.reveal
                             Calc.reveal-content
                             "? ? ? = ?") 0 30))
  (when Calc.reveal
    (love.graphics.draw (if Calc.correct right-icon wrong-icon) 270 30 0 0.125
                        0.125)))

(fn Calc.keypressed [key _ repeat]
  (when (and Calc.start (not repeat))
    (let [prev-n (Calc.queue:front)
          num-string (key:gsub "%D" "")
          num (tonumber num-string)]
      (when (not= num nil)
        (set Calc.correct (= num prev-n.a))
        (set Calc.reveal-content (.. prev-n.q " = " num))
        (when Calc.reveal
          (Calc.reveal-clearer:stop))
        (set Calc.reveal true)
        (set Calc.reveal-clearer
             (tick.delay (fn []
                           (set Calc.reveal false))
                         Calc.reveal-time))
        (Calc.update-question)
        (Calc.queue:pop)))))

; }}}

; {{{ Character
(local Char {:x 100
             :y 300
             :v {:x 0 :y 0 :x-lim 500 :jump -300}
             :accel 1000
             :brake 1500
             :gravity 1000
             :width (* 16 4)
             :height (* 16 4)
             :ani {}
             :on-ground true
             :can-long-jump true})

(local g (anim8.newGrid 16 16 (tile-map:getWidth) (tile-map:getHeight) -1 -1 1))

(set Char.ani.idle (anim8.newAnimation (g 1 14 6 14) [0.4 0.2]))
(set Char.ani.now Char.ani.idle)
(set Char.ani.walk-right (anim8.newAnimation (g :2-4 14) 0.1))
(set Char.ani.walk-left (: (Char.ani.walk-right:clone) :flipH))
(set Char.ani.jump-right (anim8.newAnimation (g 5 14) 0.1))
(set Char.ani.jump-left (: (Char.ani.jump-right:clone) :flipH))

(fn Char.facing-left []
  (< Char.v.x 0))

(fn Char.update-velosity [dt]
  (if (love.keyboard.isDown :right)
      (set Char.v.x (math.min Char.v.x-lim
                              (+ Char.v.x
                                 (* dt
                                    (if (Char.facing-left) Char.brake
                                        Char.accel)))))
      (love.keyboard.isDown :left)
      (set Char.v.x (math.max (- Char.v.x-lim)
                              (- Char.v.x
                                 (* dt
                                    (if (Char.facing-left) Char.accel
                                        Char.brake)))))
      (let [v-brake (* dt Char.brake (if (< Char.v.x 0) 1 -1))]
        (set Char.v.x (if (< (math.abs Char.v.x) (math.abs v-brake)) 0
                          (+ Char.v.x v-brake)))))
  (when (and Char.can-long-jump (love.keyboard.isDown :up))
    (set Char.v.y Char.v.jump))
  (set Char.v.y (+ Char.v.y (* dt Char.gravity))))

; TODO Fix jumping from right but when = 0 Char.v.x
(fn Char.update-ani []
  (set Char.ani.now (if Char.on-ground
                        (if (= 0 Char.v.x) Char.ani.idle
                            (Char.facing-left) Char.ani.walk-left
                            Char.ani.walk-right)
                        (if (Char.facing-left) Char.ani.jump-left
                            Char.ani.jump-right))))

(fn Char.move [dt]
  (let [goal-x (+ Char.x (* Char.v.x dt))
        goal-y (+ Char.y (* Char.v.y dt))
        ground-y (- screen-height Char.height)
        real-y (math.min ground-y goal-y)]
    (set Char.on-ground (= real-y ground-y))
    (set Char.x goal-x)
    (set Char.y real-y)))

(fn Char.update [dt]
  (tick.update dt)
  (Char.ani.now:update dt)
  (Char.update-velosity dt)
  (Char.update-ani)
  (Char.move dt))

(fn Char.draw []
  (Char.ani.now:draw tile-map Char.x Char.y 0 4 4))

; TODO nearly on ground
(fn Char.keypressed [key]
  (when (and Char.on-ground (= key :up))
    (set Char.v.y Char.v.jump)
    (set Char.on-ground false)
    (set Char.can-long-jump true)
    (tick.delay (fn []
                  (set Char.can-long-jump false)) 0.3)))

; }}}

; {{{ Love
(var state Char)

(fn love.load []
  (love.graphics.setFont font))

(fn love.update [dt]
  (state.update dt))

(fn love.draw []
  (state.draw))

(fn love.keypressed [key]
  (if (= key :escape) (love.event.quit)
      (= key :r) (love.event.quit :restart))
  (state.keypressed key))

; }}}
