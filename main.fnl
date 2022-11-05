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

(local world (bump.newWorld))
(local map [[1 0 0 0 0 0 0 0 0 1]
            [1 0 0 0 0 0 0 0 0 1]
            [1 0 0 0 0 1 1 0 0 1]
            [1 0 0 1 0 0 0 1 0 1]
            [1 0 0 0 0 0 0 0 0 1]
            [1 0 0 0 0 0 0 0 1 1]
            [1 0 0 0 0 0 0 0 0 1]
            [1 0 0 0 0 0 1 1 1 1]
            [0 0 0 0 0 0 0 0 0 0]
            [1 1 1 1 1 1 1 1 1 1]])

(math.randomseed (os.time))

(macro += [a inc]
  `(set ,a (+ ,a ,inc)))

(fn axpy [y a x]
  (+ (* a x) y))

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
  (+= self.last 1)
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
  (+= self.first 1))

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
  (love.graphics.print Calc.display (* 64 11) (* 64 3))
  (let [prev-n (Calc.queue:front)]
    (love.graphics.print (if Calc.reveal
                             Calc.reveal-content
                             "? ? ? = ?") (* 64 11)
                         (* 64 4)))
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
             :decel 1800
             :gravity 2000
             :jump {:coyote 0 :passed 0 :coyote-lim 0.25 :passed-lim 0.5}
             :width (* 16 4)
             :height (* 16 4)
             :ani {}
             :on-ground true})

(local g (anim8.newGrid 16 16 (tile-map:getWidth) (tile-map:getHeight) -1 -1 1))

(local box-ani (anim8.newAnimation (g 6 6) 1))

(set Char.ani.idle (anim8.newAnimation (g 1 14 6 14) [0.4 0.2]))
(set Char.ani.now Char.ani.idle)
(set Char.ani.walk-right (anim8.newAnimation (g :2-4 14) 0.1))
(set Char.ani.walk-left (: (Char.ani.walk-right:clone) :flipH))
(set Char.ani.jump-right (anim8.newAnimation (g 5 14) 0.1))
(set Char.ani.jump-left (: (Char.ani.jump-right:clone) :flipH))

(world:add Char Char.x Char.y Char.width Char.height)

(each [i row (ipairs map)]
  (each [j tpe (ipairs row)]
    (when (= 1 tpe)
      (let [x (* 64 (- j 1))
            y (* 64 (- i 1))]
        (world:add {:name (.. "row " i " col " j)} x y 64 64)))))

(fn Char.facing-left []
  (< Char.v.x 0))

(fn Char.update-vx [dt]
  (if (love.keyboard.isDown :right)
      (let [acc (if (Char.facing-left) Char.decel Char.accel)
            vx (axpy Char.v.x dt acc)
            vx-capped (math.min Char.v.x-lim vx)]
        (set Char.v.x vx-capped))
      (love.keyboard.isDown :left)
      (let [acc (if (Char.facing-left) Char.accel Char.decel)
            vx (axpy Char.v.x (- dt) acc)
            vx-capped (math.max (- Char.v.x-lim) vx)]
        (set Char.v.x vx-capped))
      (let [v-decel (* dt Char.decel (if (Char.facing-left) 1 -1))
            stop (< (math.abs Char.v.x) (math.abs v-decel))]
        (if stop (set Char.v.x 0) (+= Char.v.x v-decel)))))

(fn Char.update-vy [dt]
  (when (and (< Char.jump.passed Char.jump.passed-lim)
             (love.keyboard.isDown :up))
    (set Char.v.y Char.v.jump))
  (+= Char.v.y (* dt Char.gravity)))

(fn Char.update-ani []
  (set Char.ani.past-jump
       (if (= Char.ani.idle Char.ani.now) Char.ani.jump-right Char.ani.now))
  (set Char.ani.now (if Char.on-ground
                        (if (= 0 Char.v.x) Char.ani.idle
                            (Char.facing-left) Char.ani.walk-left
                            Char.ani.walk-right)
                        (if (= 0 Char.v.x) Char.ani.past-jump
                            (Char.facing-left) Char.ani.jump-left
                            Char.ani.jump-right))))

(fn Char.move [dt]
  (let [goal-x (+ Char.x (* Char.v.x dt))
        goal-y (+ Char.y (* Char.v.y dt))
        (actual-x actual-y cols len) (world:move Char goal-x goal-y)]
    (set Char.x actual-x)
    (set Char.y actual-y)
    (set Char.on-ground false)
    (for [i 1 len]
      (let [normal (. cols i :normal)]
        (when (= 1 (math.abs normal.x))
          (set Char.v.x 0))
        (when (< normal.y 0)
          (set Char.jump.coyote 0)
          (set Char.v.y 0)
          (set Char.on-ground true))))))

(fn Char.update [dt]
  (+= Char.jump.coyote dt)
  (+= Char.jump.passed dt)
  (Char.ani.now:update dt)
  (Char.update-vx dt)
  (Char.update-vy dt)
  (Char.update-ani)
  (Char.move dt))

(fn Char.draw []
  (Char.ani.now:draw tile-map Char.x Char.y 0 4 4)
  (each [i row (ipairs map)]
    (each [j tpe (ipairs row)]
      (when (= 1 tpe)
        (let [x (* 64 (- j 1))
              y (* 64 (- i 1))]
          (box-ani:draw tile-map x y 0 4 4))))))

(fn Char.keypressed [key]
  (when (and (< Char.jump.coyote Char.jump.coyote-lim) (= key :up))
    (set Char.v.y Char.v.jump)
    (set Char.on-ground false)
    (set Char.jump.passed 0)))

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
