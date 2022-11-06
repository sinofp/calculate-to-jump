; {{{ Global
(local lume (require :lib.lume))
(local tick (require :lib.tick))
(local fun (require :lib.fun))
(local anim8 (require :lib.anim8))
(local bump (require :lib.bump))

(local font (love.graphics.newFont :assets/PublicPixel.woff 30))
(local screen-width (love.graphics.getWidth))
(local screen-height (love.graphics.getHeight))
(local right-icon (love.graphics.newImage :assets/tick_256.png))
(local wrong-icon (love.graphics.newImage :assets/cross_256.png))
(local tile-map
       (love.graphics.newImage :assets/monochrome_tilemap_transparent.png))

(local g (anim8.newGrid 16 16 (tile-map:getWidth) (tile-map:getHeight) -1 -1 1))

(local world (bump.newWorld))
(local map [[0 0 0 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 1 3]
            [0 0 4 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [0 0 0 0 1 2 3 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [1 3 0 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 4]
            [0 0 0 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [0 0 1 3 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 4 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [0 0 0 0 1 3 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [1 2 3 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]
            [0 0 0 0 0 0 0 0 0 0]])

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

; {{{ Status

(local Status {:jumps 3
               :score 0
               :start false
               :end false
               :start-time 0
               :end-time 0})

(fn Status.update []
  (when (and Status.end (= 0 Status.end-time))
    (set Status.end-time (love.timer.getTime))
    (let [duration (- Status.end-time Status.start-time)
          score (lume.round duration)]
      (set Status.score score))))

(fn Status.draw []
  (love.graphics.print (.. "Jumps: " Status.jumps) (* 64 11) (* 64 1)))

; }}}

; {{{ Calc
(local Calc {:queue (Queue.new)
             :n 1
             :delay/s 1
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
              (set Status.start true)
              (set Status.start-time (love.timer.getTime)))
            (* Calc.n Calc.delay/s))

(fn Calc.draw []
  (love.graphics.print Calc.display (* 64 11) (* 64 5))
  (let [prev-n (Calc.queue:front)]
    (love.graphics.print (if Calc.reveal
                             Calc.reveal-content
                             "? ? ? = ?") (* 64 11)
                         (* 64 6)))
  (when Calc.reveal
    (love.graphics.draw (if Calc.correct right-icon wrong-icon) (* 64 11)
                        (* 64 7))))

(fn Calc.keypressed [key]
  (when Status.start
    (let [prev-n (Calc.queue:front)
          num-string (key:gsub "%D" "")
          num (tonumber num-string)]
      (when (not= num nil)
        (set Calc.correct (= num prev-n.a))
        (+= Status.jumps (if Calc.correct 1 -1))
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
(local Char {:x (* 64 3)
             :y (* 64 5)
             :v {:x 0 :y 0 :x-lim 500 :jump -300}
             :accel 1000
             :decel 1800
             :gravity 2000
             :jump {:coyote 0 :passed 0 :coyote-lim 0.25 :passed-lim 0.5}
             :width (* 16 4)
             :height (* 16 4)
             :ani {}
             :on-ground true})

(set Char.ani.idle (anim8.newAnimation (g 1 14 6 14) [0.4 0.2]))
(set Char.ani.now Char.ani.idle)
(set Char.ani.walk-right (anim8.newAnimation (g :2-4 14) 0.1))
(set Char.ani.walk-left (: (Char.ani.walk-right:clone) :flipH))
(set Char.ani.jump-right (anim8.newAnimation (g 5 14) 0.1))
(set Char.ani.jump-left (: (Char.ani.jump-right:clone) :flipH))

(world:add Char Char.x Char.y Char.width Char.height)

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
    (when (< screen-height actual-y)
      (set Status.end true))
    (set Char.x actual-x)
    (set Char.y actual-y)
    (set Char.on-ground false)
    (for [i 1 len]
      (let [normal (. cols i :normal)]
        (when (not= 0 normal.x)
          (set Char.v.x 0))
        (when (< 0 normal.y)
          (set Char.v.y 0)
          (set Char.jump.coyote Char.jump.coyote-lim))
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
  (Char.ani.now:draw tile-map Char.x Char.y 0 4 4))

(fn Char.keypressed [key]
  (when (and (< 0 Status.jumps) (< Char.jump.coyote Char.jump.coyote-lim)
             (= key :up))
    (+= Status.jumps -1)
    (set Char.v.y Char.v.jump)
    (set Char.on-ground false)
    (set Char.jump.passed 0)))

; }}}

; {{{ Blocks
(local Block {:ani (anim8.newAnimation (g :11-14 10) 1)
              :tiles []
              :batch (love.graphics.newSpriteBatch tile-map)
              :indices {}
              :offset 0
              :down {:fire true :dis (* 6 1) :interval 1}})

(for [i 1 4]
  (let [frame (. Block.ani.frames i)
        (x y w h) (frame:getViewport)]
    (frame:setViewport x y w 6)
    (tset Block.tiles i frame)))

(each [i row (ipairs map)]
  (each [j block (ipairs row)]
    (when (not= 0 block)
      (let [x (* 16 4 (- j 1))
            y (* 6 4 (- i 1))
            id (.. i "-" j)]
        (Block.batch:add (. Block.tiles block) x y 0 4 4)
        (tset Block.indices id id)
        (world:add id x y 64 (* 4 6))))))

(world:add {:id :left-border} 0 0 1 screen-height)
(world:add {:id :right-border} 640 0 1 screen-height)

(tick.delay (fn []
              (set Block.down.fire true)) Block.down.interval)

(fn Block.update [dt]
  (when (and Status.start Block.down.fire)
    (set Block.down.fire false)
    (tick.delay (fn []
                  (set Block.down.fire true))
                Block.down.interval)
    (+= Block.offset Block.down.dis)
    (+= Char.y Block.down.dis)
    (world:update Char Char.x Char.y)
    (Block.batch:clear)
    (each [i row (ipairs map)]
      (each [j block (ipairs row)]
        (when (not= 0 block)
          (let [x (* 16 4 (- j 1))
                y (* 6 4 (- i 1))
                y-down (% (+ y Block.offset) screen-height)
                id (. Block.indices (.. i "-" j))]
            (Block.batch:add (. Block.tiles block) x y-down 0 4 4)
            (world:update id x y-down)))))))

(fn Block.draw []
  (love.graphics.draw Block.batch)
  (love.graphics.rectangle :fill 638 0 4 screen-height))

; }}}

; {{{ Love
(fn love.load []
  (love.graphics.setFont font))

(fn love.update [dt]
  (Status.update)
  (tick.update dt)
  (Block.update dt)
  (Char.update dt))

(fn love.draw []
  (if Status.end
      (love.graphics.printf (.. :Congratulation! "\n\n\n" "Your score is: "
                                Status.score "!" "\n\n\n"
                                "Press R to restart, or ESC to quit!")
                            (* 64 2) (* 64 3) (- screen-width (* 64 4)))
      (do
        (Status.draw)
        (Block.draw)
        (Calc.draw)
        (Char.draw))))

(fn love.keypressed [key]
  (if (= key :escape) (love.event.quit)
      (= key :r) (love.event.quit :restart))
  (Calc.keypressed key)
  (Char.keypressed key))

; }}}
