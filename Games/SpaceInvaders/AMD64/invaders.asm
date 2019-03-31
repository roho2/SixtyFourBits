;*********************************************************
; Space Invaders Game
;
;  Written in Assembly x64
; 
;  By Toby Opferman  3/8/2019
;
;
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************



;*********************************************************
; Included Files
;*********************************************************
include demoscene.inc
include dbuffer_public.inc
include font_public.inc
include input_public.inc
include gif_public.inc
include gameengine_public.inc
include primatives_public.inc

;*********************************************************
; External WIN32/C Functions
;*********************************************************
extern LocalAlloc:proc
extern LocalFree:proc
extern sqrt:proc
extern cos:proc
extern sin:proc
extern tan:proc
extern FindResourceA:proc
extern LoadResource:proc

LMEM_ZEROINIT EQU <40h>

;*********************************************************
; Structures
;*********************************************************



;*********************************************************
; Public Declarations
;*********************************************************
public Invaders_Init
public Invaders_Demo
public Invaders_Free

;
; Space Invaders State Machine
;
SPACE_INVADERS_STATE_LOADING              EQU <0>
SPACE_INVADERS_STATE_INTRO                EQU <1>
SPACE_INVADERS_STATE_MENU                 EQU <2>
SPACE_INVADERS_GAMEPLAY                   EQU <3>
SPACE_INVADERS_HISCORE                    EQU <4>
SPACE_INVADERS_STATE_ABOUT                EQU <5>

SPACE_INVADERS_LEVEL_ONE                  EQU <6>
SPACE_INVADERS_LEVEL_TWO                  EQU <7>
SPACE_INVADERS_LEVEL_THREE                EQU <8>
SPACE_INVADERS_LEVEL_FOUR                 EQU <9>
SPACE_INVADERS_LEVEL_FIVE                 EQU <10>

SPACE_INVADERS_FAILURE_STATE              EQU <GAME_ENGINE_FAILURE_STATE>

SPRITE_STRUCT  struct
   ImagePointer    dq ?
   ExplodePointer  dq ?   ; Optional
   SpriteAlive     dq ?
   SpriteX         dq ?
   SpriteY         dq ?
   SpriteVelX      dq ?
   SpriteVelY      dq ?
   SpriteVelMaxX   dq ?
   SpriteVelMaxY   dq ?
   SpriteWidth     dq ?
   SpriteHeight    dq ?
   SpriteFire      dq ?
   SpriteMaxFire   dq ?
   HitPoints       dq ?   ; Amount of damage needed to be destroyed
   Damage          dq ?   ; How much damage this sprite does on collsion
SPRITE_STRUCT  ends 

;
; Space Invaders Constants
;
MAX_SCORES            EQU <5>
MAX_SHIELDS           EQU <3>
MAX_ALIENS_PER_ROW    EQU <1>
MAX_ALIEN_ROWS        EQU <1>
NUMBER_OF_SPRITES     EQU <2>
MAX_LOADING_COLORS    EQU <9>
LOADING_Y             EQU <768/2 - 10>
LOADING_X             EQU <10>
MAX_FRAMES_PER_IMAGE  EQU <1>
LODING_FONT_SIZE      EQU <10>
TITLE_X               EQU <250>
TITLE_Y               EQU <10>
INTRO_Y               EQU <768 - 40>
INTRO_X               EQU <300>
INTRO_FONT_SIZE       EQU <3>
NUMBER_OF_SPRITES     EQU <75>
MAX_MENU_SELECTION    EQU <5>
MENU_MAX_TIMEOUT      EQU <30*50> ; About 22 Seconds
MOVEMENT_DEBOUNCE     EQU <0>
PLAYER_X_DIM          EQU <32>
PLAYER_Y_DIM          EQU <32>
PLAYER_MAX_Y_LOC      EQU <500>
PLAYER_START_X        EQU <1024/2 - 16>
PLAYER_START_Y        EQU <700>
PLAYER_START_MAX_VEL_X EQU <5>
PLAYER_START_MAX_VEL_Y EQU <5>
PLAYER_MAX_FIRE        EQU <5>
PLAYER_START_HP        EQU <1>
PLAYER_DAMAGE          EQU <2>
PLAYER_FIRE_MAX_Y      EQU <-5>
FIRE_X_DIM             EQU <9>
FIRE_Y_DIM             EQU <9>  
PLAYER_FIRE_DAMAGE     EQU <1>


;*********************************************************
; Data Segment
;*********************************************************
.DATA
    SpaceCurrentLevel  dq ?
    SpaceStateFuncPtrs dq  Invaders_Loading             ; SPACE_INVADERS_STATE_LOADING
                       dq  Invaders_IntroScreen         ; SPACE_INVADERS_STATE_INTRO
                       dq  Invaders_MenuScreen          ; SPACE_INVADERS_STATE_MENU
                       dq  Invaders_BoxIt               ; SPACE_INVADERS_GAMEPLAY
                       dq  Invaders_HiScoreScreen       ; SPACE_INVADERS_HISCORE
                       dq  Invaders_AboutScreen         ; SPACE_INVADERS_STATE_ABOUT
                       dq  Invaders_LevelOne            ; SPACE_INVADERS_LEVEL_ONE

    ;
    ;  Graphic Resources 
    ; 
    SpaceCurrentState               dq ?
    GifResourceType                 db "GIFFILE", 0
    SpaceInvadersLoadingScreenImage db "LOADING_GIF", 0
    SpaceInvadersIntroImage         db "INTRO_GIF", 0
    SpaceInvadersMenuImage          db "MENU_GIF", 0
    SpaceInvadersTitle              db "LOGO_GIF", 0
    SpaceInvaderSprites             db "SPRITES_GIF", 0
    SpaceInvadersGeneral            db "GENERAL_GIF", 0
 
    PlayerSprite                    SPRITE_STRUCT <?>
    PlayerFire                      SPRITE_STRUCT PLAYER_MAX_FIRE DUP(<?>)
    DeBounceMovement                dq 0 

    ;
    ; Game Text
    ;
    PressSpaceToContinue            db "<Press Spacebar>", 0
    MenuText                        dq 400, 300
                                    db "Play Game", 0
                                    dq 350, 350
                                    db "Instructions",0
                                    dq 400, 400
                                    db "Hi-Scores", 0
                                    dq 440, 450
                                    db "About", 0
                                    dq 445, 500
                                    db "Quit", 0
                                    dq 0

    AboutText                       dq 370, 375
                                    db "Programming:", 0
                                    dq 350, 425
                                    db "Toby Opferman",0
                                    dq 165, 475
                                    db "x86 64-Bit Assembly Language", 0
                                    dq 400, 525
                                    db "Graphics:", 0
                                    dq 350, 575
                                    db "The Internet", 0
                                    dq 0

    ;
    ; Menu Selection 
    ;
    MenuSelection                   dq 0
    MenuToState                     dq SPACE_INVADERS_LEVEL_ONE
                                    dq SPACE_INVADERS_GAMEPLAY
                                    dq SPACE_INVADERS_HISCORE
                                    dq SPACE_INVADERS_STATE_ABOUT
                                    dq SPACE_INVADERS_FAILURE_STATE  ; Quit
    MenuIntroTimer                  dq 0

    SpriteImageFileListAttributes   db 1, 2

    ;
    ; File Lists
    ;
    LoadingString       db "Loading...", 0 
    CurrentLoadingColor dd 0 
    LoadingColorsLoop   dd 0FF000h, 0FF00h, 0FFh, 0FFFFFFh, 0FF00FFh, 0FFFF00h, 0FFFFh, 0F01F0Eh
    SpritePointer       dq OFFSET BasicSpriteData

    ;
    ; List of Sprite Information
    ;
                        ; X, Y, X2, Y2, Start Image Number, Number Of Images
                        ;
                        ; Player Graphics
                        ;
    SpriteInformation   dq 439, 453, 448, 462, 0,16                                                                               ; Player Fire
                        dq 309, 485, 340, 515, 0,6                                                                                ; Player
                        dq 358, 483, 390, 515, 9,5                                                                                ; Player Left  J - N
                        dq 358, 483, 390, 515, 2,5                                                                                ; Player Right C - G
                        dq 309, 485, 340, 515, 6,10                                                                               ; Player Explode

                        ;
                        ; Small Ships
                        ;
                        dq 53, 284, 84, 319, 0,4                                                                                  ; Small Ship 1
                        dq 104, 284, 135, 319, 0,16                                                                               ; Small Ship 2
                        dq 155, 284, 186, 319, 0,6                                                                                ; Small Ship 3 
                        dq 53+51+51+51, 284, 84+51+51+51, 319, 0,2                                                                ; Small Ship 4 
                        dq 53+51+51+51+51-3, 284, 84+51+51+51+51-3, 319, 0, 16                                                    ; Small Ship 5 
                        dq 53+51+51+51+51+51-2, 284, 84+51+51+51+51+51, 319, 0,4                                                  ; Small Ship 6 
                        dq 53+51+51+51+51+51+51-1, 284, 84+51+51+51+51+51+51, 319, 0,8                                            ; Small Ship 7 
                        dq 53+51+51+51+51+51+51+51, 284, 84+51+51+51+51+51+51+51-7, 319, 0,4                                      ; Small Ship 8 
                        dq 53+51+51+51+51+51+51+51+51-4, 284, 84+51+51+51+51+51+51+51+51-4, 319, 0,6                              ; Small Ship 9 
                        dq 53+51+51+51+51+51+51+51+51+51-4, 284, 84+51+51+51+51+51+51+51+51+51-3, 319, 3,8                        ; Small Ship 10
                        dq 37-1, 369-31, 66-1, 401-31, 0,7                                                                        ; Small Ship 11
                        dq 37+50-1, 369-31, 66+50-1, 401-31, 0,16                                                                 ; Small Ship 12 
                        dq 37+50+50-1, 369-31,  66+50+50-1, 401-31, 0,5                                                           ; Small Ship 13 
                        dq 37+50+50+50-1,369-31, 66+50+50+50-1, 401-31, 0,16                                                      ; Small Ship 14
                        dq 37+50+50+50+50+50-1, 369-31, 66+50+50+50+50+50-1,  401-31, 0,16                                        ; Small Ship 15 
                        dq 37+50+50+50+50+50+50+50+50-1, 369-31, 66+50+50+50+50+50+50+50+50-1, 401-31, 0,3                        ; Small Ship 16
                        dq 37+50+50+50+50+50+50+50+50+50-1, 369-31, 66+50+50+50+50+50+50+50+50+50-1, 401-31, 0,16                 ; Small Ship 17
                        dq 37+50+50+50+50+50+50+50+50+50+50-1, 369-31,66+50+50+50+50+50+50+50+50+50+50-1 , 401-31, 0,16           ; Small Ship 18


                        ;
                        ; Small Ship Explosions
                        ;
                        dq 53, 284, 84, 319, 4,4                                                                                  ; Small Ship 1 Exploding
                        dq 213-1, 420-31, 247-1,  454-31, 9,7                                                                     ; Space Explosion
                        dq 155, 284, 186, 319, 6,8                                                                                ; Small Ship 3 Exploding
                        dq 53+51+51+51, 284, 84+51+51+51, 319, 2,8                                                                ; Small Ship 4 Exploding
                        dq 213-1, 420-31, 247-1,  454-31, 9,7                                                                     ; Space Explosion
                        dq 53+51+51+51+51+51-2, 284, 84+51+51+51+51+51, 319, 4,8                                                  ; Small Ship 6 Exploding
                        dq 53+51+51+51+51+51+51-1, 284, 84+51+51+51+51+51+51, 319, 8,8                                            ; Small Ship 7 Exploding
                        dq 53+51+51+51+51+51+51+51, 284, 84+51+51+51+51+51+51+51-7, 319, 4,4                                      ; Small Ship 8 Exploding
                        dq 53+51+51+51+51+51+51+51+51-4, 284, 84+51+51+51+51+51+51+51+51-4, 319, 6,6                              ; Small Ship 9 Exploding
                        dq 53+51+51+51+51+51+51+51+51+51-4, 284, 84+51+51+51+51+51+51+51+51+51-3, 319, 11,5                       ; Small Ship 10 Exploding
                        dq 37-1, 369-31, 66-1, 401-31, 8,8                                                                        ; Small Ship 11 Exploding
                        dq 213-1, 420-31, 247-1,  454-31, 9,7                                                                     ; Space Explosion
                        dq 37+50+50-1, 369-31,  66+50+50-1, 401-31, 5,5                                                           ; Small Ship 13 Exploding 
                        dq 213-1, 420-31, 247-1,  454-31, 9,7                                                                     ; Space Explosion
                        dq 37+50+50+50+50+50+50+50-1, 369-31, 66 +50+50+50+50+50+50+50-1, 401-31, 7,9                             ; Small Ship 15 Exploding
                        dq  37+50+50+50+50+50+50+50+50-1, 369-31, 66+50+50+50+50+50+50+50+50-1, 401-31, 4,7                       ; Small Ship 16 Exploding
                        dq 213-1, 420-31, 247-1,  454-31, 9,7                                                                     ; Space Explosion
                        dq 213-1, 420-31, 247-1,  454-31, 9,7                                                                     ; Space Explosion

                        ;
                        ; Large Ships
                        ;
                        dq  26, 47, 89, 144, 0,16                                                                                 ; Large Ship 1
                        dq 103, 31, 167, 159, 0,16                                                                                ; Large Ship 2
                        dq 426, 54, 490, 150, 0,16                                                                                ; Large Ship 3
                        dq 47, 211, 114, 244, 0,5                                                                                 ; Large Ship 4
                        dq 137, 204, 200, 266, 0,8                                                                                ; Large Ship 5
                        dq 227, 194, 254, 261, 0,12                                                                               ; Large Ship 6
                        dq 281, 195, 344, 261, 0,4                                                                                ; Large Ship 7 
                        dq 366, 194, 397, 258, 0,16                                                                               ; Large Ship 8
                        dq 422, 199, 477, 264, 0,8                                                                                ; Large Ship 9
                        dq 499, 214, 546, 250, 0,8                                                                                ; Large Ship 10

                        ;
                        ; Large Ships Exploding
                        ;
                        dq 281, 195, 344, 261, 8,4                                                                                ; Generic Explosion
                        dq 189, 31, 253, 159, 4,12                                                                                ; Large Ship 2 Exploding
                        dq 508, 54, 572, 150, 3, 8                                                                                ; Large Ship 3 Exploding
                        dq 47, 211, 114, 244, 6,8                                                                                 ; Large Ship 4 Exploding
                        dq 137, 204, 200, 266, 8,8                                                                                ; Large Ship 5 Exploding
                        dq 227, 194, 254, 261, 12,4                                                                               ; Large Ship 6 Exploding
                        dq 281, 195, 344, 261, 4,8                                                                                ; Large Ship 7 Exploding 
                        dq 281, 195, 344, 261, 8,4                                                                                ; Generic Explosion
                        dq 422, 199, 477, 264, 8,8                                                                                ; Large Ship 9 Exploding
                        dq 499, 214, 546, 250, 8,8                                                                                ; Large Ship 10 Exploding


                        ;
                        ; Space Mines
                        ;
                        dq 115-1,420-31,  150-1, 454-31, 0,16                                                                     ; Space Mine 1
                        dq 164-1, 420-31, 201-1, 454-31, 0,16                                                                     ; Space Mine 2
                        dq 30, 392, 62, 421, 0,8                                                                                  ; Space Mine 3
                        dq 547, 395, 569, 416, 0,4                                                                                ; Space Mine 4

                        ;
                        ; Space Mines Exploding
                        ;
                        dq 30, 392, 62, 421, 8,8                                                                                  ; Space Mine 3 Exploding
                        dq 547, 395, 569, 416, 4,8                                                                                ; Space Mine 4 Exploding

                        ;
                        ; Astroids
                        ;
                        dq 455, 390, 483, 424, 0,8                                                                                ; Large Astroid
                        dq 357, 451, 372, 465, 0,16                                                                               ; Small Astroid
                        dq 387, 452, 400, 464, 0,16                                                                               ; Small Astroid

                        ;
                        ; Power Ups
                        ;
                        dq 213-1, 420-31, 247-1,  454-31, 0,8                                                                     ; Power Up
                        dq 504, 395, 533, 419, 0,8                                                                                ; Power Up Box
                       
                        ;
                        ; Other Explosions
                        ;
                        dq 213-1, 420-31, 247-1,  454-31, 9,7                                                                     ; Space Explosion
                        dq 504, 395, 533, 419, 8,8                                                                                ; Power Up Box Exploding
                        dq 455, 390, 483, 424, 8,8                                                                                ; Large Astroid Exploding

                        ;
                        ; Alien Fire
                        ;
                        dq 413, 452, 426, 464, 0,10                                                                               ; Alien Fire
                        dq 413, 452, 426, 464, 10,4                                                                               ; Alien Fire Exploding
                        
                        ;
                        ; Images not going to use.
                        ;
                        ;  dq 160, 485, 190, 514, 0,16
                        ;  dq  37+50+50+50+50+50+50-1, 369-31, 66+50+50+50+50+50+50-1, 401-31, 0,16  
                        ;  dq 37+50+50+50+50-1, 369-31, 66+50+50+50+50-1, 401-31, 0,16 Not going to use

    ;
    ; Game Variable Structures
    ;
    SmallShips         SPRITE_STRUCT  18 DUP(<?>)
    LargeShips         SPRITE_STRUCT  10 DUP(<?>)
    SpriteConvert      SPRITE_CONVERT     <?>
    GameEngInit        GAME_ENGINE_INIT   <?>
    LoadingScreen      IMAGE_INFORMATION  <?>
    IntroScreen        IMAGE_INFORMATION  <?>
    MenuScreen         IMAGE_INFORMATION  <?>
    SpTitle            IMAGE_INFORMATION  <?>
    SpInvaders         IMAGE_INFORMATION  <?>
    SpGeneral          IMAGE_INFORMATION  <?>
    BasicSpriteData    SPRITE_BASIC_INFORMATION  NUMBER_OF_SPRITES DUP(<?>) 
    SpSpriteList       dq ?
  ;  HiScoreList        dq MAX_SCORES DUP(<>)
.CODE

;*********************************************************
;   Invaders_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Invaders_Init, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV [SpaceCurrentState], SPACE_INVADERS_STATE_LOADING
  
  MOV RCX, OFFSET SpaceInvadersLoadingScreenImage
  DEBUG_FUNCTION_CALL Invaders_LoadGifResource
  MOV RCX, RAX

  MOV RDX, OFFSET LoadingScreen
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory
  CMP RAX, 0
  JE @FailureExit

  MOV RCX, OFFSET SpaceStateFuncPtrs
  MOV RDX, OFFSET GameEngInit
  MOV GAME_ENGINE_INIT.GameFunctionPtrs[RDX], RCX
  MOV RCX, OFFSET Invaders_LoadingThread
  MOV GAME_ENGINE_INIT.GameLoadFunction[RDX],RCX
  MOV GAME_ENGINE_INIT.GameLoadCxt[RDX], 0
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_Init
  JE @FailureExit

  MOV RDX, Invaders_SpaceBar
  MOV RCX, VK_SPACE
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease
  
  MOV RDX, Invaders_UpArrow
  MOV RCX, VK_UP
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  
  
  MOV RDX, Invaders_DownArrow
  MOV RCX, VK_DOWN
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  

  MOV RDX, Invaders_Enter
  MOV RCX, VK_RETURN
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  

  MOV RDX, Invaders_RightArrow
  MOV RCX, VK_RIGHT
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  
  
  MOV RDX, Invaders_RightArrowPress
  MOV RCX, VK_RIGHT
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyPress

  MOV RDX, Invaders_LeftArrow
  MOV RCX, VK_LEFT
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  
  
  MOV RDX, Invaders_LeftArrowPress
  MOV RCX, VK_LEFT
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyPress


  MOV RDX, Invaders_UpArrowPress
  MOV RCX, VK_UP
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyPress
  
  MOV RDX, Invaders_DownArrowPress
  MOV RCX, VK_DOWN
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyPress

  MOV RDX, Invaders_SpacePress
  MOV RCX, VK_SPACE
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyPress

@SuccessExit:
  MOV EAX, 1
  JMP @ActualExit  
@FailureExit:
  XOR EAX, EAX
@ActualExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_Init, _TEXT$00




;*********************************************************
;   Invaders_SpacePress
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_SpacePress, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP [SpaceCurrentState], SPACE_INVADERS_LEVEL_ONE
  JB @GameNotActive
  CMP [PlayerSprite.SpriteFire], PLAYER_MAX_FIRE
  JAE @AlreadyAtMaxFire

  INC [PlayerSprite.SpriteFire]

  MOV RDI, OFFSET PlayerFire

  ;
  ; Find a Fire, Assume we are tracking properly and dont need to make a max.
  ;
@FindFire:

  CMP SPRITE_STRUCT.SpriteAlive[RDI], 0
  JE @Found
  ADD RDI, SIZEOF SPRITE_STRUCT
  JMP @FindFire
@Found:

  MOV SPRITE_STRUCT.SpriteAlive[RDI], 1
  MOV RCX, [PlayerSprite.SpriteY]
  MOV SPRITE_STRUCT.SpriteY[RDI], RCX
  MOV RDX, [PlayerSprite.SpriteX]
  ADD RDX, PLAYER_X_DIM/2 - FIRE_X_DIM/2
  MOV SPRITE_STRUCT.SpriteX[RDI], RDX

  MOV RDX, SPRITE_STRUCT.SpriteVelMaxY[RDI]
  MOV SPRITE_STRUCT.SpriteVelY[RDI], RDX

@AlreadyAtMaxFire:
@GameNotActive:
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_SpacePress, _TEXT$00


;*********************************************************
;   Invaders_SpaceBar
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_SpaceBar, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP [SpaceCurrentState], SPACE_INVADERS_HISCORE
  JE @GoToMenu
  CMP [SpaceCurrentState], SPACE_INVADERS_STATE_ABOUT
  JE @GoToMenu
  CMP [SpaceCurrentState], SPACE_INVADERS_STATE_INTRO
  JNE @CheckOtherState

@GoToMenu:
  MOV [SpaceCurrentState], SPACE_INVADERS_STATE_MENU
  MOV RCX, SPACE_INVADERS_STATE_MENU
  DEBUG_FUNCTION_CALL GameEngine_ChangeState
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@CheckOtherState:
  CMP [SpaceCurrentState], SPACE_INVADERS_STATE_MENU
  JNE @NotOnMenu
  MOV [MenuIntroTimer], 0

  DEBUG_FUNCTION_CALL Invaders_ResetGame

  ;
  ; Implement Menu Selection
  ;
  MOV RDX, [MenuSelection]
  MOV RCX, OFFSET MenuToState
  SHL RDX, 3
  ADD RCX, RDX
  MOV RCX, QWORD PTR [RCX]
  MOV [SpaceCurrentState], RCX
  DEBUG_FUNCTION_CALL GameEngine_ChangeState

@NotOnMenu:

;  ADD [SpritePointer], SIZE SPRITE_BASIC_INFORMATION
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_SpaceBar, _TEXT$00



;*********************************************************
;   Invaders_ResetGame
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_ResetGame, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  ;
  ; Treat Player Special
  ;
  MOV [PlayerSprite.ImagePointer], 0
  MOV [PlayerSprite.ExplodePointer], 0
  MOV [PlayerSprite.SpriteAlive], 1
  MOV [PlayerSprite.SpriteX], PLAYER_START_X
  MOV [PlayerSprite.SpriteY], PLAYER_START_Y
  MOV [PlayerSprite.SpriteVelX], 0
  MOV [PlayerSprite.SpriteVelY], 0
  MOV [PlayerSprite.SpriteVelMaxX], PLAYER_START_MAX_VEL_X
  MOV [PlayerSprite.SpriteVelMaxY], PLAYER_START_MAX_VEL_Y
  MOV [PlayerSprite.SpriteWidth], PLAYER_X_DIM
  MOV [PlayerSprite.SpriteHeight], PLAYER_Y_DIM
  MOV [PlayerSprite.SpriteFire], 0
  MOV [PlayerSprite.SpriteMaxFire], PLAYER_MAX_FIRE
  MOV [PlayerSprite.HitPoints], PLAYER_START_HP
  MOV [PlayerSprite.Damage], PLAYER_DAMAGE

  MOV RDI, OFFSET PlayerFire
  XOR R8, R8
  ;
  ; Initialize Player's Fire
  ;
@InitPlayerFire:

  MOV SPRITE_STRUCT.ImagePointer[RDI], 0
  MOV SPRITE_STRUCT.ExplodePointer[RDI], 0
  MOV SPRITE_STRUCT.SpriteAlive[RDI], 0
  MOV SPRITE_STRUCT.SpriteX[RDI], 0
  MOV SPRITE_STRUCT.SpriteY[RDI], 0
  MOV SPRITE_STRUCT.SpriteVelX[RDI], 0
  MOV SPRITE_STRUCT.SpriteVelY[RDI], PLAYER_FIRE_MAX_Y
  MOV SPRITE_STRUCT.SpriteVelMaxX[RDI], 0
  MOV SPRITE_STRUCT.SpriteVelMaxY[RDI], PLAYER_FIRE_MAX_Y
  MOV SPRITE_STRUCT.SpriteWidth[RDI], FIRE_X_DIM
  MOV SPRITE_STRUCT.SpriteHeight[RDI], FIRE_Y_DIM
  MOV SPRITE_STRUCT.SpriteFire[RDI], 0
  MOV SPRITE_STRUCT.SpriteMaxFire[RDI], 0
  MOV SPRITE_STRUCT.HitPoints[RDI], 0
  MOV SPRITE_STRUCT.Damage[RDI], PLAYER_FIRE_DAMAGE

  ADD RDI, SIZEOF SPRITE_STRUCT
  INC R8
  CMP R8, PLAYER_MAX_FIRE
  JB @InitPlayerFire

  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_ResetGame, _TEXT$00


;*********************************************************
;   Invaders_Enter
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_Enter, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP [SpaceCurrentState], SPACE_INVADERS_STATE_MENU
  JNE @CheckOtherState

  MOV [MenuIntroTimer], 0

  DEBUG_FUNCTION_CALL Invaders_ResetGame
  ;
  ; Implement Menu Selection
  ;
  MOV RDX, [MenuSelection]
  MOV RCX, OFFSET MenuToState
  SHL RDX, 3
  ADD RCX, RDX
  MOV RCX, QWORD PTR [RCX]
  MOV [SpaceCurrentState], RCX
  DEBUG_FUNCTION_CALL GameEngine_ChangeState

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@CheckOtherState:
  ADD [SpritePointer], SIZE SPRITE_BASIC_INFORMATION
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_Enter, _TEXT$00


;*********************************************************
;   Invaders_LeftArrowPress
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_LeftArrowPress, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  DEC [DeBounceMovement]
  CMP [DeBounceMovement], 0
  JGE @SkipUpate
  MOV [DeBounceMovement], MOVEMENT_DEBOUNCE
  MOV RDX, [PlayerSprite.SpriteVelMaxX]
  NEG RDX
  CMP RDX, [PlayerSprite.SpriteVelX]
  JE @SkipUpate

  DEC [PlayerSprite.SpriteVelX]

@SkipUpate:
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_LeftArrowPress, _TEXT$00





;*********************************************************
;   Invaders_RightArrowPress
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_RightArrowPress, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  DEC [DeBounceMovement]
  CMP [DeBounceMovement], 0
  JGE @SkipUpate
  MOV [DeBounceMovement], MOVEMENT_DEBOUNCE
  MOV RDX, [PlayerSprite.SpriteVelMaxX]
  CMP RDX, [PlayerSprite.SpriteVelX]
  JE @SkipUpate

  INC [PlayerSprite.SpriteVelX]

@SkipUpate:
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_RightArrowPress, _TEXT$00

;*********************************************************
;   Invaders_LeftArrow
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_LeftArrow, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV [DeBounceMovement], 0
  MOV [PlayerSprite.SpriteVelX], 0

  DEBUG_FUNCTION_CALL Invaders_ResetPlayerLeftRight

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_LeftArrow, _TEXT$00




;*********************************************************
;   Invaders_RightArrow
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_RightArrow, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV [DeBounceMovement], 0
  MOV [PlayerSprite.SpriteVelX], 0

  DEBUG_FUNCTION_CALL Invaders_ResetPlayerLeftRight

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_RightArrow, _TEXT$00






;*********************************************************
;   Invaders_DownArrowPress
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_DownArrowPress, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  DEC [DeBounceMovement]
  CMP [DeBounceMovement], 0
  JGE @SkipUpate
  MOV [DeBounceMovement], MOVEMENT_DEBOUNCE
  MOV RDX, [PlayerSprite.SpriteVelMaxY]
  CMP RDX, [PlayerSprite.SpriteVelY]
  JE @SkipUpate

  INC [PlayerSprite.SpriteVelY]

@SkipUpate:
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_DownArrowPress, _TEXT$00






;*********************************************************
;   Invaders_UpArrowPress
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_UpArrowPress, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  DEC [DeBounceMovement]
  CMP [DeBounceMovement], 0
  JGE @SkipUpate
  MOV [DeBounceMovement], MOVEMENT_DEBOUNCE
  MOV RDX, [PlayerSprite.SpriteVelMaxY]
  NEG RDX
  CMP RDX, [PlayerSprite.SpriteVelY]
  JE @SkipUpate

  DEC [PlayerSprite.SpriteVelY]

@SkipUpate:
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_UpArrowPress, _TEXT$00



;*********************************************************
;   Invaders_DownArrow
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_DownArrow, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV [PlayerSprite.SpriteVelY], 0
  MOV [DeBounceMovement], 0

  CMP [SpaceCurrentState], SPACE_INVADERS_STATE_MENU
  JNE @CheckOtherState
  MOV [MenuIntroTimer], 0
  INC QWORD PTR [MenuSelection]
  
  CMP QWORD PTR [MenuSelection], MAX_MENU_SELECTION
  JB @NoResetToStart
  MOV [MenuSelection], 0

@NoResetToStart:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@CheckOtherState:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_DownArrow, _TEXT$00


;*********************************************************
;   Invaders_UpArrow
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_UpArrow, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV [PlayerSprite.SpriteVelY], 0
  MOV [DeBounceMovement], 0

  CMP [SpaceCurrentState], SPACE_INVADERS_STATE_MENU
  JNE @CheckOtherState

  MOV [MenuIntroTimer], 0

  CMP QWORD PTR [MenuSelection], 0
  JA @Decrement
  MOV [MenuSelection], MAX_MENU_SELECTION
@Decrement:
  DEC QWORD PTR [MenuSelection]
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@CheckOtherState:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_UpArrow, _TEXT$00

;*********************************************************
;   Invaders_Demo
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_Demo, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_Demo, _TEXT$00




;*********************************************************
;   Invaders_LoadingThread
;
;        Parameters: Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_LoadingThread, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RCX, OFFSET SpaceInvadersIntroImage
  DEBUG_FUNCTION_CALL Invaders_LoadGifResource
  MOV RCX, RAX
    
  MOV RDX, OFFSET IntroScreen
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory
  CMP RAX, 0
  JE @FailureExit

  MOV [IntroScreen.StartX], 0
  MOV [IntroScreen.StartY], 0
  MOV [IntroScreen.InflateCountDown], 0
  MOV [IntroScreen.InflateCountDownMax], 0
  PXOR XMM0, XMM0
  MOVSD [IntroScreen.IncrementX], XMM0
  MOVSD [IntroScreen.IncrementY], XMM0

  MOV RCX, OFFSET SpaceInvadersMenuImage
  DEBUG_FUNCTION_CALL Invaders_LoadGifResource
  MOV RCX, RAX

  MOV RDX, OFFSET MenuScreen
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory
  CMP RAX, 0
  JE @FailureExit

  MOV [MenuScreen.StartX], 0
  MOV [MenuScreen.StartY], 0
  MOV [MenuScreen.InflateCountDown], 0
  MOV [MenuScreen.InflateCountDownMax], 0
  PXOR XMM0, XMM0
  MOVSD [MenuScreen.IncrementX], XMM0
  MOVSD [MenuScreen.IncrementY], XMM0

  MOV RCX, OFFSET SpaceInvadersTitle
  DEBUG_FUNCTION_CALL Invaders_LoadGifResource
  MOV RCX, RAX

  MOV RDX, OFFSET SpTitle
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory
  CMP RAX, 0
  JE @FailureExit

  MOV [SpTitle.StartX], 0
  MOV [SpTitle.StartY], 0
  MOV [SpTitle.InflateCountDown], 0
  MOV [SpTitle.InflateCountDownMax], 0
  PXOR XMM0, XMM0
  MOVSD [SpTitle.IncrementX], XMM0
  MOVSD [SpTitle.IncrementY], XMM0

  MOV RCX, OFFSET SpaceInvadersGeneral
  DEBUG_FUNCTION_CALL Invaders_LoadGifResource
  MOV RCX, RAX

  MOV RDX, OFFSET SpGeneral
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory
  CMP RAX, 0
  JE @FailureExit

  MOV [SpGeneral.StartX], 0
  MOV [SpGeneral.StartY], 0
  MOV [SpGeneral.InflateCountDown], 0
  MOV [SpGeneral.InflateCountDownMax], 0
  PXOR XMM0, XMM0
  MOVSD [SpGeneral.IncrementX], XMM0
  MOVSD [SpGeneral.IncrementY], XMM0
  
  MOV RCX, OFFSET SpaceInvaderSprites
  DEBUG_FUNCTION_CALL Invaders_LoadGifResource
  MOV RCX, RAX

  MOV RDX, OFFSET SpInvaders
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory
  CMP RAX, 0
  JE @FailureExit

  MOV [SpInvaders.StartX], 0
  MOV [SpInvaders.StartY], 0
  MOV [SpInvaders.InflateCountDown], 0
  MOV [SpInvaders.InflateCountDownMax], 0
  PXOR XMM0, XMM0
  MOVSD [SpInvaders.IncrementX], XMM0
  MOVSD [SpInvaders.IncrementY], XMM0
  MOV [SpInvaders.ImageHeight], 700

 
  DEBUG_FUNCTION_CALL Invaders_LoadSprites


  MOV EAX, 1
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@FailureExit:
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_LoadingThread, _TEXT$00

;*********************************************************
;   Invaders_LoadSprites
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_LoadSprites, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RBX, OFFSET BasicSpriteData
  MOV RDI, OFFSET SpInvaders

  XOR RSI, RSI
  MOV R12, OFFSET SpriteInformation
@LoadNextSprite:

  MOV [SpriteConvert.ImageInformationPtr], RDI
  MOV [SpriteConvert.SpriteBasicInformtionPtr], RBX

  MOV R8, [R12]
  MOV [SpriteConvert.SpriteX], R8
  ADD R12, 8

  MOV R8, [R12]
  MOV [SpriteConvert.SpriteY], R8
  ADD R12, 8

  MOV R8, [R12]
  MOV [SpriteConvert.SpriteX2], R8
  ADD R12, 8

  MOV R8, [R12]
  MOV [SpriteConvert.SpriteY2], R8
  ADD R12, 8

  MOV R8, [R12]
  MOV [SpriteConvert.SpriteImageStart], R8
  ADD R12, 8

  MOV R8, [R12]
  MOV [SpriteConvert.SpriteNumImages],R8
  ADD R12, 8

  MOV RCX, OFFSET SpriteConvert
  DEBUG_FUNCTION_CALL GameEngine_ConvertImageToSprite

  ; MOV SPRITE_BASIC_INFORMATION.SpriteMaxFrames[RBX], 50
  ADD RBX, SIZE SPRITE_BASIC_INFORMATION
  INC RSI
  CMP RSI, NUMBER_OF_SPRITES
  JB @LoadNextSprite
  

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_LoadSprites, _TEXT$00


;*********************************************************
;   Invaders_Loading
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value:State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_Loading, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R10, RCX
  MOV R11, RDX
  MOV RSI, [LoadingScreen.ImageListPtr]
  MOV RDI, RDX
  MOV RCX, [LoadingScreen.ImgOffsets]
  REP MOVSB

  INC [CurrentLoadingColor]
  CMP [CurrentLoadingColor], MAX_LOADING_COLORS
  JB @DisplayLoading
  MOV [CurrentLoadingColor], 0

@DisplayLoading:
  ;
  ; Load next color
  ;
  MOV EDX, [CurrentLoadingColor]
  MOV RCX, OFFSET LoadingColorsLoop
  SHL RDX, 2
  ADD RCX, RDX
  MOV ECX, [RCX]
       
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RCX
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], LODING_FONT_SIZE
  MOV R9, LOADING_Y
  MOV R8, LOADING_X
  MOV RDX, OFFSET LoadingString
  MOV RCX, R10
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV RAX, SPACE_INVADERS_STATE_LOADING
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_Loading, _TEXT$00



;*********************************************************
;   Invaders_IntroScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_IntroScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET IntroScreen
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET SpTitle
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, INTRO_Y
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressSpaceToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [SpaceCurrentState], SPACE_INVADERS_STATE_INTRO
  MOV RAX, SPACE_INVADERS_STATE_INTRO
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_IntroScreen, _TEXT$00


;*********************************************************
;   Invaders_AboutScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_AboutScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET SpGeneral
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET SpTitle
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV R8, 20
  MOV RDX, OFFSET AboutText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DisplayScrollText

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, INTRO_Y
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressSpaceToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [SpaceCurrentState], SPACE_INVADERS_STATE_ABOUT
  MOV RAX, SPACE_INVADERS_STATE_ABOUT
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_AboutScreen, _TEXT$00

;*********************************************************
;   Invaders_HiScoreScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_HiScoreScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET SpGeneral
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET SpTitle
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage


  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, INTRO_Y
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressSpaceToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [SpaceCurrentState], SPACE_INVADERS_HISCORE
  MOV RAX, SPACE_INVADERS_HISCORE
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_HiScoreScreen, _TEXT$00



;*********************************************************
;   Invaders_DisplayScrollText
;
;        Parameters: Master Context, Text, Highlight Index
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_DisplayScrollText, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  MOV RBX, R8

  XOR R12, R12

@DisplayMenuText:
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  CMP R12, RBX
  JNE @SkipColorChange
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FF0000h

@SkipColorChange:
  
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE

  MOV R8, QWORD PTR [RDI]
  ADD RDI, 8
  MOV R9, QWORD PTR [RDI]
  ADD RDI, 8

  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord
@FindEnd:
  INC RDI
  CMP BYTE PTR [RDI], 0
  JNZ @FindEnd

  INC R12

  INC RDI
  CMP QWORD PTR [RDI], 0
  JNE @DisplayMenuText

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_DisplayScrollText, _TEXT$00

;*********************************************************
;   Invaders_BoxIt
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_BoxIt, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX

  XOR R9, R9
  XOR R8, R8
  MOV RDX, OFFSET SpInvaders
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage
  
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 144
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 89
  MOV R9, 47
  MOV R8, 26
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox


  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 159
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 167
  MOV R9, 31
  MOV R8, 103
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 159
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 167+86
  MOV R9, 31
  MOV R8, 103+86
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 150
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 490
  MOV R9, 54
  MOV R8, 426
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox


  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 150
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 490+82
  MOV R9, 54
  MOV R8, 426+82
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84
  MOV R9, 284
  MOV R8, 53
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox


  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51
  MOV R9, 284
  MOV R8, 53+51
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51+51
  MOV R9, 284
  MOV R8, 53+51+51
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51+51+51
  MOV R9, 284
  MOV R8, 53+51+51+51
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51+51+51+51-3
  MOV R9, 284
  MOV R8, 53+51+51+51+51-3
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51+51+51+51+51
  MOV R9, 284
  MOV R8, 53+51+51+51+51+51-2
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51+51+51+51+51+51
  MOV R9, 284
  MOV R8, 53+51+51+51+51+51+51-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox


  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51+51+51+51+51+51+51-7
  MOV R9, 284
  MOV R8, 53+51+51+51+51+51+51+51
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51+51+51+51+51+51+51+51-4
  MOV R9, 284
  MOV R8, 53+51+51+51+51+51+51+51+51-4
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51+51+51+51+51+51+51+51+51-3
  MOV R9, 284
  MOV R8, 53+51+51+51+51+51+51+51+51+51-4
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 454-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 150-1
  MOV R9, 420-31
  MOV R8, 115-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 454-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 201-1
  MOV R9, 420-31
  MOV R8, 164-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 454-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 247-1
  MOV R9, 420-31
  MOV R8, 213-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox


  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66-1
  MOV R9, 369-31
  MOV R8, 37-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox


  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50-1
  MOV R9, 369-31
  MOV R8, 37+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50+50+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50+50+50+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50+50+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50+50+50+50+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50+50+50+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP],66 +50+50+50+50+50+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50+50+50+50+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50+50+50+50+50+50+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50+50+50+50+50+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50+50+50+50+50+50+50+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50+50+50+50+50+50+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50+50+50+50+50+50+50+50+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50+50+50+50+50+50+50+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox


  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 244
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 114
  MOV R9, 211
  MOV R8, 47
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox


  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 266
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 200
  MOV R9, 204
  MOV R8, 137
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 261
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 254
  MOV R9, 194
  MOV R8, 227
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 261
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 344
  MOV R9, 195
  MOV R8, 281
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 258
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 397
  MOV R9, 194
  MOV R8, 366
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 264
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 477
  MOV R9, 199
  MOV R8, 422
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox


  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 250
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 546
  MOV R9, 214
  MOV R8, 499
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox



  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 421
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 62
  MOV R9, 392
  MOV R8, 30
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox


  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 424
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 483
  MOV R9, 390
  MOV R8, 455
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 419
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 533
  MOV R9, 395
  MOV R8, 504
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox



  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 416
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 569
  MOV R9, 395
  MOV R8, 547
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox



  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 465
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 372
  MOV R9, 451
  MOV R8, 357
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox



  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 464
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 400
  MOV R9, 452
  MOV R8, 387
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox



  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 464
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 426
  MOV R9, 452
  MOV R8, 413
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox



  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 462
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 448
  MOV R9, 453
  MOV R8, 439
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox



  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 514
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 190
  MOV R9, 485
  MOV R8, 160
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox



  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 515
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 340
  MOV R9, 485
  MOV R8, 309
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox



  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 515
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 390
  MOV R9, 483
  MOV R8, 358
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox





  MOV [SpaceCurrentState], SPACE_INVADERS_GAMEPLAY
  MOV RAX, SPACE_INVADERS_GAMEPLAY

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_BoxIt, _TEXT$00


;*********************************************************
;   Invaders_DrawBox
;   Not used in the game, this is the herlp function to split the
;   sprites up from a single image.
;        Parameters: Master Context, Double Buffer X, Y, X2, Y2
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Invaders_DrawBox, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX

  MOV STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP], R8     ; X
  MOV STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP], R9     ; Y

  ;
  ; X, Y to X2, Y
  ;
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RDI
  MOV R10, OFFSET Invaders_PlotPixel
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], R10
  MOV R9, STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], R9
  MOV R9, STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP]
  MOV RDX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Prm_DrawLine

  ;
  ; X, Y to X, Y2
  ;
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RDI
  MOV R10, OFFSET Invaders_PlotPixel
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], R10
  MOV R9, STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], R9
  MOV R9, STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP]
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP]
  MOV RDX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Prm_DrawLine

  ;
  ; X, Y2 to X2, Y2
  ;
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RDI
  MOV R10, OFFSET Invaders_PlotPixel
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], R10
  MOV R9, STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], R9
  MOV R9, STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]
  MOV RDX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Prm_DrawLine


  ;
  ; X2, Y to X2, Y2
  ;
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RDI
  MOV R10, OFFSET Invaders_PlotPixel
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], R10
  MOV R9, STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], R9
  MOV R9, STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP]
  MOV RDX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Prm_DrawLine
 

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_DrawBox, _TEXT$00

;*********************************************************
;   Invaders_PlotPixel
;
;        Parameters: X, Y, Context, Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Invaders_PlotPixel, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, R9
  MOV RDI, R8

  XOR RAX, RAX
  CMP RCX, MASTER_DEMO_STRUCT.ScreenWidth[R9]
  JA @OffScreen
  CMP RDX, MASTER_DEMO_STRUCT.ScreenHeight[R9]
  JA @OffScreen
  
  MOV RAX, RDX
  XOR RDX, RDX
  MUL MASTER_DEMO_STRUCT.ScreenWidth[R9]
  SHL RAX, 2
  SHL RCX, 2
  ADD RAX, RCX
  MOV DWORD PTR [RDI + RAX], 0FFFFFFh
  
  MOV EAX, 1
@OffScreen:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_PlotPixel, _TEXT$00

;*********************************************************
;   Invaders_MenuScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_MenuScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET MenuScreen
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET SpTitle
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV R8, [MenuSelection]
  MOV RDX, OFFSET MenuText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DisplayScrollText

  MOV [SpaceCurrentState], SPACE_INVADERS_STATE_MENU

  INC [MenuIntroTimer]
  MOV RAX, [MenuIntroTimer]
  CMP RAX, MENU_MAX_TIMEOUT
  JB @KeepOnSpaceInvadersMenu

  MOV [MenuIntroTimer], 0
  MOV [SpaceCurrentState], SPACE_INVADERS_STATE_INTRO
  
@KeepOnSpaceInvadersMenu:
  MOV RAX, [SpaceCurrentState]
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_MenuScreen, _TEXT$00


;*********************************************************
;   Invaders_LevelOne
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_LevelOne, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DisplayPlayer

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DisplayPlayerFire

  MOV [SpaceCurrentState], SPACE_INVADERS_LEVEL_ONE
  MOV RAX, [SpaceCurrentState]
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_LevelOne, _TEXT$00


;*********************************************************
;   Invaders_DisplayPlayer
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_DisplayPlayer, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  ;
  ; Update The Player's Movement
  ;
  MOV RCX, [PlayerSprite.SpriteX]
  ADD RCX, [PlayerSprite.SpriteVelX]
  MOV [PlayerSprite.SpriteX], RCX
  CMP RCX, 0
  JGE @CheckUpperBoundsX
  MOV [PlayerSprite.SpriteX], 0
  JMP @CheckYVelocity

@CheckUpperBoundsX:
  ADD RCX, PLAYER_X_DIM
  CMP RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  JL @CheckYVelocity
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SUB RCX, PLAYER_X_DIM + 1
  MOV [PlayerSprite.SpriteX], RCX

@CheckYVelocity:
  MOV RDX, [PlayerSprite.SpriteY]
  ADD RDX, [PlayerSprite.SpriteVelY]
  MOV [PlayerSprite.SpriteY], RDX
  CMP RDX, PLAYER_MAX_Y_LOC
  JGE @CheckUpperBoundsY
  MOV [PlayerSprite.SpriteY], PLAYER_MAX_Y_LOC
  JMP @DisplaySprite

@CheckUpperBoundsY:
  ADD RDX, PLAYER_Y_DIM
  CMP RDX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  JL @DisplaySprite
  MOV RCX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  SUB RCX, PLAYER_Y_DIM + 1
  MOV [PlayerSprite.SpriteY], RCX

@DisplaySprite:  
  CMP [PlayerSprite.SpriteVelX], 0
  JE @DisplayRegularSprite

  CMP [PlayerSprite.SpriteVelX], 0
  JL @DisplayLeft

  MOV R9, [PlayerSprite.SpriteY]
  MOV R8, [PlayerSprite.SpriteX]
  MOV RDX, [SpritePointer]
  ADD RDX, SIZE SPRITE_BASIC_INFORMATION*3
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplaySpriteNoLoop

  JMP @PlayerComplete
@DisplayLeft:
  MOV R9, [PlayerSprite.SpriteY]
  MOV R8, [PlayerSprite.SpriteX]
  MOV RDX, [SpritePointer]
  ADD RDX, SIZE SPRITE_BASIC_INFORMATION*2
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplaySpriteNoLoop
  JMP @PlayerComplete
@DisplayRegularSprite:  
  MOV R9, [PlayerSprite.SpriteY]
  MOV R8, [PlayerSprite.SpriteX]
  MOV RDX, [SpritePointer]
  ADD RDX, SIZE SPRITE_BASIC_INFORMATION
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplaySprite  

@PlayerComplete:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_DisplayPlayer, _TEXT$00


;*********************************************************
;   Invaders_DisplayPlayerFire
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_DisplayPlayerFire, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV RDI, OFFSET PlayerFire
  XOR R12, R12

  ;
  ; Diplay Player's Fire
  ;
@DisplayPlayerFire:

  CMP SPRITE_STRUCT.SpriteAlive[RDI], 0
  JNE @AttemptDisplayFire
  INC R12
  ADD RDI, SIZEOF SPRITE_STRUCT
  CMP R12, PLAYER_MAX_FIRE
  JB @DisplayPlayerFire
  JMP @DisplayComplete
@AttemptDisplayFire:
  MOV RCX, SPRITE_STRUCT.SpriteY[RDI]
  ADD RCX, SPRITE_STRUCT.SpriteVelY[RDI]
  MOV SPRITE_STRUCT.SpriteY[RDI], RCX

  CMP QWORD PTR RCX, 0
  JG @DisplayFire
  MOV SPRITE_STRUCT.SpriteAlive[RDI], 0
  DEC [PlayerSprite.SpriteFire] 

  JMP @CheckNext
@DisplayFire:
  MOV R9, SPRITE_STRUCT.SpriteY[RDI]
  MOV R8, SPRITE_STRUCT.SpriteX[RDI]
  MOV RDX, [SpritePointer]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplaySprite  
@CheckNext:  
  ADD RDI, SIZEOF SPRITE_STRUCT
  INC R12
  CMP R12, PLAYER_MAX_FIRE
  JB @DisplayPlayerFire

@DisplayComplete:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_DisplayPlayerFire, _TEXT$00




;*********************************************************
;   Invaders_ResetPlayerLeftRight
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_ResetPlayerLeftRight, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDX, [SpritePointer]
  MOV RCX, RDX
  ADD RDX, SIZE SPRITE_BASIC_INFORMATION*3
  ADD RCX, SIZE SPRITE_BASIC_INFORMATION*2

  MOV SPRITE_BASIC_INFORMATION.CurrentSprite[RDX], 0   
  MOV RAX, SPRITE_BASIC_INFORMATION.SpriteListPtr[RDX]
  MOV SPRITE_BASIC_INFORMATION.CurrSpritePtr[RDX], RAX

  MOV SPRITE_BASIC_INFORMATION.CurrentSprite[RCX], 0   
  MOV RAX, SPRITE_BASIC_INFORMATION.SpriteListPtr[RCX]
  MOV SPRITE_BASIC_INFORMATION.CurrSpritePtr[RCX], RAX

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_ResetPlayerLeftRight, _TEXT$00


;*********************************************************
;   Invaders_SpriteTest
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_SpriteTest, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  
  MOV R9, 100
  MOV R8, 100
  MOV RDX, [SpritePointer]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplaySprite



  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 4
  MOV R9, 500
  MOV R8, 500
  

  MOV RDX, [SpritePointer]
  MOV RAX, SPRITE_BASIC_INFORMATION.CurrentSprite[RDX]
  ADD RAX, 'A'
  MOV RDX, OFFSET LoadingString
  MOV [RDX], AL
  MOV BYTE PTR [RDX+1], 0

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord


  MOV [SpaceCurrentState], SPACE_INVADERS_LEVEL_ONE
  MOV RAX, SPACE_INVADERS_LEVEL_ONE

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_SpriteTest, _TEXT$00


;*********************************************************
;   Invaders_Free
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Invaders_Free, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX




  

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_Free, _TEXT$00

;*********************************************************
;   Invaders_LoadGifResource
;
;        Parameters: Resource Name
;
;        Return Value: Memory
;
;
;*********************************************************  
NESTED_ENTRY Invaders_LoadGifResource, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV R8, OFFSET GifResourceType         ; Resource Type
  MOV RDX, RSI                           ; Resource Name
  XOR RCX, RCX                           ; Use process module
  DEBUG_FUNCTION_CALL FindResourceA

  MOV RDX, RAX
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL LoadResource

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_LoadGifResource, _TEXT$00







END