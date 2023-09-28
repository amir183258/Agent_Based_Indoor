extensions [
  py
]

globals [
  currentMovements ; Used in go and rule2

  ; Plot vairables
  cumulativeInternalInfected
  cumulativeExternalInfected
  cumulativeIndirectInfected
  totalInfected
]

patches-own [
  virusConcentration
]

; Agent Breeds
breed [people person]

people-own [
  P1
  P2
  P3

  Pfat

  Pmove
  Psmove

  Tinc
  Trec

  infectionStatus

  vaccinated
  asymptomatic
  reinfectionFlag

  currentIncubationTime
  currentRecoveryTime
]

; Initialize the model
to  setup
  clear-all
  clear-turtles
  clear-output
  clear-all-plots
  reset-ticks

  ; World size
  resize-world 0 facilityWidth 0 facilityHeight

  ask patches [
    set pcolor 3
  ]

  setup-agents

  ; Plot variables
  set cumulativeInternalInfected 0
  set cumulativeExternalInfected 0
  set cumulativeIndirectInfected 0
  set totalInfected 0

  ; I used python to visualize difference between actual data and
  ; simulation results for calibration purpose. You can ignore
  ; python sections. I commented them all.

  ; Python
  py:setup "/home/amir/Articles/article2/main/migrate to linux/env/bin/python"
  py:set "totalPopulation" populationSize
  py:run("simulationInfected = []")

  print("*** Setup Done ***")
end

to setup-agents
  ask patches [
    set virusConcentration initialConcentration
  ]

  create-people populationSize [
    set shape "circle"
    set color 8

    set xcor random-float facilityWidth
    set ycor random-float facilityHeight

    set P1 contagionProb1range1 + random-float (contagionProb1range2 - contagionProb1range1)
    set P2 contagionProb2range1 + random-float (contagionProb2range2 - contagionProb2range1)
    set P3 contagionProb3range1 + random-float (contagionProb3range2 - contagionProb3range1)

    set Pfat fatalityProbRange1 + random-float (fatalityProbRange2 - fatalityProbRange1)

    set Pmove movementProbRange1 + random-float (movementProbRange2 - movementProbRange1)
    set Psmove smallMovementProbRange1 + random-float (smallMovementProbRange2 - smallMovementProbRange1)

    set Tinc incubationTimeRange1 + (random (incubationTimeRange2 - incubationTimeRange1)) + 1
    set Trec recoveryTime
  ]

  ; Asymptomatic Agents
  ask n-of numberOfAsymptomaticAgents people [
    set asymptomatic 1
  ]

  ; Vaccinated Agents
  ask n-of numberOfVaccinatedAgents people [
    set vaccinated 1
    set label "V"
    set label-color yellow
  ]

  ; Initial infected agents
  ask n-of initialNumberOfInfectedAgents people [
    set infectionStatus 1
    set color red
  ]
end

; ********************************************* Run Section *********************************************
to go
  ; temp variables

  set currentMovements 0

  while [currentMovements < maxMovementsPerDay] [
    rule1
    rule2
    indirectTransmission
  ]
  indirectTransmissionRule
  rule3
  rule4
  rule5
  rule6

  ; Plot variables
  set totalInfected (cumulativeInternalInfected + cumulativeExternalInfected + cumulativeIndirectInfected)

  ; Python
  py:set "temp" totalInfected
  py:run("simulationInfected.append(temp)")

   tick
  if ticks >= simulationDays [
    stop
  ]

end

; ********************************************* Rule 1: Infection *********************************************
to rule1
  ; Infection rule
  ask people with [infectionStatus = 0] [
    ; Count number of near infected agents
    let infectedNeighbors 0
    ask people with [infectionStatus = 1 and distance myself < distanceOfContagion and who != [who] of myself] [
      set infectedNeighbors infectedNeighbors + 1
    ]

    ; Simulate contagion from near infected agents
    if infectedNeighbors > 0 [
      let Pcon P1

      if reinfectionFlag = 1 [
        set Pcon P2
      ]

      if vaccinated = 1 [
        set Pcon P3
      ]

      let i 0
      while [i < infectedNeighbors] [
        if random-float 1 < Pcon [
          set infectionStatus 1
          set currentIncubationTime 0
          set currentRecoveryTime 0

          set color red

          set i infectedNeighbors

          ; Plot variables
          set cumulativeInternalInfected cumulativeInternalInfected + 1

        ]

        set i i + 1
      ]
    ]
  ]
end

; ********************************************* Rule 2: Movement *********************************************
to rule2
  ; Movement rule
  ask people with [infectionStatus != -1] [
    if currentMovements < maxMovementsPerDay [
      if random-float 1 < Pmove [
        set currentMovements currentMovements + 1
        ifelse random-float 1 < Psmove [
          small-move
        ]
        [
          distant-move
        ]
      ]
    ]
  ]
end

to small-move
  let xSmallMovement (2 * (random-float 1) - 1) * maxRadiusLocalMovement
  let ySmallMovement (2 * (random-float 1) - 1) * maxRadiusLocalMovement

  ifelse xcor + xSmallMovement < 0 or xcor + xSmallMovement > facilityWidth [
    set xcor xcor - xSmallMovement
  ]
  [
    set xcor xcor + xSmallMovement
  ]

  ifelse ycor + ySmallMovement < 0 or ycor + ySmallMovement > facilityHeight [
    set ycor ycor - ySmallMovement
  ]
  [
    set ycor ycor + ySmallMovement
  ]
end

to distant-move
  set xcor facilityWidth * (random-float 1)
  set ycor facilityHeight * (random-float 1)
end

; ********************************************* Indirect Transmission Rule *********************************************
to indirectTransmissionRule
  ask people with [infectionStatus = 1] [
    ask patches with [distance myself < indirectTransmissionDistance] [
      let d distance myself
      set virusconcentration virusconcentration + secretionRate
    ]
  ]

  decay
end

to decay
  ask patches [
    ;set virusconcentration virusconcentration * ((1 - decayRate) ^ 6)

    set virusconcentration virusconcentration * decayRate

;    if ticks > 35 and virusConcentration > 1 [
;      set virusConcentration 0
;    ]


    ;if virusconcentration > 10 [
    ;  set virusconcentration 0
    ;]
  ]



end

; ********************************************* Indirect Transmission Probability *********************************************
to indirectTransmission
  ask people with [infectionStatus = 0] [
    let concentration [virusConcentration] of patch-here
    let transmissionProb random-float(1)

    if transmissionProb < indirectTransmissionParameter * concentration [
      set infectionStatus 1
      set currentIncubationTime 0
      set currentRecoveryTime 0

      set color orange

      ; Plot variables
      set cumulativeIndirectInfected cumulativeIndirectInfected + 1
    ]
  ]
end

; ********************************************* Rule 3: External infection *********************************************
to rule3
  ask people with [infectionStatus = 0] [
    if random-float 1 < externalInfectionParameter [
      let Pcon P1

      if reinfectionFlag = 1 [
        set Pcon P2
      ]

      if vaccinated = 1 [
        set Pcon P3
      ]

      if random-float 1 < Pcon [
        set infectionStatus 1
        set currentIncubationTime 0
        set currentRecoveryTime 0

        set color red - 2

        ; Plot variables
        set cumulativeExternalInfected cumulativeExternalInfected + 1
      ]
    ]
  ]
end

; ********************************************* Rule 4: Incubation time, symptom onset and quarantine *********************************************
to rule4
  ; Ask infected people
  ask people with [infectionStatus != 0] [
    ifelse currentIncubationTime < Tinc [
      set currentIncubationTime currentIncubationTime + 1
    ]
    [
      if currentRecoveryTime < Trec [
        set currentRecoveryTime currentRecoveryTime + 1
      ]
    ]
  ]

  ask people with [infectionStatus = 1] [
    if currentIncubationTime >= Tinc and asymptomatic = 0 [
      set infectionStatus -1
      set hidden? true
    ]
  ]
end

; ********************************************* Rule 5: Fatal cases *********************************************
to rule5
  ; Ask quarantined agents
  ask people with [infectionStatus = -1] [
    let PFatal Pfat

    if vaccinated = 1 [
      set PFatal PFatal * 0.1
    ]

    if random-float 1 < PFatal [
      die
    ]
  ]
end

; ********************************************* Rule 6: Recovery Process *********************************************
to rule6
  ask people with [infectionStatus != 0] [
    if currentRecoveryTime >= Trec [
      set currentIncubationTime 0
      set currentRecoveryTime 0

      set infectionStatus 0
      set hidden? false
      set color green
      set reinfectionFlag 1

    ]
  ]
end

; ********************************************* Environment Color *********************************************
to environmentColor
  ask patches with [virusconcentration > 0] [
    set pcolor scale-color yellow  virusconcentration (min [virusconcentration] of patches) (max [virusconcentration] of patches)
  ]

  ask patches with [virusconcentration = 0] [
    set pcolor 3
  ]
end

; ********************************************* Python Button *********************************************
to pythonTest
  (py:run
    "import matplotlib.pyplot as plt"
    "import numpy as np"
    "print('hi this is python')"

    "from python.plotData import plotData"
    "plotData('/home/amir/Articles/article2/main/migrate to linux/data/italy/calabria.csv')"
    "simulationInfected = np.array(simulationInfected, dtype=float)"
    "simulationInfected /= totalPopulation"
    "plt.plot(simulationInfected)"
    "plt.show()"
  )
end

@#$#@#$#@
GRAPHICS-WINDOW
1180
10
1743
574
-1
-1
15.0
1
8
1
1
1
0
0
0
1
0
36
0
36
0
0
1
Day
30.0

INPUTBOX
0
45
86
105
populationSize
200.0
1
0
Number

BUTTON
481
199
574
232
Setup
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

INPUTBOX
230
108
316
168
initialNumberOfInfectedAgents
0.0
1
0
Number

INPUTBOX
114
45
201
105
simulationDays
365.0
1
0
Number

INPUTBOX
114
108
201
168
maxMovementsPerDay
305.0
1
0
Number

INPUTBOX
114
171
200
231
maxRadiusLocalMovement
5.0
1
0
Number

INPUTBOX
230
45
316
105
distanceOfContagion
1.5
1
0
Number

INPUTBOX
0
108
86
168
facilityWidth
36.0
1
0
Number

INPUTBOX
0
171
86
231
facilityHeight
36.0
1
0
Number

INPUTBOX
230
171
317
231
numberOfVaccinatedAgents
0.0
1
0
Number

INPUTBOX
345
45
436
105
numberOfAsymptomaticAgents
100.0
1
0
Number

INPUTBOX
0
289
128
349
contagionProb1Range1
0.02
1
0
Number

INPUTBOX
0
354
128
414
contagionProb1Range2
0.03
1
0
Number

INPUTBOX
0
418
128
478
contagionProb2Range1
0.006
1
0
Number

INPUTBOX
0
482
128
542
contagionProb2Range2
0.0065
1
0
Number

INPUTBOX
0
547
129
607
contagionProb3Range1
0.0045
1
0
Number

INPUTBOX
158
289
289
349
contagionProb3Range2
0.005
1
0
Number

INPUTBOX
158
354
289
414
fatalityProbRange1
0.007
1
0
Number

INPUTBOX
158
418
289
478
fatalityProbRange2
0.07
1
0
Number

INPUTBOX
158
482
290
542
movementProbRange1
0.3
1
0
Number

INPUTBOX
158
546
291
606
movementProbRange2
0.5
1
0
Number

INPUTBOX
317
289
446
349
smallMovementProbRange1
0.7
1
0
Number

INPUTBOX
317
354
446
414
smallMovementProbRange2
0.9
1
0
Number

INPUTBOX
316
419
447
479
incubationTimeRange1
5.0
1
0
Number

INPUTBOX
316
482
447
542
incubationTimeRange2
6.0
1
0
Number

INPUTBOX
316
545
448
605
recoveryTime
14.0
1
0
Number

BUTTON
582
199
674
232
Run
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
0
10
197
50
• Simulation Parameters:
16
0.0
1

TEXTBOX
0
234
492
304
---------------------------------------------------------------------------------------------------------------------
11
0.0
1

TEXTBOX
468
10
483
248
|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n
11
0.0
1

TEXTBOX
0
249
150
269
• Agents Attributes
16
0.0
1

TEXTBOX
468
248
487
612
|\n|\n|\n|\n|
11
0.0
1

PLOT
698
10
1168
264
Accumulated Infected Population
NIL
NIL
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"Internal" 1.0 0 -2674135 true "" "plot cumulativeInternalInfected"
"External" 1.0 0 -8053223 true "" "plot cumulativeExternalInfected"
"Indirect" 1.0 0 -955883 true "" "plot cumulativeIndirectInfected"
"Total" 1.0 0 -1184463 true "" "plot totalInfected"

INPUTBOX
489
44
571
104
indirectTransmissionDistance
2.0
1
0
Number

INPUTBOX
490
109
572
169
secretionRate
0.008
1
0
Number

BUTTON
481
236
674
269
Environment Color
environmentColor
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
593
44
676
104
decayRate
0.25
1
0
Number

INPUTBOX
593
109
676
169
indirectTransmissionParameter
0.015
1
0
Number

TEXTBOX
488
10
693
50
• Indirect Transmission:
16
0.0
1

BUTTON
481
273
676
306
Calibration Plot
pythonTest
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
698
271
755
316
Internal
cumulativeInternalInfected
17
1
11

MONITOR
764
271
823
316
External
cumulativeExternalInfected
17
1
11

MONITOR
835
271
892
316
Indirect
cumulativeIndirectInfected
17
1
11

MONITOR
903
271
960
316
Total
totalInfected
17
1
11

INPUTBOX
344
108
435
168
externalInfectionParameter
0.015
1
0
Number

TEXTBOX
473
180
688
208
-----------------------------------------------------
11
0.0
1

TEXTBOX
468
192
483
234
|\n|\n|
11
0.0
1

TEXTBOX
685
10
835
178
|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|
11
0.0
1

TEXTBOX
686
196
701
322
|\n|\n|\n|\n|\n|\n|\n|\n|\n
11
0.0
1

TEXTBOX
471
319
689
347
-----------------------------------------------------
11
0.0
1

TEXTBOX
469
334
484
614
|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n
11
0.0
1

MONITOR
480
337
573
382
Vaccinated
count turtles with [vaccinated = 1]
17
1
11

MONITOR
587
388
681
433
Asymptomatic
count people with [asymptomatic = 1]
17
1
11

MONITOR
480
388
573
433
Reinfected
count people with [reinfectionflag = 1]
17
1
11

MONITOR
482
438
573
483
Infected
count people with [infectionstatus = 1]
17
1
11

MONITOR
587
337
680
382
Susceptible
count people with [infectionstatus = 0]
17
1
11

MONITOR
587
438
682
483
Quarantined
count people with [infectionStatus = -1]
17
1
11

MONITOR
483
490
574
535
Dead
populationSize - count turtles
17
1
11

MONITOR
588
490
682
535
Concentration Index
sum [virusConcentration] of patches / count patches
17
1
11

PLOT
698
324
1168
586
Population Status
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Infected" 1.0 0 -2674135 true "" "plot count people with [infectionStatus = 1]"
"Quarantined" 1.0 0 -5825686 true "" "plot count people with [infectionStatus = -1]"
"Dead" 1.0 0 -8732573 true "" "plot populationSize - count turtles"

MONITOR
483
541
575
586
Day
ticks
17
1
11

MONITOR
589
541
682
586
Alive
count people
17
1
11

INPUTBOX
344
172
434
232
initialConcentration
0.0
1
0
Number

MONITOR
966
271
1048
316
Max Concentration
max [virusConcentration] of patches
17
1
11

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
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>totalInfected</metric>
    <enumeratedValueSet variable="indirectTransmissionDistance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatalityProbRange1">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distanceOfContagion">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatalityProbRange2">
      <value value="0.07"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recoveryTime">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="facilityWidth">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxMovementsPerDay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="indirectTransmissionParameter">
      <value value="0.015"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulationDays">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movementProbRange1">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb2Range2">
      <value value="0.0065"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movementProbRange2">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="secretionRate">
      <value value="0.23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb3Range1">
      <value value="0.0045"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubationTimeRange1">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="populationSize">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb3Range2">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubationTimeRange2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialConcentration">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb1Range1">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decayRate">
      <value value="0.1732"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb1Range2">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smallMovementProbRange1">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="externalInfectionParameter">
      <value value="0.015"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smallMovementProbRange2">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb2Range1">
      <value value="0.006"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxRadiusLocalMovement">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="facilityHeight">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialNumberOfInfectedAgents">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfVaccinatedAgents">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfAsymptomaticAgents">
      <value value="80"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="New Experiment" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>totalInfected</metric>
    <enumeratedValueSet variable="indirectTransmissionDistance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatalityProbRange1">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distanceOfContagion">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatalityProbRange2">
      <value value="0.07"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recoveryTime">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="facilityWidth">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxMovementsPerDay">
      <value value="305"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="indirectTransmissionParameter">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulationDays">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movementProbRange1">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb2Range2">
      <value value="0.0065"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movementProbRange2">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="secretionRate">
      <value value="0.008"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="populationSize">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubationTimeRange1">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb3Range1">
      <value value="0.0045"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb3Range2">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb1Range1">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubationTimeRange2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decayRate">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialConcentration">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb1Range2">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smallMovementProbRange1">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="externalInfectionParameter">
      <value value="0.015"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smallMovementProbRange2">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb2Range1">
      <value value="0.006"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxRadiusLocalMovement">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="facilityHeight">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialNumberOfInfectedAgents">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfVaccinatedAgents">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfAsymptomaticAgents">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="New Experiment Discussion" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>cumulativeInternalInfected</metric>
    <metric>cumulativeExternalInfected</metric>
    <metric>cumulativeIndirectInfected</metric>
    <metric>count people with [infectionStatus = 1]</metric>
    <metric>count people with [infectionStatus = -1]</metric>
    <enumeratedValueSet variable="indirectTransmissionDistance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatalityProbRange1">
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distanceOfContagion">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatalityProbRange2">
      <value value="0.07"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recoveryTime">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="facilityWidth">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxMovementsPerDay">
      <value value="305"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="indirectTransmissionParameter">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulationDays">
      <value value="365"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movementProbRange1">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb2Range2">
      <value value="0.0065"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movementProbRange2">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="secretionRate">
      <value value="0.008"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="populationSize">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubationTimeRange1">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb3Range1">
      <value value="0.0045"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb3Range2">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb1Range1">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubationTimeRange2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decayRate">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialConcentration">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb1Range2">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smallMovementProbRange1">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="externalInfectionParameter">
      <value value="0.015"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smallMovementProbRange2">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagionProb2Range1">
      <value value="0.006"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxRadiusLocalMovement">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="facilityHeight">
      <value value="36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialNumberOfInfectedAgents">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfVaccinatedAgents">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfAsymptomaticAgents">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
