   ;***************************************************************
   ;
   ;  Pulsating Color Cycling Example
   ;
   ;  Example program by Duane Alan Hahn (Random Terrain) using
   ;  hints, tips, code snippets, and more from AtariAge members
   ;  such as batari, SeaGtGruff, RevEng, Robert M, Nukey Shay,
   ;  Atarius Maximus, jrok, supercat, GroovyBee, and bogax.
   ;
   ;
   ;```````````````````````````````````````````````````````````````
   ;
   ;  If this program will not compile for you, get the latest
   ;  version of batari Basic:
   ;  
   ;  http://www.randomterrain.com/atari-2600-memories-batari-basic-commands.html#gettingstarted
   ;  
   ;***************************************************************



   ;***************************************************************
   ;
   ;  Variable aliases go here (DIMs).
   ;
   ;  You can have more than one alias for each variable.
   ;  If you use different aliases for bit operations,
   ;  it's easier to understand and remember what they do.
   ;
   ;  I start variable aliases with one underscore so I won't
   ;  have to worry that I might be using bB keywords by mistake.
   ;  I also start labels with two underscores for the same
   ;  reason. The second underscore also makes labels stand out 
   ;  so I can tell at a glance that they are labels and not
   ;  variables.
   ;
   ;  Use bit operations any time you need a simple off/on
   ;  variable. One variable essentially becomes 8 smaller
   ;  variables when you use bit operations.
   ;
   ;  I start my bit aliases with "_Bit" then follow that
   ;  with the bit number from 0 to 7, then another underscore
   ;  and the name. Example: _Bit0_Reset_Restrainer 
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Player0 color.
   ;
   dim _P0_Luminosity = a.b

   ;```````````````````````````````````````````````````````````````
   ;  Highest brightness.
   ;
   dim _Hue_Brightness_High = c

   ;```````````````````````````````````````````````````````````````
   ;  Lowest brightness.
   ;
   dim _Hue_Brightness_Low = d

   ;```````````````````````````````````````````````````````````````
   ;  Tiny little itty-bitty bit variables.
   ;
   dim _Bit0_Reset_Restrainer = y
   dim _Bit6_Sequence_Switch = y





   ;***************************************************************
   ;***************************************************************
   ;
   ;  PROGRAM START/RESTART
   ;
   ;
__Start_Restart


   ;***************************************************************
   ;
   ;  Mutes volume of both sound channels.
   ;
   AUDV0 = 0 : AUDV1 = 0


   ;***************************************************************
   ;
   ;  Clears all normal variables.
   ;
   a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
   j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
   s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0


   ;***************************************************************
   ;
   ;  Sets background color.
   ;
   COLUBK = 0


   ;***************************************************************
   ;
   ;  Sets score color.
   ;
   scorecolor = $00


   ;***************************************************************
   ;
   ;  Defines the highest brightness.
   ;
   _Hue_Brightness_High = $0C


   ;***************************************************************
   ;
   ;  Defines the lowest brightness.
   ;
   _Hue_Brightness_Low = $04


   ;***************************************************************
   ;
   ;  Sets the luminosity variable.
   ;
   _P0_Luminosity = $02


   ;***************************************************************
   ;
   ;  Sets starting position of player0.
   ;
   player0x = 66 : player0y = 65


   ;***************************************************************
   ;
   ;  Restrains the reset switch for the main loop.
   ;
   ;  This bit fixes it so the reset switch becomes inactive if
   ;  it hasn't been released after being pressed once.
   ;
   _Bit0_Reset_Restrainer{0} = 1


   ;***************************************************************
   ;
   ;  Defines shape of Player0 sprite.
   ;
   player0:
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
end





   ;***************************************************************
   ;***************************************************************
   ;
   ;  MAIN LOOP (MAKES THE PROGRAM GO)
   ;
   ;
__Main_Loop



   ;***************************************************************
   ;
   ;  Color cycling.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Brightness increase section. (When switch bit is off.)
   ;  Skips to brightness decrease section if switch bit is on.
   ;
   if _Bit6_Sequence_Switch{6} then goto __Switch_Bit_On

   ;```````````````````````````````````````````````````````````````
   ;  Increases the player0 luminosity variable.
   ;
   _P0_Luminosity = _P0_Luminosity + 0.22

   ;```````````````````````````````````````````````````````````````
   ;  The switch bit is turned on and the hue is changed for the
   ;  next loop around if luminosity variable reaches highest
   ;  defined brightness.
   ;
   if _P0_Luminosity >= _Hue_Brightness_High then _Bit6_Sequence_Switch{6} = 1 : _Hue_Brightness_High = _Hue_Brightness_High + $10
   
   goto __Skip_Hue_Change

   ;```````````````````````````````````````````````````````````````
   ;  Brightness decrease section. (When switch bit is on.)
   ;
__Switch_Bit_On

   ;```````````````````````````````````````````````````````````````
   ;  Decreases the luminosity variable.
   ;
    _P0_Luminosity = _P0_Luminosity - 0.22

   ;```````````````````````````````````````````````````````````````
   ;  The switch bit is turned off, the hue is changed, and the
   ;  luminosity variable is updated if luminosity variable
   ;  reaches lowest defined brightness.
   ;
   if _P0_Luminosity <= _Hue_Brightness_Low then _Bit6_Sequence_Switch{6} = 0 : _Hue_Brightness_Low = _Hue_Brightness_Low + $10 : _P0_Luminosity = _Hue_Brightness_Low


__Skip_Hue_Change



   ;***************************************************************
   ;
   ;  Player0 luminosity.
   ;
   COLUP0 = _P0_Luminosity



   ;***************************************************************
   ;
   ;  Sets the width of player0.
   ;
   NUSIZ0 = 7



   ;***************************************************************
   ;
   ;  Displays the screen.
   ;
   drawscreen



   ;***************************************************************
   ;
   ;  Reset switch check and end of main loop.
   ;
   ;  Any Atari 2600 program should restart when the reset  
   ;  switch is pressed. It is part of the usual standards
   ;  and procedures.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Turns off reset restrainer bit and jumps to beginning of
   ;  main loop if the reset switch is not pressed.
   ;
   if !switchreset then _Bit0_Reset_Restrainer{0} = 0 : goto __Main_Loop

   ;```````````````````````````````````````````````````````````````
   ;  Jumps to beginning of main loop if the reset switch hasn't
   ;  been released after being pressed.
   ;
   if _Bit0_Reset_Restrainer{0} then goto __Main_Loop

   ;```````````````````````````````````````````````````````````````
   ;  Restarts the program.
   ;
   goto __Start_Restart





   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;
   ;  END OF MAIN LOOP
   ;
   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````