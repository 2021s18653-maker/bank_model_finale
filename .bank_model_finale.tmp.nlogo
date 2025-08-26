breed [employees employee]
breed [people person]

globals [
  ;num-employees
  employee-queues        ;; list of queues (each queue is a list of people)
  ;lambda                 ;; Poisson arrival rate
  people-left            ;; total people who left due to negative influence
  population-center-x
  population-center-y
  population-radius
  num-positively-influenced
  num-negatively-influenced
  num-people-served
  people-left-over-time tick-counts
]

employees-own [
  efficiency
  stress
  serving?
  service-timer
]

people-own [
  patience-threshold
  wait-time
  satisfaction
  being-served?
  arrival-delay
  ready-to-join?
  service-duration
  queue-index
  target-employee
  moving-to-queue?
  position-in-queue
]

;; ------------------------------------
;; SETUP
;; ------------------------------------
to setup
  clear-all

  set people-left 0
  set population-center-x max-pxcor - 5
  set population-center-y min-pycor + 5
  set population-radius 5
  set num-positively-influenced 0
  set num-negatively-influenced 0
  set num-people-served 0


  ;; Create employees
  create-employees num-employees [
    set shape "square"
    set color orange
    set size 2
    set stress 0
    set serving? false
    set service-timer 0
  ]

  ;; Position employees evenly
  let employee-y max-pycor - 3
  let space-left 1
  let space-right 1
  let lane-spacing 5
  let total-span (num-employees - 1) * lane-spacing
  let start-x (min-pxcor + space-left) + ((world-width - space-left - space-right - total-span) / 2)

  (foreach sort employees (range num-employees) [ [emp idx] ->
    ask emp [ setxy (start-x + lane-spacing * idx) employee-y
              set color orange
              set label (idx + 1)   ;; label each counter
              set label-color white
    ]
  ])

  ;; Create people in population area
  create-people 100 [
    move-to-population self
    set shape "person"
    set patience-threshold random 50 + 50
    set wait-time 0
    set satisfaction 100
    set being-served? false
    set arrival-delay poisson-wait-time
    set ready-to-join? false
    set moving-to-queue? false
    set queue-index -1
    set service-duration 0
    set position-in-queue -1
  ]

  set employee-queues n-values num-employees [ [] ]
  reset-ticks
end

;; ------------------------------------
;; Helper: Move to population area
;; ------------------------------------
to move-to-population [c]
  let r population-radius * sqrt random-float 1
  let angle random-float 360
  let offset-x r * cos angle
  let offset-y r * sin angle
  ask c [
    setxy population-center-x + offset-x population-center-y + offset-y
    set color white
    set ready-to-join? false
    set moving-to-queue? false
    set queue-index -1
    set being-served? false
    set position-in-queue -1
  ]
end

;; ------------------------------------
;; POISSON WAIT TIME
;; ------------------------------------
to-report poisson-wait-time
  let L exp (-(lambda))
  let k 0
  let p 1.0
  while [p > L] [
    set k k + 1
    set p p * random-float 1
  ]
  report max list 1 (k - 1)
end

;; ------------------------------------
;; ARRIVAL HANDLER
;; ------------------------------------
to handle-arrivals
  ask people with [not ready-to-join? and not being-served? and not moving-to-queue?] [
    set arrival-delay arrival-delay - 1
    if arrival-delay <= 0 [
      set ready-to-join? true
    ]
  ]
end

;; ------------------------------------
;; ASSIGN TO QUEUE
;; ------------------------------------
to assign-to-queue
  let next-person one-of people with [ready-to-join? and not being-served? and not moving-to-queue?]
  if next-person != nobody [
    ;; Find the shortest queue
    let shortest-queue-index 0
    let shortest-length length item 0 employee-queues
    foreach range num-employees [ i ->
      let q-length length item i employee-queues
      if q-length < shortest-length [
        set shortest-length q-length
        set shortest-queue-index i
      ]
    ]

    ;; Add to shortest queue if it has less than 6 people
    if shortest-length < 6 [
      let queue item shortest-queue-index employee-queues
      set queue lput next-person queue
      set employee-queues replace-item shortest-queue-index employee-queues queue
      ask next-person [
        set queue-index shortest-queue-index
        set target-employee item shortest-queue-index sort employees
        set moving-to-queue? true
        set ready-to-join? false
        set color yellow
        set position-in-queue shortest-length
      ]
    ]
  ]
end

;; ------------------------------------
;; MOVE TO QUEUE
;; ------------------------------------
to move-to-queue
  ask people with [moving-to-queue? and queue-index >= 0] [
    let spacing 2
    let q item queue-index employee-queues
    let employee-x [xcor] of target-employee
    let employee-y [ycor] of target-employee
    let desired-x employee-x
    let desired-y employee-y - ((position-in-queue + 1) * spacing)
    move-to patch desired-x desired-y
    set moving-to-queue? false

    if position-in-queue = 0 [
      set being-served? true
      set service-duration random 10 + 5
      set color blue
    ]
  ]
end

;; ------------------------------------
;; SERVE CUSTOMERS
;; ------------------------------------
to serve-customers
  foreach range num-employees [ i ->
    let queue item i employee-queues
    if length queue > 0 [
      let first-person first queue
      if is-turtle? first-person and member? first-person people [
        ask first-person [
          if being-served? and service-duration <= 0 [
            perform-influence self
            set num-people-served num-people-served + 1
            move-to-population self
            set being-served? false
            set arrival-delay poisson-wait-time
            set ready-to-join? false
            set queue-index -1
            set service-duration 0
            set position-in-queue -1

            ;; Remove served person from queue
            set queue but-first queue
            set employee-queues replace-item i employee-queues queue

            ;; Move everyone forward in queue
            let new-queue []
            let pos 0
            foreach queue [ p ->
              if is-turtle? p and member? p people [
                ask p [
                  set queue-index i
                  set position-in-queue pos
                  let employee-x [xcor] of target-employee
                  let employee-y [ycor] of target-employee
                  let desired-x employee-x
                  let desired-y employee-y - ((pos + 1) * 2)
                  move-to patch desired-x desired-y
                  ifelse pos = 0 [
                    set being-served? true
                    set service-duration random 10 + 5
                    set color blue
                  ] [
                    set color yellow
                    set being-served? false
                  ]
                ]
                set new-queue lput p new-queue
                set pos pos + 1
              ]
            ]
            set employee-queues replace-item i employee-queues new-queue
          ]
          if being-served? [
            set service-duration service-duration - 1
          ]
        ]
      ]
    ]
  ]
end

;; ------------------------------------
;; PERFORM INFLUENCE
;; ------------------------------------
to perform-influence [p]
  let influence-type one-of ["positive" "negative"]
  let others other people with [not being-served? and not moving-to-queue?]
  if any? others [
    let target one-of others
    if influence-type = "negative" [
      ask p [ set color red ]
      ask target [
    set color red
    set ready-to-join? false
    set moving-to-queue? false
    set being-served? false
    set queue-index -1
  ]
      set people-left people-left + 1
      set num-negatively-influenced num-negatively-influenced + 1
    ]
    if influence-type = "positive" [
      ask p [ set color green ]
      ask target [
        set color green
        set ready-to-join? true
        set arrival-delay 0
      ]
      set num-positively-influenced num-positively-influenced + 1
    ]
  ]
end

;; ------------------------------------
;; UPDATE SATISFACTION & EFFICIENCY
;; ------------------------------------
to update-satisfaction-and-efficiency
  ;; People lose satisfaction while waiting
  ask people with [not being-served? and queue-index >= 0] [
    set satisfaction satisfaction - 0.2
    if satisfaction < 0 [ set satisfaction 0 ]
  ]

  ;; People gain satisfaction if served positively
  ask people with [being-served?] [
    set satisfaction satisfaction + 0.5
    if satisfaction > 100 [ set satisfaction 100 ]
  ]

  ;; Employee efficiency depends on stress
  ask employees [
    ifelse serving? [
      set stress stress + 0.2
    ] [
      set stress stress - 0.1
    ]

    if stress < 0 [ set stress 0 ]
    if stress > 100 [ set stress 100 ]

    ;; Efficiency = 100 - stress
    set efficiency 100 - stress
  ]
end


;; ------------------------------------
;; MAIN LOOP
;; ------------------------------------
to go
  handle-arrivals
  assign-to-queue
  move-to-queue
  serve-customers
  tick
  set people-left-over-time []  ;; initialize as empty list
  set tick-counts []             ;; similarly initialize tick-counts if needed


  ;; then your commands
  set people-left-over-time lput people-left people-left-over-time
  set tick-counts lput ticks tick-counts

  ;; Plot 1: People Left
  set-current-plot "People Left"
  plotxy ticks people-left

  ;; Plot 2: Average Satisfaction
  set-current-plot "Average Satisfaction"
  plotxy ticks mean [satisfaction] of people

  ;; Plot 3: Average Efficiency
  set-current-plot "Average Efficiency"
  plotxy ticks mean [efficiency] of employees

  update-plots
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
55
77
118
110
go
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
50
138
113
171
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
33
205
205
238
num-employees
num-employees
0
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
29
249
201
282
lambda
lambda
0
100
2.0
5
1
NIL
HORIZONTAL

MONITOR
6
309
85
354
People_Left
people-left
17
1
11

MONITOR
106
311
203
356
People_Served
num-people-served
17
1
11

MONITOR
4
363
69
408
Positively
num-positively-influenced
17
1
11

MONITOR
107
364
178
409
Negatively
num-negatively-influenced
17
1
11

PLOT
750
27
950
177
People Left
time
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

PLOT
758
239
958
389
Average Satisfaction
time
satisfaction
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

PLOT
1045
39
1245
189
Average Efficiency
time
efficiency
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
