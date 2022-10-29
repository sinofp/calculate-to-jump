; {{{ Global
(local font (love.graphics.newFont :assets/PublicPixel.woff 30))
(local screen-width (love.graphics.getWidth))
(local screen-height (love.graphics.getHeight))
(local right-icon (love.graphics.newImage :assets/checkmark.png))
(local wrong-icon (love.graphics.newImage :assets/cross.png))

(local lume (require :lib.lume))
(local tick (require :lib.tick))
(local fun (require :lib.fun))

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
    (love.graphics.draw (if Calc.correct right-icon wrong-icon) 270 30)))

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

; {{{ Love
(var state Calc)

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
