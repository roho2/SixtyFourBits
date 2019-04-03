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
extern sprintf:proc
extern LockResource:proc
extern GetEnvironmentVariableA:proc
extern CreateDirectoryA:proc
extern CreateFileA:proc
extern WriteFile:proc
extern ReadFile:proc
extern CloseHandle:proc

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
SPACE_INVADERS_END_GAME                   EQU <6>
SPACE_INVADERS_STATE_ENTER_HI_SCORE       EQU <7>
SPACE_INVADERS_LEVEL_ONE                  EQU <8>
SPACE_INVADERS_LEVEL_TWO                  EQU <9>
SPACE_INVADERS_LEVEL_THREE                EQU <10>
SPACE_INVADERS_LEVEL_FOUR                 EQU <11>
SPACE_INVADERS_LEVEL_FIVE                 EQU <12>

SPACE_INVADERS_FAILURE_STATE              EQU <GAME_ENGINE_FAILURE_STATE>

SPRITE_STRUCT  struct
   ImagePointer    dq ?   ; Sprite Basic Information
   ExplodePointer  dq ?   ; Optional Sprite Basic Information
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
   MaxHp           dq ?
   Damage          dq ?   ; How much damage this sprite does on collsion
   pNext           dq ?
   pPrev           dq ?
   KillOffscreen   dq ?   ; If it goes off screen, it ends or should it be reset.
   SpritePrototypePtr    dq ?
   SpriteInactiveListPtr dq ?
   SpriteCategory        dq ?
   SpriteBasePointsValue dq ?
   pfnSpriteMovementUpdate  dq ?                        ; Movement update function pointer
   pfnAddedBackToList    dq ?
SPRITE_STRUCT  ends 

;
; Space Invaders Constants
;
MAX_SCORES             EQU <5>
MAX_SHIELDS            EQU <3>
MAX_ALIENS_PER_ROW     EQU <1>
MAX_ALIEN_ROWS         EQU <1>
NUMBER_OF_SPRITES      EQU <2>
MAX_LOADING_COLORS     EQU <9>
LOADING_Y              EQU <768/2 - 10>
LOADING_X              EQU <10>
MAX_FRAMES_PER_IMAGE   EQU <1>
LODING_FONT_SIZE       EQU <10>
TITLE_X                EQU <250>
TITLE_Y                EQU <10>
INTRO_Y                EQU <768 - 40>
INTRO_X                EQU <300>
INTRO_FONT_SIZE        EQU <3>

NUMBER_OF_SPRITES      EQU <(SpriteInformationEnd - SpriteInformation) / (6*8)>

MAX_MENU_SELECTION     EQU <5>
MENU_MAX_TIMEOUT       EQU <30*50> ; About 22 Seconds
MOVEMENT_DEBOUNCE      EQU <0>
PLAYER_MAX_Y_LOC       EQU <500>
PLAYER_START_X         EQU <1024/2 - 16>
PLAYER_START_Y         EQU <700>
PLAYER_START_MAX_VEL_X EQU <5>
PLAYER_START_MAX_VEL_Y EQU <5>
PLAYER_MAX_FIRE        EQU <5>          ; Starting Level 1 max
PLAYER_START_HP        EQU <1>
PLAYER_DAMAGE          EQU <2>
PLAYER_FIRE_MAX_Y      EQU <-5>
LARGE_GAME_ALLOCATION  EQU <1024*1024*5> ; 5 MB
MAXIMUM_PLAYER_FIRE    EQU <5>          ; Total Game Maximum Fire
SMALL_ALIEN_SHIPS_MAX  EQU <18*10>
LARGE_ALIEN_SHIPS_MAX  EQU <10>
ASTROIDS_SMALL_MAX     EQU <100>
ASTROIDS_MAX_VELOCITY  EQU <7>
LEVEL_INTRO_TIMER_SIZE EQU <30*5>   
ASTROID_BASE_POINTS    EQU <10>
PLAYER_START_LIVES     EQU <3>
HI_SCORE_Y_START       EQU <350>
HI_SCORE_Y_INC         EQU <25>
HI_SCORE_X             EQU <350>
HI_SCORE_FONT_SIZE     EQU <2>
MAX_HI_SCORES          EQU <10>
HI_SCORE_TITLE_X       EQU <275>
HI_SCORE_TITLE_Y       EQU <275>
HI_SCORE_TITLE_SIZE    EQU <5>
ALIEN_FIRE_MAX         EQU <500>
SPACE_MINES_MAX        EQU <15>
ASTROIDS_LARGE_MAX     EQU <50>
POWER_UPS_MAX          EQU <7>
ALIEN_FIRE_LARGE_MAX   EQU <10>
MAX_SPRITE_LIST        EQU <18>

ALIEN_SHIP_MAX_VEL_X   EQU <6>
ALIEN_SHIP_MAX_VEL_Y   EQU <6>
SMALL_SHIP_BASE_VALUE  EQU <15>
TOTAL_ENEMY_LISTS      EQU <8>

ASTROIDS_DAMAGE           EQU   <1>
ALIEN_SHIP_MAX_FIRE       EQU   <3>
ALIEN_SHIP_HIT_POINTS     EQU   <2>
ALIEN_SHIP_DAMAGE         EQU   <2>
ALIEN_SHIP_L_MAX_VX       EQU   <4>
ALIEN_SHIP_L_MAX_VY       EQU   <3>
LARGE_SHIP_BASE_VALUE     EQU   <50>
LARGE_SHIP_MAX_FIRE       EQU   <5>
LARGE_SHIP_HIT_POINTS     EQU   <15>
LARGE_SHIP_DAMAGE         EQU   <20>
ALIEN_FIRE_MAX_VEL_X      EQU   <0>
ALIEN_FIRE_MAX_VEL_Y      EQU   <-3>
ALIEN_FIRE_BASE_VALUE     EQU   <1>
ALIEN_FIRE_DAMAGE            EQU <1>
ALIEN_LARGE_FIRE_MAX_VELX    EQU <0>
ALIEN_LARGE_FIRE_MAX_VELY    EQU <2>
ALIEN_LARGE_FIRE_BASE_VALUE  EQU <5>
ALIEN_LARGE_FIRE_DAMAGE      EQU <5>
SPACE_MINES_MAX_VEL_X        EQU <2>
SPACE_MINES_MAX_VEL_Y        EQU <2>
SPACE_MINES_BASE_POINTS      EQU <5>
SPACE_MINES_DAMAGE           EQU <5>
LARGE_ASTROID_MAX_VEL_X      EQU <3>
LARGE_ASTROID_MAX_VEL_Y      EQU <2>
LARGE_ASTROID_BASE_VALUE     EQU <5>
LARGE_ASTROID_DAMAGE         EQU <5>
POWER_UP_MAX_VEL_X           EQU <5>
POWER_UP_MAX_VEL_Y           EQU <5>
POWER_UP_SPECIAL_DAMAGE      EQU <01337h>


;
; Sprite Setup
;
ASTROID_BASIC_SPRITE                EQU <70>
ASTROID_BASIC_SPRITE_NUM            EQU <2>

LARGE_ASTROID_BASIC_SPRITE                EQU <69>
LARGE_ASTROID_BASIC_SPRITE_EXPLODE        EQU <76>
LARGE_ASTROID_BASIC_SPRITE_NUM            EQU <2>

SMALL_ALIEN_BASIC_SPRITE            EQU <5>
SMALL_ALIEN_BASIC_SPRITE_EXPLODE    EQU <23>
SMALL_ALIEN_BASIC_SPRITE_NUM        EQU <18>

LARGE_ALIEN_BASIC_SPRITE            EQU <41>
LARGE_ALIEN_BASIC_SPRITE_EXPLODE    EQU <51>
LARGE_ALIEN_BASIC_SPRITE_NUM        EQU <10>

SPACE_MINE_BASIC_SPRITE             EQU <61>
SPACE_MINE_BASIC_SPRITE_EXPLODE     EQU <65>
SPACE_MINE_BASIC_SPRITE_NUM         EQU <4>

POWER_UPS_BASIC_SPRITE              EQU <72>
POWER_UPS_BASIC_SPRITE_EXPLODE      EQU <74>
POWER_UPS_BASIC_SPRITE_NUM          EQU <2>

ALIEN_FIRE_BASIC_SPRITE              EQU <77>
ALIEN_FIRE_BASIC_SPRITE_EXPLODE      EQU <78>
ALIEN_FIRE_BASIC_SPRITE_NUM          EQU <1>

MAX_SHIPS_SCREEN                     EQU <1>
;
; We will hard code these dimenstions for now.
;
PLAYER_X_DIM           EQU <32>
PLAYER_Y_DIM           EQU <32>
FIRE_X_DIM             EQU <9>
FIRE_Y_DIM             EQU <9>  
PLAYER_FIRE_DAMAGE     EQU <1>

;
; Game Over Constants
;
GAME_OVER_X     EQU <125>
GAME_OVER_Y     EQU <300>
GAME_OVER_SIZE  EQU <10>

HS_GAME_OVER_X    EQU <100>
HS_GAME_OVER_Y    EQU <300>
HS_GAME_OVER_SIZE EQU <10>

ENTER_INITIALS_X    EQU <275>
ENTER_INITIALS_Y    EQU <400>
ENTER_INITIALS_SIZE EQU <3>

INITIALS_X    EQU <350>
INITIALS_Y    EQU <500>
INITIALS_SIZE EQU <10>

;*********************************************************
; Macros
;*********************************************************

;
; Setup sprite list, destroys RAX, RDX, R8, R10, R11
;
SETUP_SPRITE_BASIC_LIST_MACRO MACRO BasicSprite, ExplodeSprite, NumberSprites
  LOCAL SetupSpriteLoop
  MOV R8,  OFFSET SpriteBasicExplodPtr
  MOV RDX, OFFSET SpriteBasicListPtr 

  MOV R10, [SpritePointer]
  MOV R11, R10
  ADD R11, BasicSprite  * SIZEOF SPRITE_BASIC_INFORMATION
  ADD R10, ExplodeSprite * SIZEOF SPRITE_BASIC_INFORMATION

  XOR RAX, RAX
SetupSpriteLoop:
  MOV QWORD PTR [R8], R10
  MOV QWORD PTR [RDX], R11
  ADD R8, 8
  ADD RDX, 8
  ADD R11, SIZEOF SPRITE_BASIC_INFORMATION
  ADD R10, SIZEOF SPRITE_BASIC_INFORMATION

  INC RAX
  CMP RAX, NumberSprites
  JB SetupSpriteLoop
ENDM


;
; Setup sprite list, destroys RAX, RDX, R8, R10, R11
;
SETUP_SPRITE_BASIC_LIST_NO_EXPLODE_MACRO MACRO BasicSprite, NumberSprites
  LOCAL SetupSpriteLoop
  MOV R8,  OFFSET SpriteBasicExplodPtr
  MOV RDX, OFFSET SpriteBasicListPtr 

  MOV R10, [SpritePointer]
  MOV R11, R10
  ADD R11, BasicSprite  * SIZEOF SPRITE_BASIC_INFORMATION
  XOR R10, R10

  XOR RAX, RAX
SetupSpriteLoop:
  MOV QWORD PTR [R8], R10
  MOV QWORD PTR [RDX], R11
  ADD R8, 8
  ADD RDX, 8
  ADD R11, SIZEOF SPRITE_BASIC_INFORMATION

  INC RAX
  CMP RAX, NumberSprites
  JB SetupSpriteLoop
ENDM



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
                       dq  Invaders_GameOver            ; SPACE_INVADERS_END_GAME
                       dq  Invaders_EnterHiScore        ; SPACE_INVADERS_STATE_ENTER_HI_SCORE
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
    SpaceInvadersLevel1             db "LEVEL1_GIF", 0
    
	;
    ;  Player Support Structures
    ;	
    PlayerSprite                    SPRITE_STRUCT <?>
    PlayerFireActivePtr             dq ?
    PlayerFireInActivePtr           dq ?
    DeBounceMovement                dq 0                        ; I don't think this is needed.
    
	;
	; Hi Score File Name
	;
	HiScoreAppData      db 1024 DUP(?)
	HiScoreAppDataDirFormat  db "%s\\SpaceInvadersX64", 0
	HiScoreAppDataFileFormat db "%s\\SpaceInvadersX64\\SpaceInvadersx64.HS", 0
	HiScoreAppDataFileFormat2 db "%s\\SpaceInvadersx64.HS", 0
	ApplicationDataEnv        db "APPDATA",0
    ; 
    ; Active List - All active enemies are on this list.                      
    ;
    GameActiveListPtr               dq ?
    
    ;
    ; Inactive Lists - Change the constant "TOTAL_ENEMY_LISTS" if additional are added or removed.
    ;
    AstroidsSmallInActivePtr             dq ?
    AstroidsSmallPrototype               SPRITE_STRUCT <?>

    AlienFreeSmallShipsPtr               dq ?
    AlienSmallShipPrototype              SPRITE_STRUCT <?>
 
    AlienFreeLargeShipsPtr               dq ?
    AlienLargeShipPrototype              SPRITE_STRUCT <?>

    AlienFireInactivePtr                 dq ?
    AlienFirePrototype                   SPRITE_STRUCT <?>

    AlienFireInactiveLargePtr            dq ?
    AlienFireLargePrototype              SPRITE_STRUCT <?>

    SpaceMinesInactivePtr                dq ?
    SpaceMinesPrototype                  SPRITE_STRUCT <?>

    LargeAstroidInactivePtr              dq ?
    LargeAstroidPrototype                SPRITE_STRUCT <?>

    PowerUpInactivePtr                   dq ?
    PowerUpPrototype                     SPRITE_STRUCT <?>

    ShipScreenCounter                    dq 0
    ;
    ; Prototypes for populating new sprites and resetting game engine.
    ;

    

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

    AboutText                       dq 370, 325
                                    db "Programming:", 0
                                    dq 350, 350
                                    db "Toby Opferman",0
                                    dq 165, 400
                                    db "x86 64-Bit Assembly Language", 0
                                    dq 400, 450
                                    db "Graphics:", 0
                                    dq 350, 475
                                    db "The Internet", 0
                                    dq 410, 525
                                    db "Sprites:", 0
                                    dq 350, 550
                                    db "bugpixel.com", 0
                                    dq 350, 600
                                    db "Open Source:", 0
                                    dq 50, 625
                                    db "github.com/opferman/SixtyFourBits", 0									
                                    dq 0
    HighScoresText                  db "High Scores", 0
    LevelOne                        dq 370, 375
                                    db "Level One", 0
                                    dq 325, 425
                                    db "Meteor Shower",0
                                    dq 0
    HiScoreFormatString             db "%s - %I64u", 0
    HiScoreString                   db "                                      ",0
    
    LevelIntroTimer                dq LEVEL_INTRO_TIMER_SIZE
    LevelTimer                     dq ?
    HiScoreLocationPtr             dq ?

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
    PlayerLives                     dq PLAYER_START_LIVES
    PlayerScore                     dq 0
    PlayerOutputText                db "                              ",0
    PlayerHpText                    db "Hit Points: %I64u",0
    PlayerLivesText                 db "Lives: %I64u",0
    PlayerScoreFormat               db "%I64u", 0
    SpriteImageFileListAttributes   db 1, 2
    
	;
	; Game Over Data
	;
	GameOverCaptureScreen           dq ?
	GameCaptureSize                 dq ?
	GameOverText                    db "GAME OVER",0
        HighScoreText                   db "HIGH SCORE!",0
        EnterInitials                   db "Enter your initials!",0
        InitialsConst                   db "A--", 0
        InitialsEnter                   db "   ", 0
        InitialsEnterPtr                dq ?

    ;
    ; File Lists
    ;
    LoadingString       db "Loading...", 0 
    CurrentLoadingColor dd 0 
    LoadingColorsLoop   dd 0FF000h, 0FF00h, 0FFh, 0FFFFFFh, 0FF00FFh, 0FFFF00h, 0FFFFh, 0F01F0Eh

    ;
    ; Other Data Pointers
    ;
    SpritePointer       dq ?
    SpriteBasicListPtr   dq MAX_SPRITE_LIST DUP(?)
    SpriteBasicExplodPtr dq MAX_SPRITE_LIST DUP(?)

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
                        dq 30, 392, 62, 421, 8,8                                                                                  ; Space Mine 1 Exploding
                        dq 547, 395, 569, 416, 4,8                                                                                ; Space Mine 2 Exploding
                        dq 30, 392, 62, 421, 8,8                                                                                  ; Space Mine 3 Exploding
                        dq 547, 395, 569, 416, 4,8                                                                                ; Space Mine 4 Exploding

                        ;
                        ; Astroids
                        ; 70
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
   SpriteInformationEnd db 0
                        ;
                        ; Images not going to use.
                        ;
                        ;  dq 160, 485, 190, 514, 0,16
                        ;  dq  37+50+50+50+50+50+50-1, 369-31, 66+50+50+50+50+50+50-1, 401-31, 0,16  
                        ;  dq 37+50+50+50+50-1, 369-31, 66+50+50+50+50-1, 401-31, 0,16 Not going to use


    ;
    ; Game Variable Structures
    ;
    LargeMemoryAllocation    dq ?
    LargeMemoryAllocationEnd dq ?
    CurrentMemoryPtr         dq ?
    SpriteConvert      SPRITE_CONVERT     <?>
    GameEngInit        GAME_ENGINE_INIT   <?>
    Level1Screen       IMAGE_INFORMATION  <?>
    LoadingScreen      IMAGE_INFORMATION  <?>
    IntroScreen        IMAGE_INFORMATION  <?>
    MenuScreen         IMAGE_INFORMATION  <?>
    SpTitle            IMAGE_INFORMATION  <?>
    SpInvaders         IMAGE_INFORMATION  <?>
    SpGeneral          IMAGE_INFORMATION  <?>
    HiScoreListPtr     dq OFFSET HiScoreListConst
    HiScoreListConst   db "TEO", 0
	                   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0

					   
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
  MOV GAME_ENGINE_INIT.GameLoadCxt[RDX], RSI
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



;***************************************************************************************************************************************************************************
; Key Functions
;***************************************************************************************************************************************************************************

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

  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead


  MOV RDX, [PlayerSprite.SpriteMaxFire]
  CMP [PlayerSprite.SpriteFire], RDX
  JAE @AlreadyAtMaxFire

  INC [PlayerSprite.SpriteFire]

  ;
  ; Move an Inactive Fire to an Active Fire
  ;

  ;
  ; Remove from Current List and update inactive list.
  ; 
  MOV RDI, [PlayerFireInActivePtr]
  MOV R8, SPRITE_STRUCT.pNext[RDI]
  CMP R8, 0
  JE @DoNotUpdateZero
  MOV SPRITE_STRUCT.pPrev[R8], 0
@DoNotUpdateZero:
  MOV [PlayerFireInActivePtr], R8

  ;
  ; Add fire to active list.
  ;
  MOV R8, [PlayerFireActivePtr]
  MOV SPRITE_STRUCT.pNext[RDI], R8
  CMP R8, 0
  JE @DoNotUpdate
  MOV SPRITE_STRUCT.pPrev[R8], RDI
@DoNotUpdate:
  MOV SPRITE_STRUCT.pPrev[RDI], 0               ; Should already be zero anyway.
  MOV [PlayerFireActivePtr], RDI

  ;
  ; Find a Fire, Assume we are tracking properly and dont need to make a max.
  ;
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
@PlayerIsDead:
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

@GoToIntro:
  MOV [SpaceCurrentState], SPACE_INVADERS_STATE_INTRO
  MOV RCX, SPACE_INVADERS_STATE_INTRO
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
  CMP [SpaceCurrentState], SPACE_INVADERS_END_GAME
  JNE @NotOnEndGame
  
  CMP [HiScoreLocationPtr], 0
  JE @GoToIntro
   
  MOV [SpaceCurrentState], SPACE_INVADERS_STATE_ENTER_HI_SCORE
  MOV RCX, SPACE_INVADERS_STATE_ENTER_HI_SCORE
  DEBUG_FUNCTION_CALL GameEngine_ChangeState  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@NotOnEndGame:
  CMP [SpaceCurrentState], SPACE_INVADERS_STATE_ENTER_HI_SCORE
  JNE @NotHighScore

  INC QWORD PTR [InitialsEnterPtr]
  MOV RAX, [InitialsEnterPtr]
  MOV AL, BYTE PTR [RAX]

  CMP AL, 0
  JNE @NotDoneEnteringYet

  ;
  ; Done entering high score, Update Hi Score File
  ; and go to Intro.
  ;
  DEBUG_FUNCTION_CALL Invaders_UpdateHighScore
  MOV [SpaceCurrentState], SPACE_INVADERS_STATE_INTRO
  MOV RCX, SPACE_INVADERS_STATE_INTRO
  DEBUG_FUNCTION_CALL GameEngine_ChangeState
  JMP @DoneWithEnteringScore
@NotDoneEnteringYet:
  MOV RAX, [InitialsEnterPtr]
  MOV BYTE PTR [RAX], 'A'
@NotHighScore:
@DoneWithEnteringScore:
;  ADD [SpritePointer], SIZE SPRITE_BASIC_INFORMATION
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_SpaceBar, _TEXT$00


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
  ;ADD [SpritePointer], SIZE SPRITE_BASIC_INFORMATION
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
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead

  DEC [DeBounceMovement]
  CMP [DeBounceMovement], 0
  JGE @SkipUpate
  MOV [DeBounceMovement], MOVEMENT_DEBOUNCE
  MOV RDX, [PlayerSprite.SpriteVelMaxX]
  NEG RDX
  MOV [PlayerSprite.SpriteVelX], RDX
  ;CMP RDX, [PlayerSprite.SpriteVelX]
  ;JE @SkipUpate

  ;DEC [PlayerSprite.SpriteVelX]
@PlayerIsDead:
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
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead

  DEC [DeBounceMovement]
  CMP [DeBounceMovement], 0
  JGE @SkipUpate
  MOV [DeBounceMovement], MOVEMENT_DEBOUNCE
  MOV RDX, [PlayerSprite.SpriteVelMaxX]
  MOV [PlayerSprite.SpriteVelX], RDX
  ;CMP RDX, [PlayerSprite.SpriteVelX]
  ;JE @SkipUpate

  ;INC [PlayerSprite.SpriteVelX]

@SkipUpate:
@PlayerIsDead:  
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
  CMP [SpaceCurrentState], SPACE_INVADERS_STATE_ENTER_HI_SCORE
  JE @UpdateHighScore

  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead

  DEC [DeBounceMovement]
  CMP [DeBounceMovement], 0
  JGE @SkipUpate
  MOV [DeBounceMovement], MOVEMENT_DEBOUNCE
  MOV RDX, [PlayerSprite.SpriteVelMaxY]
  MOV [PlayerSprite.SpriteVelY], RDX
  ;CMP RDX, [PlayerSprite.SpriteVelY]
  ;JE @SkipUpate

  ;INC [PlayerSprite.SpriteVelY]
@PlayerIsDead:  
@SkipUpate:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@UpdateHighScore:

  MOV AL, 1
  DEBUG_FUNCTION_CALL Invaders_HiScoreEnterUpdate
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
  CMP [SpaceCurrentState], SPACE_INVADERS_STATE_ENTER_HI_SCORE
  JE @UpdateHighScore

  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead

  DEC [DeBounceMovement]
  CMP [DeBounceMovement], 0
  JGE @SkipUpate
  MOV [DeBounceMovement], MOVEMENT_DEBOUNCE
  MOV RDX, [PlayerSprite.SpriteVelMaxY]
  NEG RDX
  MOV [PlayerSprite.SpriteVelY], RDX

  ;CMP RDX, [PlayerSprite.SpriteVelY]
  ;JE @SkipUpate

  ;DEC [PlayerSprite.SpriteVelY]
@PlayerIsDead:  
@SkipUpate:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@UpdateHighScore:

  MOV AL, -1
  DEBUG_FUNCTION_CALL Invaders_HiScoreEnterUpdate  
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




;***************************************************************************************************************************************************************************
; Initialization & Support Functions
;***************************************************************************************************************************************************************************

;*********************************************************
;   Invaders_AllocateMemory
;
;        Parameters: Ignored, RDX is the size.
;
;        Return Value: Memory
;
;
;*********************************************************  
NESTED_ENTRY Invaders_AllocateMemory, _TEXT$00
.ENDPROLOG
  MOV RAX, [CurrentMemoryPtr]
  ADD [CurrentMemoryPtr], RDX

  MOV RDX, [LargeMemoryAllocationEnd]
  CMP [CurrentMemoryPtr], RDX
  JAE @OutOfMemory
  RET
@OutOfMemory:
  INT 3
  RET

NESTED_END Invaders_AllocateMemory, _TEXT$00




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
  
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL LockResource

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_LoadGifResource, _TEXT$00


;*********************************************************
;   Invaders_SetupHiScores
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_SetupHiScores, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV R8, 1024
  MOV RDX, OFFSET HiScoreAppData
  MOV RCX, OFFSET ApplicationDataEnv
  DEBUG_FUNCTION_CALL GetEnvironmentVariableA
  CMP RAX, 0
  JZ @CannotGetAppDataLocation
  
  MOV R8, OFFSET HiScoreAppData
  MOV RDX, OFFSET HiScoreAppDataFileFormat
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 03h  ; OPEN_EXISTING
  MOV R9, 0
  MOV R8, 03h   	; File Share Read / Write
  MOV RDX, 01h   ; File Read Data
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL CreateFileA
  
  CMP EAX, 0FFFFFFFFh   ; INVALID_HANDLE_VALUE
  JE @FailedToOpenAttemptToCreate
  
  ;
  ; File exists, read in the Hi-Scores
  ;
  LEA R9, STD_FUNCTION_STACK.Parameters.Param7[RSP]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 0
  MOV R8, 120				; File Size is fixed to 120 bytes.
  MOV RDX, [HiScoreListPtr]
  MOV RSI, RAX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL ReadFile
  
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL CloseHandle  
 
@CannotGetAppDataLocation: 
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@FailedToOpenAttemptToCreate:

  DEBUG_FUNCTION_CALL Invaders_CreateHiScores
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END Invaders_SetupHiScores, _TEXT$00



;*********************************************************
;   Invaders_CreateHiScores
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_CreateHiScores, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO


  MOV R8, 1024
  MOV RDX, OFFSET HiScoreAppData
  MOV RCX, OFFSET ApplicationDataEnv
  DEBUG_FUNCTION_CALL GetEnvironmentVariableA
  CMP RAX, 0
  JZ @CannotGetAppDataLocation
  
  MOV R8, OFFSET HiScoreAppData
  MOV RDX, OFFSET HiScoreAppDataDirFormat
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL sprintf
  
  XOR RDX, RDX
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL CreateDirectoryA
 
  MOV R8, OFFSET HiScoreAppData
  MOV RDX, OFFSET HiScoreAppDataFileFormat2
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 02h  ; CREATE_ALWAYS
  MOV R9, 0
  MOV R8, 3h   	; File Share Read/Write
  MOV RDX, 2h    ; File write
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL CreateFileA
  
  CMP EAX, 0FFFFFFFFh   ; INVALID_HANDLE_VALUE
  JE @FailedToOpenAttemptToCreate
  
  ;
  ; Write out the initial high scores list.
  ;
  LEA R9, STD_FUNCTION_STACK.Parameters.Param7[RSP]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 0
  MOV R8, 120				; File Size is fixed to 120 bytes.
  MOV RDX, [HiScoreListPtr]
  MOV RSI, RAX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL WriteFile
  
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL CloseHandle  
 
@CannotGetAppDataLocation:
@FailedToOpenAttemptToCreate:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END Invaders_CreateHiScores, _TEXT$00



;*********************************************************
;   Invaders_SetupPrototypes
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_SetupPrototypes, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  ;
  ; Astroids Small Prototype
  ;  
  MOV [AstroidsSmallPrototype.SpriteVelX], 0
  MOV [AstroidsSmallPrototype.SpriteVelY], 0
  MOV [AstroidsSmallPrototype.SpriteVelMaxX], 0
  MOV [AstroidsSmallPrototype.SpriteVelMaxY], ASTROIDS_MAX_VELOCITY
  MOV [AstroidsSmallPrototype.SpriteMaxFire], 0
  MOV [AstroidsSmallPrototype.SpriteBasePointsValue], ASTROID_BASE_POINTS
  MOV [AstroidsSmallPrototype.HitPoints], 0
  MOV [AstroidsSmallPrototype.MaxHp], 0
  MOV [AstroidsSmallPrototype.Damage], ASTROIDS_DAMAGE
  MOV [AstroidsSmallPrototype.KillOffscreen], 1
  MOV RCX, OFFSET Invaders_DefaultMovement
  MOV [AstroidsSmallPrototype.pfnSpriteMovementUpdate], RCX
  MOV RCX, OFFSET Invaders_DefaultAddToList
  MOV [AstroidsSmallPrototype.pfnAddedBackToList], RCX

  

  MOV [AlienSmallShipPrototype.SpriteVelX], 0
  MOV [AlienSmallShipPrototype.SpriteVelY], 0
  MOV [AlienSmallShipPrototype.SpriteVelMaxX], ALIEN_SHIP_MAX_VEL_X
  MOV [AlienSmallShipPrototype.SpriteVelMaxY], ALIEN_SHIP_MAX_VEL_Y
  MOV [AlienSmallShipPrototype.SpriteMaxFire], ALIEN_SHIP_MAX_FIRE
  MOV [AlienSmallShipPrototype.SpriteBasePointsValue], SMALL_SHIP_BASE_VALUE
  MOV [AlienSmallShipPrototype.HitPoints], 0
  MOV [AlienSmallShipPrototype.MaxHp], ALIEN_SHIP_HIT_POINTS
  MOV [AlienSmallShipPrototype.Damage], ALIEN_SHIP_DAMAGE
  MOV [AlienSmallShipPrototype.KillOffscreen], 0
  MOV RCX, OFFSET Invaders_SmallShipMovement
  MOV [AlienSmallShipPrototype.pfnSpriteMovementUpdate], RCX
  MOV RCX, OFFSET Invaders_SmallShipAddToList
  MOV [AlienSmallShipPrototype.pfnAddedBackToList], RCX

  MOV [AlienLargeShipPrototype.SpriteVelX], 0
  MOV [AlienLargeShipPrototype.SpriteVelY], 0
  MOV [AlienLargeShipPrototype.SpriteVelMaxX], ALIEN_SHIP_L_MAX_VX
  MOV [AlienLargeShipPrototype.SpriteVelMaxY], ALIEN_SHIP_L_MAX_VY
  MOV [AlienLargeShipPrototype.SpriteMaxFire], LARGE_SHIP_MAX_FIRE
  MOV [AlienLargeShipPrototype.SpriteBasePointsValue], LARGE_SHIP_BASE_VALUE
  MOV [AlienLargeShipPrototype.HitPoints], 0
  MOV [AlienLargeShipPrototype.MaxHp], LARGE_SHIP_HIT_POINTS
  MOV [AlienLargeShipPrototype.Damage], LARGE_SHIP_DAMAGE
  MOV [AlienLargeShipPrototype.KillOffscreen], 0
  MOV RCX, OFFSET Invaders_DefaultMovement
  MOV [AlienLargeShipPrototype.pfnSpriteMovementUpdate], RCX
  MOV RCX, OFFSET Invaders_DefaultAddToList
  MOV [AlienLargeShipPrototype.pfnAddedBackToList], RCX


  MOV [AlienFirePrototype.SpriteVelX], 0
  MOV [AlienFirePrototype.SpriteVelY], 0
  MOV [AlienFirePrototype.SpriteVelMaxX], ALIEN_FIRE_MAX_VEL_X
  MOV [AlienFirePrototype.SpriteVelMaxY], ALIEN_FIRE_MAX_VEL_Y
  MOV [AlienFirePrototype.SpriteMaxFire], 0
  MOV [AlienFirePrototype.SpriteBasePointsValue], ALIEN_FIRE_BASE_VALUE
  MOV [AlienFirePrototype.HitPoints], 0
  MOV [AlienFirePrototype.MaxHp], 0
  MOV [AlienFirePrototype.Damage], ALIEN_FIRE_DAMAGE
  MOV [AlienFirePrototype.KillOffscreen], 1
  MOV RCX, OFFSET Invaders_DefaultMovement
  MOV [AlienFirePrototype.pfnSpriteMovementUpdate], RCX
  MOV RCX, OFFSET Invaders_DefaultAddToList
  MOV [AlienFirePrototype.pfnAddedBackToList], RCX

  MOV [AlienFireLargePrototype.SpriteVelX], 0
  MOV [AlienFireLargePrototype.SpriteVelY], 0
  MOV [AlienFireLargePrototype.SpriteVelMaxX], ALIEN_LARGE_FIRE_MAX_VELX
  MOV [AlienFireLargePrototype.SpriteVelMaxY], ALIEN_LARGE_FIRE_MAX_VELY
  MOV [AlienFireLargePrototype.SpriteMaxFire], 3
  MOV [AlienFireLargePrototype.SpriteBasePointsValue], ALIEN_LARGE_FIRE_BASE_VALUE
  MOV [AlienFireLargePrototype.HitPoints], 0
  MOV [AlienFireLargePrototype.MaxHp], 0
  MOV [AlienFireLargePrototype.Damage], ALIEN_LARGE_FIRE_DAMAGE
  MOV [AlienFireLargePrototype.KillOffscreen], 1
  MOV RCX, OFFSET Invaders_DefaultMovement
  MOV [AlienFireLargePrototype.pfnSpriteMovementUpdate], RCX
  MOV RCX, OFFSET Invaders_DefaultAddToList
  MOV [AlienFireLargePrototype.pfnAddedBackToList], RCX


  MOV [SpaceMinesPrototype.SpriteVelX], 0
  MOV [SpaceMinesPrototype.SpriteVelY], 0
  MOV [SpaceMinesPrototype.SpriteVelMaxX], SPACE_MINES_MAX_VEL_X
  MOV [SpaceMinesPrototype.SpriteVelMaxY], SPACE_MINES_MAX_VEL_Y
  MOV [SpaceMinesPrototype.SpriteMaxFire], 3
  MOV [SpaceMinesPrototype.SpriteBasePointsValue], SPACE_MINES_BASE_POINTS
  MOV [SpaceMinesPrototype.HitPoints], 0
  MOV [SpaceMinesPrototype.MaxHp], 0
  MOV [SpaceMinesPrototype.Damage], SPACE_MINES_DAMAGE
  MOV [SpaceMinesPrototype.KillOffscreen], 1
  MOV RCX, OFFSET Invaders_DefaultMovement
  MOV [SpaceMinesPrototype.pfnSpriteMovementUpdate], RCX
  MOV RCX, OFFSET Invaders_DefaultAddToList
  MOV [SpaceMinesPrototype.pfnAddedBackToList], RCX

  MOV [LargeAstroidPrototype.SpriteVelX], 0
  MOV [LargeAstroidPrototype.SpriteVelY], 0
  MOV [LargeAstroidPrototype.SpriteVelMaxX], LARGE_ASTROID_MAX_VEL_X
  MOV [LargeAstroidPrototype.SpriteVelMaxY], LARGE_ASTROID_MAX_VEL_Y
  MOV [LargeAstroidPrototype.SpriteMaxFire], 0
  MOV [LargeAstroidPrototype.SpriteBasePointsValue], LARGE_ASTROID_BASE_VALUE
  MOV [LargeAstroidPrototype.HitPoints], 0
  MOV [LargeAstroidPrototype.MaxHp], 0
  MOV [LargeAstroidPrototype.Damage], LARGE_ASTROID_DAMAGE
  MOV [LargeAstroidPrototype.KillOffscreen], 1
  MOV RCX, OFFSET Invaders_DefaultMovement
  MOV [LargeAstroidPrototype.pfnSpriteMovementUpdate], RCX
  MOV RCX, OFFSET Invaders_DefaultAddToList
  MOV [LargeAstroidPrototype.pfnAddedBackToList], RCX


  MOV [PowerUpPrototype.SpriteVelX], 0
  MOV [PowerUpPrototype.SpriteVelY], 0
  MOV [PowerUpPrototype.SpriteVelMaxX], POWER_UP_MAX_VEL_X
  MOV [PowerUpPrototype.SpriteVelMaxY], POWER_UP_MAX_VEL_Y
  MOV [PowerUpPrototype.SpriteMaxFire], 3
  MOV [PowerUpPrototype.SpriteBasePointsValue], 0
  MOV [PowerUpPrototype.HitPoints], 0
  MOV [PowerUpPrototype.MaxHp], 0
  MOV [PowerUpPrototype.Damage], POWER_UP_SPECIAL_DAMAGE
  MOV [PowerUpPrototype.KillOffscreen], 1
  MOV RCX, OFFSET Invaders_DefaultMovement
  MOV [PowerUpPrototype.pfnSpriteMovementUpdate], RCX
  MOV RCX, OFFSET Invaders_DefaultAddToList
  MOV [PowerUpPrototype.pfnAddedBackToList], RCX

  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_SetupPrototypes, _TEXT$00



;*********************************************************
;   Invaders_AssociateImageAndExplosion
;
;        Parameters: Sprite, Basic Info Sprite, Basic Info Explode
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_AssociateImageAndExplosion, _TEXT$00
.ENDPROLOG
  MOV SPRITE_STRUCT.ImagePointer[RCX], RDX
  MOV R10, SPRITE_BASIC_INFORMATION.SpriteHeight[RDX]
  MOV SPRITE_STRUCT.SpriteHeight[RCX], R10
  MOV R10, SPRITE_BASIC_INFORMATION.SpriteWidth[RDX]
  MOV SPRITE_STRUCT.SpriteWidth[RCX], R10
  RET
NESTED_END Invaders_AssociateImageAndExplosion, _TEXT$00




;*********************************************************
;   Invaders_AllocateSpriteList
;
;        Parameters: Inactive List Offset, Number of Sprites
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_AllocateSpriteList, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RAX, [CurrentMemoryPtr]
  MOV [RCX], RAX                        ; Start allocation of list.

  XOR R9, R9                            ; Previous Sprite
  XOR R8, R8                            ; Sprite Counter
@SetupSpriteList:
  MOV RDI, RAX                          ; Current Sprite Update
  ADD RAX, SIZE SPRITE_STRUCT           ; Next Sprite
  MOV SPRITE_STRUCT.pPrev[RDI], R9      ; Set Up Previous Sprite.
  MOV R9, RDI                           ; This is now the previous sprite.
  MOV SPRITE_STRUCT.pNext[RDI], RAX
  MOV SPRITE_STRUCT.SpriteInactiveListPtr[RDI], RCX
  INC R8
  CMP R8, RDX
  JB @SetupSpriteList
  
  ;
  ; Update Last Entry
  ;
  MOV RDI, RAX                          ; Current Sprite Update
  ADD RAX, SIZE SPRITE_STRUCT           ; Next Sprite
  MOV SPRITE_STRUCT.pPrev[RDI], R9      ; Set Up Previous Sprite.
  MOV SPRITE_STRUCT.pNext[RDI], 0
  MOV SPRITE_STRUCT.SpriteInactiveListPtr[RDI], RCX

  ;
  ; Set the current memory pointer and verify we are not out of memory.
  ;
  MOV [CurrentMemoryPtr], RAX
  MOV RDX, [LargeMemoryAllocationEnd]
  CMP [CurrentMemoryPtr], RDX
  JAE @OutOfMemory

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@OutOfMemory:
  INT 3
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET


NESTED_END Invaders_AllocateSpriteList, _TEXT$00

;*********************************************************
;   Invaders_SetupMemoryAllocations
;
;        Parameters: None
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Invaders_SetupMemoryAllocations, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
   
  MOV RDX, LARGE_GAME_ALLOCATION
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  CMP RAX, 0
  JE @Failure
  MOV [LargeMemoryAllocation], RAX
  MOV [LargeMemoryAllocationEnd], RAX
  ADD [LargeMemoryAllocationEnd],LARGE_GAME_ALLOCATION

  ;
  ; Setup data structure allocations.
  ;
  MOV [SpritePointer], RAX
  ADD RAX, NUMBER_OF_SPRITES * SIZE SPRITE_BASIC_INFORMATION

  ;
  ; Setup Player Fire
  ;
  MOV [PlayerFireActivePtr], 0
  MOV [PlayerFireInActivePtr], RAX
  MOV RDI, RAX
  ADD RAX, SIZE SPRITE_STRUCT
  XOR R8, R8
  MOV SPRITE_STRUCT.pPrev[RDI], 0

@SetupPlayerFire:
  MOV SPRITE_STRUCT.pNext[RDI], RAX
  MOV SPRITE_STRUCT.pPrev[RAX], RDI
  MOV RDI, RAX
  ADD RAX, SIZE SPRITE_STRUCT
  INC R8
  CMP R8, MAXIMUM_PLAYER_FIRE
  JB @SetupPlayerFire
  MOV SPRITE_STRUCT.pNext[RDI], 0

  ;
  ;
  ;  Create the initial list for each type of sprite.
  ;
  ; 
  MOV [CurrentMemoryPtr], RAX

  ;
  ; Initialize Small Alien Ships
  ;
  MOV RDX, SMALL_ALIEN_SHIPS_MAX
  MOV RCX, OFFSET AlienFreeSmallShipsPtr
  DEBUG_FUNCTION_CALL Invaders_AllocateSpriteList

  ;
  ; Initialize Large Alien Ships
  ;
  MOV RDX, LARGE_ALIEN_SHIPS_MAX
  MOV RCX, OFFSET AlienFreeLargeShipsPtr
  DEBUG_FUNCTION_CALL Invaders_AllocateSpriteList

  ;
  ; Initialize Small Astroids
  ;
  MOV RDX, ASTROIDS_SMALL_MAX
  MOV RCX, OFFSET AstroidsSmallInActivePtr
  DEBUG_FUNCTION_CALL Invaders_AllocateSpriteList

  ;
  ; Initialize Alien Fire
  ;
  MOV RDX, ALIEN_FIRE_MAX
  MOV RCX, OFFSET AlienFireInactivePtr
  DEBUG_FUNCTION_CALL Invaders_AllocateSpriteList

  ;
  ; Initialize Space Mines
  ;
  MOV RDX, SPACE_MINES_MAX
  MOV RCX, OFFSET SpaceMinesInactivePtr
  DEBUG_FUNCTION_CALL Invaders_AllocateSpriteList

  ;
  ; Initialize Large Astroids
  ;
  MOV RDX, ASTROIDS_LARGE_MAX
  MOV RCX, OFFSET LargeAstroidInactivePtr
  DEBUG_FUNCTION_CALL Invaders_AllocateSpriteList

  ;
  ; Initialize Power UPs
  ;
  MOV RDX, POWER_UPS_MAX
  MOV RCX, OFFSET PowerUpInactivePtr
  DEBUG_FUNCTION_CALL Invaders_AllocateSpriteList


  ;
  ; Initialize Large Alien Fire
  ;
  MOV RDX, ALIEN_FIRE_LARGE_MAX
  MOV RCX, OFFSET AlienFireInactiveLargePtr
  DEBUG_FUNCTION_CALL Invaders_AllocateSpriteList

  ;
  ; Active Game Ptr is 0
  ;
  MOV [GameActiveListPtr], 0

  MOV EAX, 1
@Failure:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_SetupMemoryAllocations, _TEXT$00



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
  MOV RSI, RCX
  
  ;
  ; Large Memory Allocation
  ;
  DEBUG_FUNCTION_CALL Invaders_SetupMemoryAllocations
  CMP RAX, 0
  JE @FailureExit
  
  ;
  ; Game Over Capture Screen; create a buffer
  ; as large as the screen to capture it.
  ;
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  XOR RDX, RDX
  MUL MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  SHL RAX, 2
  
  MOV [GameCaptureSize], RAX
  MOV RDX, RAX
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL Invaders_AllocateMemory
  CMP RAX, 0
  JE @FailureExit
  
  MOV [GameOverCaptureScreen], RAX
  
  ;
  ; Determine Hi Scores
  ;
  DEBUG_FUNCTION_CALL Invaders_SetupHiScores
  
  ;
  ;  Load GIFs
  ;
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

  MOV RCX, OFFSET SpaceInvadersLevel1
  DEBUG_FUNCTION_CALL Invaders_LoadGifResource
  MOV RCX, RAX

  MOV RDX, OFFSET Level1Screen
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory
  CMP RAX, 0
  JE @FailureExit

  MOV [Level1Screen.StartX], 0
  MOV [Level1Screen.StartY], 0
  MOV [Level1Screen.InflateCountDown], 0
  MOV [Level1Screen.InflateCountDownMax], 0
  PXOR XMM0, XMM0
  MOVSD [Level1Screen.IncrementX], XMM0
  MOVSD [Level1Screen.IncrementY], XMM0

  

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

  DEBUG_FUNCTION_CALL Invaders_SetupPrototypes

  ;
  ; Setup Small Astroids, 2 sprites and no explosion graphics.
  ;
  SETUP_SPRITE_BASIC_LIST_NO_EXPLODE_MACRO ASTROID_BASIC_SPRITE, ASTROID_BASIC_SPRITE_NUM

  MOV R9, ASTROID_BASIC_SPRITE_NUM
  MOV R8, OFFSET SpriteBasicExplodPtr
  MOV RDX, OFFSET SpriteBasicListPtr 
  MOV RCX, OFFSET AstroidsSmallInActivePtr
  DEBUG_FUNCTION_CALL Invaders_SetupSpriteImages

  ;
  ; Setup Small Alien Ships
  ;
  SETUP_SPRITE_BASIC_LIST_MACRO SMALL_ALIEN_BASIC_SPRITE, SMALL_ALIEN_BASIC_SPRITE_EXPLODE, SMALL_ALIEN_BASIC_SPRITE_NUM

  MOV R9, SMALL_ALIEN_BASIC_SPRITE_NUM                            
  MOV R8, OFFSET SpriteBasicExplodPtr
  MOV RDX, OFFSET SpriteBasicListPtr 
  MOV RCX, OFFSET AlienFreeSmallShipsPtr
  DEBUG_FUNCTION_CALL Invaders_SetupSpriteImages

  ;
  ; Setup Large Alien Ships
  ;
  SETUP_SPRITE_BASIC_LIST_MACRO LARGE_ALIEN_BASIC_SPRITE, LARGE_ALIEN_BASIC_SPRITE_EXPLODE, LARGE_ALIEN_BASIC_SPRITE_NUM

  MOV R9, LARGE_ALIEN_BASIC_SPRITE_NUM
  MOV R8, OFFSET SpriteBasicExplodPtr
  MOV RDX, OFFSET SpriteBasicListPtr 
  MOV RCX, OFFSET AlienFreeLargeShipsPtr
  DEBUG_FUNCTION_CALL Invaders_SetupSpriteImages


  ;
  ; Setup Alien Fire
  ;
  SETUP_SPRITE_BASIC_LIST_MACRO ALIEN_FIRE_BASIC_SPRITE, ALIEN_FIRE_BASIC_SPRITE_EXPLODE, ALIEN_FIRE_BASIC_SPRITE_NUM

  MOV R9,  ALIEN_FIRE_BASIC_SPRITE_NUM                           
  MOV R8, OFFSET SpriteBasicExplodPtr
  MOV RDX, OFFSET SpriteBasicListPtr 
  MOV RCX, OFFSET AlienFireInactivePtr
  DEBUG_FUNCTION_CALL Invaders_SetupSpriteImages


  ;
  ; Setup  Space Mines
  ;
  SETUP_SPRITE_BASIC_LIST_MACRO SPACE_MINE_BASIC_SPRITE, SPACE_MINE_BASIC_SPRITE_EXPLODE, SPACE_MINE_BASIC_SPRITE_NUM

  MOV R9, SPACE_MINE_BASIC_SPRITE_NUM                             
  MOV R8, OFFSET SpriteBasicExplodPtr
  MOV RDX, OFFSET SpriteBasicListPtr 
  MOV RCX, OFFSET SpaceMinesInactivePtr
  DEBUG_FUNCTION_CALL Invaders_SetupSpriteImages

  ;
  ; Setup Large Astroids
  ;
  SETUP_SPRITE_BASIC_LIST_MACRO LARGE_ASTROID_BASIC_SPRITE, LARGE_ASTROID_BASIC_SPRITE_EXPLODE, LARGE_ASTROID_BASIC_SPRITE_NUM

  MOV R9, LARGE_ASTROID_BASIC_SPRITE_NUM                           
  MOV R8, OFFSET SpriteBasicExplodPtr
  MOV RDX, OFFSET SpriteBasicListPtr 
  MOV RCX, OFFSET LargeAstroidInactivePtr
  DEBUG_FUNCTION_CALL Invaders_SetupSpriteImages

  ;
  ; Setup Power UPs
  ;
  SETUP_SPRITE_BASIC_LIST_MACRO POWER_UPS_BASIC_SPRITE, POWER_UPS_BASIC_SPRITE_EXPLODE, POWER_UPS_BASIC_SPRITE_NUM

  MOV R9, POWER_UPS_BASIC_SPRITE_NUM                             
  MOV R8, OFFSET SpriteBasicExplodPtr
  MOV RDX, OFFSET SpriteBasicListPtr 
  MOV RCX, OFFSET PowerUpInactivePtr
  DEBUG_FUNCTION_CALL Invaders_SetupSpriteImages

  ;
  ; Setup Large Alien Fire
  ;
  SETUP_SPRITE_BASIC_LIST_MACRO ALIEN_FIRE_BASIC_SPRITE, ALIEN_FIRE_BASIC_SPRITE_EXPLODE, ALIEN_FIRE_BASIC_SPRITE_NUM

  MOV R9, ALIEN_FIRE_BASIC_SPRITE_NUM                            
  MOV R8, OFFSET SpriteBasicExplodPtr
  MOV RDX, OFFSET SpriteBasicListPtr 
  MOV RCX, OFFSET AlienFireInactiveLargePtr
  DEBUG_FUNCTION_CALL Invaders_SetupSpriteImages


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
;   Invaders_SetupSpriteImages
;
;        Parameters: Offset Inactive List Ptr, List of Sprites to distribute, List of Exploisions to distribute, Number of Sprites in distribute list.
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_SetupSpriteImages, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  ;
  ; Create the Base
  ;
  MOV R13, RDX
  MOV R14, R8
  MOV R15, R9
  
  ;   
  ;  Initialize
  ;
  MOV RDI, R13
  MOV RSI, R14
  MOV R12, QWORD PTR [RCX]
  XOR RBX, RBX

@SetupSpriteImages:
  
  MOV RCX, QWORD PTR [RDI]
  DEBUG_FUNCTION_CALL Invaders_DuplicateBasicSprite

  MOV SPRITE_STRUCT.ImagePointer[R12], RAX
  MOV R10, SPRITE_BASIC_INFORMATION.SpriteHeight[RAX]
  MOV SPRITE_STRUCT.SpriteHeight[R12], R10
  MOV R10, SPRITE_BASIC_INFORMATION.SpriteWidth[RAX]
  MOV SPRITE_STRUCT.SpriteWidth[R12], R10

  XOR RAX, RAX
  CMP QWORD PTR [RSI], 0
  JE @NoExplosions

  MOV RCX, QWORD PTR [RSI]
  DEBUG_FUNCTION_CALL Invaders_DuplicateBasicSprite
@NoExplosions:

  MOV SPRITE_STRUCT.ExplodePointer[R12], RAX
  MOV R12, SPRITE_STRUCT.pNext[R12]
  INC RBX
  ADD RDI, 8
  ADD RSI, 8

  CMP RBX, R15
  JB @CheckEndOfList
  MOV RDI, R13
  MOV RSI, R14
  XOR RBX, RBX
@CheckEndOfList:
  CMP R12, 0
  JNE @SetupSpriteImages


  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_SetupSpriteImages, _TEXT$00




;*********************************************************
;   Invaders_DuplicateBasicSprite
;
;        Parameters: Basic Sprite Information
;
;        Return Value: New Basic Sprite Information
;
;
;*********************************************************  
NESTED_ENTRY Invaders_DuplicateBasicSprite, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
 
  MOV RDX, SIZEOF SPRITE_BASIC_INFORMATION
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL Invaders_AllocateMemory 
  CMP RAX, 0
  JZ @Failure

  MOV RDX, SPRITE_BASIC_INFORMATION.SpriteOffsets[RSI]           
  MOV SPRITE_BASIC_INFORMATION.SpriteOffsets[RAX], RDX           

  MOV RDX, SPRITE_BASIC_INFORMATION.NumberOfSprites[RSI]
  MOV SPRITE_BASIC_INFORMATION.NumberOfSprites[RAX], RDX         
  
  MOV SPRITE_BASIC_INFORMATION.CurrentSprite[RAX], 0           

  MOV RDX, SPRITE_BASIC_INFORMATION.SpriteFrameNum[RSI]          
  MOV SPRITE_BASIC_INFORMATION.SpriteFrameNum[RAX], RDX          

  MOV RDX, SPRITE_BASIC_INFORMATION.SpriteMaxFrames[RSI]         
  MOV SPRITE_BASIC_INFORMATION.SpriteMaxFrames[RAX], RDX         

  MOV RDX, SPRITE_BASIC_INFORMATION.SpriteWidth[RSI]             
  MOV SPRITE_BASIC_INFORMATION.SpriteWidth[RAX], RDX             

  MOV RDX, SPRITE_BASIC_INFORMATION.SpriteHeight[RSI]          
  MOV SPRITE_BASIC_INFORMATION.SpriteHeight[RAX], RDX          

  MOV EDX, SPRITE_BASIC_INFORMATION.SpriteTransparentColor[RSI]
  MOV SPRITE_BASIC_INFORMATION.SpriteTransparentColor[RAX], EDX

;
; No reason to re-allocate the sprite memory itself, the context is enough
;
  
  MOV RDX, SPRITE_BASIC_INFORMATION.SpriteListPtr[RSI]   

  MOV SPRITE_BASIC_INFORMATION.SpriteListPtr[RAX], RDX
  MOV SPRITE_BASIC_INFORMATION.CurrSpritePtr[RAX], RDX

@Failure:
@Success:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_DuplicateBasicSprite, _TEXT$00





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
  MOV RBX, [SpritePointer]
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




;***************************************************************************************************************************************************************************
; Game Reset Functions
;***************************************************************************************************************************************************************************



;*********************************************************
;   Invaders_EmptyActiveList
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_EmptyActiveList, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  MOV RDI, [GameActiveListPtr]
  MOV [GameActiveListPtr], 0
  CMP RDI, 0
  JE @ActiveListEmpty

@InitActiveListToInactive:
  MOV SPRITE_STRUCT.SpriteAlive[RDI], 0

  ;
  ; Notify adding back to list.
  ;
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL SPRITE_STRUCT.pfnAddedBackToList[RDI]

  ;
  ; Add back to the inactive list
  ;
  MOV R11, SPRITE_STRUCT.SpriteInactiveListPtr[RDI]
  MOV R10, [R11]

  MOV R8, SPRITE_STRUCT.pNext[RDI]
  MOV SPRITE_STRUCT.pNext[RDI], R10
  MOV SPRITE_STRUCT.pPrev[RDI], 0
  CMP R10, 0
  JE @DoNotUpdate
  MOV SPRITE_STRUCT.pPrev[R10], RDI
@DoNotUpdate:
  MOV [R11], RDI

  MOV RDI, R8
  CMP RDI, 0
  JNE @InitActiveListToInactive
@ActiveListEmpty:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_EmptyActiveList, _TEXT$00


;*********************************************************
;   Invaders_ResetActiveInactiveSprites
;
;        Parameters: Inactive List Pointer, Prototype
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_ResetActiveInactiveSprites, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  ;
  ; Inactive list can't be empty.
  ;
  MOV R9, RCX
  MOV RDI, [R9]
  MOV R8, RDX

@InitSpriteList:
  MOV SPRITE_STRUCT.SpriteAlive[RDI], 0
  MOV SPRITE_STRUCT.SpriteX[RDI], 0
  MOV SPRITE_STRUCT.SpriteY[RDI], 0

  MOV R9, SPRITE_STRUCT.SpriteVelY[R8]
  MOV SPRITE_STRUCT.SpriteVelY[RDI], R9

  MOV R9, SPRITE_STRUCT.SpriteBasePointsValue[R8]
  MOV SPRITE_STRUCT.SpriteBasePointsValue[RDI], R9

  MOV R9, SPRITE_STRUCT.SpriteVelY[R8]
  MOV SPRITE_STRUCT.SpriteVelY[RDI], R9

  MOV R9, SPRITE_STRUCT.KillOffscreen[R8]
  MOV SPRITE_STRUCT.KillOffscreen[RDI], R9

  MOV R9, SPRITE_STRUCT.SpriteVelMaxX[R8]
  MOV SPRITE_STRUCT.SpriteVelMaxX[RDI], R9

  MOV R9, SPRITE_STRUCT.SpriteVelMaxY[R8]
  MOV SPRITE_STRUCT.SpriteVelMaxY[RDI], R9
  MOV SPRITE_STRUCT.SpriteFire[RDI], 0

  MOV R9, SPRITE_STRUCT.SpriteMaxFire[R8]
  MOV SPRITE_STRUCT.SpriteMaxFire[RDI], R9

  MOV R9, SPRITE_STRUCT.MaxHp[R8]
  MOV SPRITE_STRUCT.HitPoints[RDI], R9

  MOV R9, SPRITE_STRUCT.MaxHp[R8]
  MOV SPRITE_STRUCT.MaxHp[RDI], R9


  MOV R9, SPRITE_STRUCT.Damage[R8]
  MOV SPRITE_STRUCT.Damage[RDI], R9

  MOV R9, SPRITE_STRUCT.pfnSpriteMovementUpdate[R8]
  MOV SPRITE_STRUCT.pfnSpriteMovementUpdate[RDI], R9

  MOV R9, SPRITE_STRUCT.pfnAddedBackToList[R8]
  MOV SPRITE_STRUCT.pfnAddedBackToList[RDI], R9
  
  MOV RDI, SPRITE_STRUCT.pNext[RDI]
  CMP RDI, 0
  JNE @InitSpriteList
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_ResetActiveInactiveSprites, _TEXT$00



;*********************************************************
;   Invaders_ResetGame
;                This will reset the game for level 1.
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
  MOV [PlayerScore], 0
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
  MOV [PlayerLives], PLAYER_START_LIVES     

  MOV RDI, [PlayerFireInActivePtr]
  CMP RDI, 0
  JE @NoInactiveList
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
  
  MOV RDI, SPRITE_STRUCT.pNext[RDI]
  CMP RDI, 0
  JNE @InitPlayerFire
  
 @NoInactiveList:
  MOV RDI, [PlayerFireActivePtr]
  MOV [PlayerFireActivePtr], 0

  CMP RDI, 0
  JE @ListEmpty

@InitPlayerFirePreviouslyActive:

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
  
  ;
  ; Add the fire to the inactive list.
  ;
  MOV R8, SPRITE_STRUCT.pNext[RDI]


  MOV R9, [PlayerFireInActivePtr]
  MOV SPRITE_STRUCT.pNext[RDI], R9
  MOV SPRITE_STRUCT.pPrev[RDI], 0
  CMP R9, 0
  JE @DoNotUpdate
  MOV SPRITE_STRUCT.pPrev[R9], RDI
@DoNotUpdate:
  MOV [PlayerFireInActivePtr], RDI

  MOV RDI, R8
  CMP RDI, 0
  JNE @InitPlayerFirePreviouslyActive
@ListEmpty:
  
  ;
  ;  Empty the active list.
  ;
  DEBUG_FUNCTION_CALL Invaders_EmptyActiveList

  ;
  ; To allow for later levels to change the prototypes, Re-Initialize them now.
  ;
  DEBUG_FUNCTION_CALL Invaders_SetupPrototypes

  ;
  ; Initialize All of the Inactive Lists.
  ;
  XOR R12, R12
  MOV RSI, OFFSET AstroidsSmallInActivePtr
@ReInitializeEnemyListsWithPrototype:
  MOV RCX, RSI
  ADD RSI, 8
  MOV RDX, RSI
  DEBUG_FUNCTION_CALL Invaders_ResetActiveInactiveSprites

  ADD RSI, SIZEOF SPRITE_STRUCT
  INC R12
  CMP R12, TOTAL_ENEMY_LISTS
  JB @ReInitializeEnemyListsWithPrototype

  ;
  ; Set the Level Intro Timer.
  ;
  MOV [LevelIntroTimer], LEVEL_INTRO_TIMER_SIZE
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_ResetGame, _TEXT$00



;*********************************************************
;   Invaders_ResetSpriteBasicInformation
;
;        Parameters: Resource Name
;
;        Return Value: Memory
;
;
;*********************************************************  
NESTED_ENTRY Invaders_ResetSpriteBasicInformation, _TEXT$00
.ENDPROLOG
  MOV RDX, SPRITE_BASIC_INFORMATION.SpriteListPtr[RCX]
  MOV SPRITE_BASIC_INFORMATION.CurrSpritePtr[RCX], RDX
  MOV SPRITE_BASIC_INFORMATION.CurrentSprite[RCX], 0
  MOV SPRITE_BASIC_INFORMATION.SpriteFrameNum[RCX], 0
  RET
NESTED_END Invaders_ResetSpriteBasicInformation, _TEXT$00


;***************************************************************************************************************************************************************************
; Graphics Support Functions
;***************************************************************************************************************************************************************************

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



;***************************************************************************************************************************************************************************
; Non-Level Screens
;***************************************************************************************************************************************************************************


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
;   Invaders_GameOver
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_GameOver, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL Invaders_ScreenBlast
  
  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET SpTitle
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  ;
  ; Display Game Over Title with random color
  ;
  DEBUG_FUNCTION_CALL Math_Rand
  MOV ECX, EAX
  SHR EAX, 8
  SHL ECX, 8
  OR EAX, ECX
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RAX
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], GAME_OVER_SIZE
  MOV R9, GAME_OVER_Y
  MOV R8, GAME_OVER_X
  MOV RDX, OFFSET GameOverText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [SpaceCurrentState], SPACE_INVADERS_END_GAME
  MOV RAX, SPACE_INVADERS_END_GAME
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_GameOver, _TEXT$00


;*********************************************************
;   Invaders_EnterHiScore
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_EnterHiScore, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL Invaders_ScreenBlast
  
  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET SpTitle
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  ;
  ; Display High Score with random color
  ;
  DEBUG_FUNCTION_CALL Math_Rand
  MOV ECX, EAX
  SHR EAX, 8
  SHL ECX, 8
  OR EAX, ECX
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RAX
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], HS_GAME_OVER_SIZE
  MOV R9, HS_GAME_OVER_Y
  MOV R8, HS_GAME_OVER_X
  MOV RDX, OFFSET HighScoreText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], ENTER_INITIALS_SIZE
  MOV R9, ENTER_INITIALS_Y
  MOV R8, ENTER_INITIALS_X
  MOV RDX, OFFSET EnterInitials
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord


  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INITIALS_SIZE
  MOV R9, INITIALS_Y
  MOV R8, INITIALS_X
  MOV RDX, OFFSET InitialsEnter
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [SpaceCurrentState], SPACE_INVADERS_STATE_ENTER_HI_SCORE
  MOV RAX, SPACE_INVADERS_STATE_ENTER_HI_SCORE
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_EnterHiScore, _TEXT$00




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

  ;
  ; Display Hi-Score Title with random color
  ;
  DEBUG_FUNCTION_CALL Math_Rand
  MOV ECX, EAX
  SHR EAX, 8
  SHL ECX, 8
  OR EAX, ECX
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RAX
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], HI_SCORE_TITLE_SIZE
  MOV R9, HI_SCORE_TITLE_Y
  MOV R8, HI_SCORE_TITLE_X
  MOV RDX, OFFSET HighScoresText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV RDI, [HiScoreListPtr]
  XOR RBX, RBX
  MOV R12, HI_SCORE_Y_START
@DisplayHighScoreLoop:
  
  MOV R9, QWORD PTR [RDI+4]
  MOV R8, RDI
  MOV RDX, OFFSET HiScoreFormatString
  MOV RCX, OFFSET HiScoreString
  DEBUG_FUNCTION_CALL sprintf
  ADD RDI, 4+8		; 3 Initials + NULL + QWORD
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], HI_SCORE_FONT_SIZE
  MOV R9, R12
  ADD R12, HI_SCORE_Y_INC
  MOV R8, HI_SCORE_X
  MOV RDX, OFFSET HiScoreString
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord
  
  INC RBX
  CMP RBX, MAX_HI_SCORES
  JB @DisplayHighScoreLoop

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


;***************************************************************************************************************************************************************************
; Levels
;***************************************************************************************************************************************************************************

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
  MOV RDI, RDX
  ;
  ; Level Background
  ;
  MOV RDX, OFFSET Level1Screen
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  ;
  ; Level Introduction Timer
  ;
  CMP [LevelIntroTimer], 0
  JE @LevelAction

  DEC [LevelIntroTimer]

  MOV R8, 20
  MOV RDX, OFFSET LevelOne
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DisplayScrollText
  JMP @SkipLevelAction

@LevelAction:
  ;
  ; Level Action - Section One - New Enemies
  ;
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_RandomAstroids

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_RandomShips

  ;
  ;  Level Action - Section Two - Collision Detection
  ;

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_CollisionPlayerFire

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_CollisionPlayer

  ;
  ; Level Action - Display Sprites and Graphics
  ;  
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DisplayPlayer
  MOV R12, RAX
  
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DisplayPlayerFire

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DisplayGameGraphics
  

  
  CMP R12, 0
  JE @GameStillGoing
  
  ;
  ; Reset Level Time!
  ;
  DEC [PlayerLives]
  DEBUG_FUNCTION_CALL Invaders_LevelOneReset
  
@GameStillGoing:

  ;
  ;  Display the Game Panel After Updating Lives!
  ;
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DisplayGamePanel

@SkipLevelAction:
  CMP [PlayerLives], 0
  JA @ContinueGoing
  
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL Invaders_ScreenCapture

  DEBUG_FUNCTION_CALL Invaders_CheckHiScores  ; Easier to just update here.

  MOV [SpaceCurrentState], SPACE_INVADERS_END_GAME
  MOV RAX, [SpaceCurrentState]
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@ContinueGoing:
  MOV [SpaceCurrentState], SPACE_INVADERS_LEVEL_ONE
  MOV RAX, [SpaceCurrentState]
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_LevelOne, _TEXT$00


;***************************************************************************************************************************************************************************
; Generic Support Functions
;***************************************************************************************************************************************************************************


  
;*********************************************************
;   Invaders_UpdateHighScore
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_UpdateHighScore, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO 

  ;
  ; No Error Checking, assume this is all correct.
  ;
  MOV RDX, [HiScoreListPtr]
  ADD RDX, (120-12)          ; Set it to the last entry

@MoveAllScores:
  CMP RDX, [HiScoreLocationPtr]
  JE @FoundLocation
  
  MOV RAX, QWORD PTR [RDX-12]
  MOV QWORD PTR [RDX], RAX
  MOV EAX, DWORD PTR [RDX-4]
  MOV DWORD PTR [RDX+8], EAX
  SUB RDX, 12
  JMP @MoveAllScores

@FoundLocation:
  ;
  ; Update Hi-Scores
  ;
  MOV RCX, OFFSET InitialsEnter
  MOV EAX, DWORD PTR [RCX]
  MOV DWORD PTR [RDX], EAX
  MOV RCX, [PlayerScore]
  MOV QWORD PTR [RDX + 4], RCX
  MOV [InitialsEnterPtr], RCX
        
  MOV [HiScoreLocationPtr], 0
  
  ;  
  ; Save the scores in the file.
  ;
  DEBUG_FUNCTION_CALL Invaders_UpdateHiScores

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END Invaders_UpdateHighScore, _TEXT$00


;*********************************************************
;   Invaders_HiScoreEnterUpdate
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_HiScoreEnterUpdate, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO 

  CMP [SpaceCurrentState], SPACE_INVADERS_STATE_ENTER_HI_SCORE
  JNE @NoScoreUpdate

  MOV RCX, [InitialsEnterPtr]
  ADD BYTE PTR [RCX], AL

  CMP BYTE PTR [RCX], 'A'
  JAE @CheckAbove

  MOV BYTE PTR [RCX], 'Z'

@CheckAbove:
  CMP BYTE PTR [RCX], 'Z'
  JBE @CompleteandDone

  MOV BYTE PTR [RCX], 'A'

@CompleteandDone:
@NoScoreUpdate:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END Invaders_HiScoreEnterUpdate, _TEXT$00


;*********************************************************
;   Invaders_ScreenCapture
;
;        Parameters: Double Buffer
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_ScreenCapture, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO 
  MOV RSI, RCX
  MOV RDI, [GameOverCaptureScreen]
  MOV RCX, [GameCaptureSize]
  TEST CL, 7
  JZ @QwordCapture

  TEST CL, 3
  JZ @DwordCapture

  TEST CL, 1
  JZ @WordCapture

  REP MOVSB
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  

@WordCapture:
  SHR RCX, 1
  REP MOVSW
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  

  
@DwordCapture:
  SHR RCX, 2
  REP MOVSD
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  
@QwordCapture:
  SHR RCX, 3
  REP MOVSQ
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END Invaders_ScreenCapture, _TEXT$00


;*********************************************************
;   Invaders_ScreenBlast
;
;        Parameters: Double Buffer
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_ScreenBlast, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX
  MOV RSI, [GameOverCaptureScreen]
  MOV RCX, [GameCaptureSize]
  TEST CL, 7
  JZ @QwordCapture

  TEST CL, 3
  JZ @DwordCapture

  TEST CL, 1
  JZ @WordCapture

  REP MOVSB
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  

@WordCapture:
  SHR RCX, 1
  REP MOVSW
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  

  
@DwordCapture:
  SHR RCX, 2
  REP MOVSD
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  
@QwordCapture:
  SHR RCX, 3
  REP MOVSQ
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END Invaders_ScreenBlast, _TEXT$00


;*********************************************************
;   Invaders_UpdateHiScores
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_UpdateHiScores, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO


  MOV R8, 1024
  MOV RDX, OFFSET HiScoreAppData
  MOV RCX, OFFSET ApplicationDataEnv
  DEBUG_FUNCTION_CALL GetEnvironmentVariableA
  CMP RAX, 0
  JZ @CannotGetAppDataLocation
  
  MOV R8, OFFSET HiScoreAppData
  MOV RDX, OFFSET HiScoreAppDataFileFormat
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 03h  ; OPEN_EXISTING
  MOV R9, 0
  MOV R8, 3h   	; File Share Read/Write
  MOV RDX, 2h    ; File write
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL CreateFileA
  
  CMP EAX, 0FFFFFFFFh   ; INVALID_HANDLE_VALUE
  JE @FailedToOpenAttemptToCreate
  
  ;
  ; Write out the initial high scores list.
  ;
  LEA R9, STD_FUNCTION_STACK.Parameters.Param7[RSP]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 0
  MOV R8, 120				; File Size is fixed to 120 bytes.
  MOV RDX, [HiScoreListPtr]
  MOV RSI, RAX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL WriteFile
  
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL CloseHandle  
 
@CannotGetAppDataLocation:
@FailedToOpenAttemptToCreate:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END Invaders_UpdateHiScores, _TEXT$00


;*********************************************************
;   Invaders_CheckHiScores
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_CheckHiScores, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  ;
  ;   Reset High Scores
  ;
  MOV RAX, OFFSET InitialsConst
  MOV EAX, [RAX]
  MOV RCX, OFFSET InitialsEnter
  MOV [RCX], EAX
  MOV [InitialsEnterPtr], RCX
        
  MOV RDX, [HiScoreListPtr]
  XOR R8, R8
  MOV RCX, [PlayerScore]
  
  
  MOV [HiScoreLocationPtr], 0

@CheckNextScore:
  CMP RCX, QWORD PTR [RDX + 4]
  JA @NewHighScore

  ADD RDX, 12
  INC R8
  CMP R8, MAX_HI_SCORES
  JB @CheckNextScore
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@NewHighScore:
  MOV [HiScoreLocationPtr], RDX                 ; Update New High Score Location!
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_CheckHiScores, _TEXT$00


;***************************************************************************************************************************************************************************
; Level Resets
;***************************************************************************************************************************************************************************


;*********************************************************
;   Invaders_LevelOneReset
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_LevelOneReset, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV [PlayerSprite.HitPoints], PLAYER_START_HP
  DEBUG_FUNCTION_CALL Invaders_EmptyActiveList
  MOV [LevelIntroTimer], LEVEL_INTRO_TIMER_SIZE/2
  MOV [PlayerSprite.SpriteAlive], 1
  MOV [PlayerSprite.SpriteFire], 0

  MOV RCX, [SpritePointer]
  ADD RCX, SIZE SPRITE_BASIC_INFORMATION*4
  DEBUG_FUNCTION_CALL Invaders_ResetSpriteBasicInformation



  MOV RDI, [PlayerFireActivePtr]
  MOV [PlayerFireActivePtr], 0

  CMP RDI, 0
  JE @ListEmpty

@InitPlayerFirePreviouslyActive:

  MOV SPRITE_STRUCT.SpriteAlive[RDI], 0
  MOV SPRITE_STRUCT.HitPoints[RDI], 0

  ;
  ; Add the fire to the inactive list.
  ;
  MOV R8, SPRITE_STRUCT.pNext[RDI]


  MOV R9, [PlayerFireInActivePtr]
  MOV SPRITE_STRUCT.pNext[RDI], R9
  MOV SPRITE_STRUCT.pPrev[RDI], 0
  CMP R9, 0
  JE @DoNotUpdate
  MOV SPRITE_STRUCT.pPrev[R9], RDI
@DoNotUpdate:
  MOV [PlayerFireInActivePtr], RDI

  MOV RDI, R8
  CMP RDI, 0
  JNE @InitPlayerFirePreviouslyActive
@ListEmpty:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_LevelOneReset, _TEXT$00

;***************************************************************************************************************************************************************************
; Creating Enemies
;***************************************************************************************************************************************************************************

;*********************************************************
;   Invaders_RandomAstroids
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_RandomAstroids, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  DEBUG_FUNCTION_CALL Math_Rand
  AND EAX, 07h
  MOV EBX, EAX
  CMP EBX, 0
  JE @NoAstroids
  

@SetupAnotherAstroid:
  MOV RDI, [AstroidsSmallInActivePtr] 

  CMP RDI, 0
  JE @NoAstroids
  MOV R8, SPRITE_STRUCT.pNext[RDI]
  MOV [AstroidsSmallInActivePtr], R8
  CMP R8, 0
  JZ @NothingToUpdateZero
  MOV SPRITE_STRUCT.pPrev[R8], 0 
@NothingToUpdateZero:
  MOV SPRITE_STRUCT.SpriteAlive[RDI], 1
  MOV SPRITE_STRUCT.SpriteY[RDI], 1

  ;
  ; Randomize X Location
  ;
  DEBUG_FUNCTION_CALL Math_Rand
  XOR RDX, RDX
  DIV MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV SPRITE_STRUCT.SpriteX[RDI], RDX

  ;
  ; Randomize Velocity
  ;
  DEBUG_FUNCTION_CALL Math_Rand
  XOR RDX, RDX
  DIV SPRITE_STRUCT.SpriteVelMaxY[RDI]
  INC RDX
  MOV SPRITE_STRUCT.SpriteVelY[RDI], RDX

  MOV R8, [GameActiveListPtr]
  MOV SPRITE_STRUCT.pNext[RDI], R8
  MOV SPRITE_STRUCT.pPrev[RDI], 0  
  CMP R8, 0
  JE @NoUpdatePrev
  MOV SPRITE_STRUCT.pPrev[R8], RDI
@NoUpdatePrev:
  MOV [GameActiveListPtr], RDI
  DEC EBX
  JNZ @SetupAnotherAstroid

  
@NoAstroids:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_RandomAstroids, _TEXT$00


;*********************************************************
;   Invaders_RandomShips
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_RandomShips, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  DEBUG_FUNCTION_CALL Math_Rand
  AND EAX, 07h
  MOV EBX, EAX
  CMP EBX, 0
  JE @NoShips
  

@SetupAnotherAstroid:
  CMP [ShipScreenCounter], MAX_SHIPS_SCREEN
  JAE @NoShips
  INC [ShipScreenCounter]
  MOV RDI, [AlienFreeSmallShipsPtr] 

  CMP RDI, 0
  JE @NoShips
  MOV R8, SPRITE_STRUCT.pNext[RDI]
  MOV [AlienFreeSmallShipsPtr], R8
  CMP R8, 0
  JZ @NothingToUpdateZero
  MOV SPRITE_STRUCT.pPrev[R8], 0 
@NothingToUpdateZero:
  MOV SPRITE_STRUCT.SpriteAlive[RDI], 1
  MOV SPRITE_STRUCT.SpriteY[RDI], 1

  ;
  ; Randomize X Location
  ;
  DEBUG_FUNCTION_CALL Math_Rand
  XOR RDX, RDX
  DIV MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV SPRITE_STRUCT.SpriteX[RDI], RDX

  ;
  ; Randomize Velocity
  ;
  DEBUG_FUNCTION_CALL Math_Rand
  XOR RDX, RDX
  DIV SPRITE_STRUCT.SpriteVelMaxY[RDI]
  INC RDX
  MOV SPRITE_STRUCT.SpriteVelY[RDI], RDX

  MOV R8, [GameActiveListPtr]
  MOV SPRITE_STRUCT.pNext[RDI], R8
  MOV SPRITE_STRUCT.pPrev[RDI], 0  
  CMP R8, 0
  JE @NoUpdatePrev
  MOV SPRITE_STRUCT.pPrev[R8], RDI
@NoUpdatePrev:
  MOV [GameActiveListPtr], RDI
  DEC EBX
  JNZ @SetupAnotherAstroid

  
@NoShips:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_RandomShips, _TEXT$00

;***************************************************************************************************************************************************************************
; Colission Detection Functions
;***************************************************************************************************************************************************************************


;*********************************************************
;   Invaders_CollisionPlayerFire
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_CollisionPlayerFire, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG

  MOV RDI, [PlayerFireActivePtr]
  CMP RDI, 0
  JE @NothingToFire

@CheckEachFire:
  MOV RSI, [GameActiveListPtr]
  CMP RSI, 0
  JE @NoActiveGameEnemies
@InnerLoop:  

  CMP SPRITE_STRUCT.SpriteAlive[RDI], 0
  JE @FireNotAlive

  CMP SPRITE_STRUCT.SpriteAlive[RSI], 0
  JE @NotAlive

  MOV R8, SPRITE_STRUCT.SpriteX[RDI]
  MOV R9, SPRITE_STRUCT.SpriteX[RSI]
  MOV R10, R8
  ADD R10, SPRITE_STRUCT.SpriteWidth[RDI]
  MOV R11, R9
  ADD R11, SPRITE_STRUCT.SpriteWidth[RSI]
  
  ;
  ;   R8------R10   /  R9-----R11 
  ;  
  ;  If R9 > R10, no Collision 
  ;  If R8 > R11, no Collision
  ;

  CMP R8, R11
  JA @NoCollision
  CMP R9, R10
  JA @NoCollision

  MOV R8, SPRITE_STRUCT.SpriteY[RDI]
  MOV R9, SPRITE_STRUCT.SpriteY[RSI]
  MOV R10, R8
  ADD R10, SPRITE_STRUCT.SpriteHeight[RDI]
  MOV R11, R9
  ADD R11, SPRITE_STRUCT.SpriteHeight[RSI]

  ;
  ;   R8      R9 
  ;   |       |
  ;   R10     R11
  ;  If R9 > R10, no Collision 
  ;  If R8 > R11, no Collision
  ;

  ;
  ; Astroid.Bottom < Fire.Top
  ;
  CMP R8, R11
  JA @NoCollision

  CMP R9, R10
  JA @NoCollision

  ;
  ; Collision, inflict damage
  ;
  MOV R8, SPRITE_STRUCT.Damage[RSI]
  SUB SPRITE_STRUCT.HitPoints[RDI], R8

  MOV R8, SPRITE_STRUCT.Damage[RDI]
  SUB SPRITE_STRUCT.HitPoints[RSI], R8

  CMP SPRITE_STRUCT.HitPoints[RSI], 0
  JG @StillAlive
  MOV SPRITE_STRUCT.SpriteAlive[RSI], 0
@StillAlive:
  CMP SPRITE_STRUCT.HitPoints[RDI], 0
  JG @StillAlive2
  MOV SPRITE_STRUCT.SpriteAlive[RDI], 0
@StillAlive2:

  ;
  ; Player Score is (Base Points * MAX(VelX, VelY))
  ;
  XOR RDX, RDX
  MOV RAX, SPRITE_STRUCT.SpriteBasePointsValue[RSI]
  MOV R8, SPRITE_STRUCT.SpriteVelX[RSI]
  MOV R9, SPRITE_STRUCT.SpriteVelY[RSI]
  CMP R8, R9
  JA @UseVelocityX
  MOV R8, R9                    ; Use velocity Y
@UseVelocityX:
  MUL R8
  ADD [PlayerScore], RAX

@NotAlive:   
@NoCollision:   
  MOV RSI, SPRITE_STRUCT.pNext[RSI]
  CMP RSI, 0
  JNE @InnerLoop

@FireNotAlive:
  MOV RDI, SPRITE_STRUCT.pNext[RDI]
  CMP RDI, 0
  JNE @CheckEachFire
@NoActiveGameEnemies:
@NothingToFire:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_CollisionPlayerFire, _TEXT$00


;*********************************************************
;   Invaders_CollisionPlayer
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_CollisionPlayer, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG

  CMP [PlayerSprite.SpriteAlive], 0
  JE @SpriteIsDead

  MOV RDI, OFFSET PlayerSprite
  MOV RSI, [GameActiveListPtr]
  CMP RSI, 0
  JE @NoActiveEnemies
@InnerLoop:  
  CMP [PlayerSprite.SpriteAlive], 0
  JE @SpriteIsDead

  CMP SPRITE_STRUCT.SpriteAlive[RSI], 0
  JE @NotAlive

  MOV R8, SPRITE_STRUCT.SpriteX[RDI]
  MOV R9, SPRITE_STRUCT.SpriteX[RSI]
  MOV R10, R8
  ADD R10, SPRITE_STRUCT.SpriteWidth[RDI]
  MOV R11, R9
  ADD R11, SPRITE_STRUCT.SpriteWidth[RSI]
  
  ;
  ;   R8------R10   /  R9-----R11 
  ;  
  ;  If R9 > R10, no Collision 
  ;  If R8 > R11, no Collision
  ;

  CMP R8, R11
  JA @NoCollision
  CMP R9, R10
  JA @NoCollision

  MOV R8, SPRITE_STRUCT.SpriteY[RDI]
  MOV R9, SPRITE_STRUCT.SpriteY[RSI]
  MOV R10, R8
  ADD R10, SPRITE_STRUCT.SpriteHeight[RDI]
  MOV R11, R9
  ADD R11, SPRITE_STRUCT.SpriteHeight[RSI]

  ;
  ;   R8      R9 
  ;   |       |
  ;   R10     R11
  ;  If R9 > R10, no Collision 
  ;  If R8 > R11, no Collision
  ;

  ;
  ; Astroid.Bottom < Fire.Top
  ;
  CMP R8, R11
  JA @NoCollision

  CMP R9, R10
  JA @NoCollision

  ;
  ; Collision, inflict damage
  ;
  MOV R8, SPRITE_STRUCT.Damage[RSI]
  SUB SPRITE_STRUCT.HitPoints[RDI], R8

  MOV R8, SPRITE_STRUCT.Damage[RDI]
  SUB SPRITE_STRUCT.HitPoints[RSI], R8

  CMP SPRITE_STRUCT.HitPoints[RSI], 0
  JG @StillAlive
  MOV SPRITE_STRUCT.SpriteAlive[RSI], 0
@StillAlive:
  CMP SPRITE_STRUCT.HitPoints[RDI], 0
  JG @StillAlive2
  MOV SPRITE_STRUCT.SpriteAlive[RDI], 0
@StillAlive2:


@NotAlive:   
@NoCollision:   
  MOV RSI, SPRITE_STRUCT.pNext[RSI]
  CMP RSI, 0
  JNE @InnerLoop
@NoActiveEnemies:
@SpriteIsDead:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_CollisionPlayer, _TEXT$00

;***************************************************************************************************************************************************************************
; Sprite Movement & Callback  Functions
;***************************************************************************************************************************************************************************



  ;*********************************************************
;   Invaders_SmallShipAddToList
;
;        Parameters: Sprite Structure
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_SmallShipAddToList, _TEXT$00
.ENDPROLOG 
  MOV R9, SPRITE_STRUCT.MaxHp[RCX]
  MOV SPRITE_STRUCT.HitPoints[RCX], R9

  MOV RCX, SPRITE_STRUCT.ExplodePointer[RCX]
  DEBUG_FUNCTION_CALL Invaders_ResetSpriteBasicInformation
  DEC [ShipScreenCounter]
  RET
  
NESTED_END Invaders_SmallShipAddToList, _TEXT$00

;*********************************************************
;   Invaders_DefaultAddToList
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_DefaultAddToList, _TEXT$00
.ENDPROLOG 
  ; This function does nothing it's a place holder so we don't 
  ; have to check if the function pointer is NULL.
  RET
  
NESTED_END Invaders_DefaultAddToList, _TEXT$00


;*********************************************************
;   Invaders_DefaultMovement
;
;    This is the most basic movement that simply updates
;    the location based on velocity and lets other game code
;    rebalance if it was offscreen.
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_DefaultMovement, _TEXT$00
.ENDPROLOG 
  MOV RDX, SPRITE_STRUCT.SpriteY[RCX]
  ADD RDX, SPRITE_STRUCT.SpriteVelY[RCX]
  MOV SPRITE_STRUCT.SpriteY[RDI], RDX

  MOV RDX, SPRITE_STRUCT.SpriteX[RCX]
  ADD RDX, SPRITE_STRUCT.SpriteVelX[RCX]
  MOV SPRITE_STRUCT.SpriteX[RCX], RDX
  RET

NESTED_END Invaders_DefaultMovement, _TEXT$00



;*********************************************************
;   Invaders_SmallShipMovement
;
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_SmallShipMovement, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  MOV RDI, RCX

  DEBUG_FUNCTION_CALL Math_Rand
  XOR RDX, RDX
  MOV R8, SPRITE_STRUCT.SpriteVelMaxY[RDI]
  SHL R8, 1
  DIV R8
  CMP RDX, SPRITE_STRUCT.SpriteVelMaxY[RDI]
  JB @VelReadyY
  SUB RDX, SPRITE_STRUCT.SpriteVelMaxY[RDI]
  NEG RDX
@VelReadyY:  

  MOV RAX, SPRITE_STRUCT.SpriteY[RDI]
  ADD RAX, RDX
  MOV SPRITE_STRUCT.SpriteY[RDI], RAX

  DEBUG_FUNCTION_CALL Math_Rand
  XOR RDX, RDX
  MOV R8, SPRITE_STRUCT.SpriteVelMaxX[RDI]
  SHL R8, 1
  DIV R8
  CMP RDX, SPRITE_STRUCT.SpriteVelMaxX[RDI]
  JB @VelReadyX
  SUB RDX, SPRITE_STRUCT.SpriteVelMaxX[RDI]
  NEG RDX
@VelReadyX:  

  MOV RAX, SPRITE_STRUCT.SpriteX[RDI]
  ADD RAX, RDX
  MOV SPRITE_STRUCT.SpriteX[RDI], RAX


  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_SmallShipMovement, _TEXT$00





;***************************************************************************************************************************************************************************
; Display Graphics Functions
;***************************************************************************************************************************************************************************



;*********************************************************
;   Invaders_DisplayPlayer
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_DisplayPlayer, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  CMP [PlayerSprite.SpriteAlive], 0
  JE @SpriteIsDead

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
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@SpriteIsDead:

  MOV R9, [PlayerSprite.SpriteY]
  MOV R8, [PlayerSprite.SpriteX]
  MOV RDX, [SpritePointer]
  ADD RDX, SIZE SPRITE_BASIC_INFORMATION*4
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplaySpriteNoLoop
  CMP RAX, 1
  JNE @StillExploding
  ;
  ; Do nothing right now, return 1
  ; So we can capture the screen and reset the
  ; level outside.
  ;
@StillExploding:    
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_DisplayPlayer, _TEXT$00


;*********************************************************
;   Invaders_DisplayPlayerFire
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_DisplayPlayerFire, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV RDI, [PlayerFireActivePtr]
  CMP RDI, 0
  JE @NothingToFire

@FireLoop:
  CMP SPRITE_STRUCT.SpriteAlive[RDI], 0
  JE @SpriteRemove
  ;
  ; Diplay Player's Fire
  ;
  MOV RCX, SPRITE_STRUCT.SpriteY[RDI]
  CMP QWORD PTR RCX, 0
  JG @DisplayFire
@SpriteRemove:  
 ;
 ; Decomission player fire
 ;
  MOV SPRITE_STRUCT.SpriteAlive[RDI], 0
  DEC [PlayerSprite.SpriteFire]

  MOV R8, SPRITE_STRUCT.pNext[RDI]
  MOV R12, R8
  MOV R9, SPRITE_STRUCT.pPrev[RDI]
  MOV R10, [PlayerFireActivePtr]

  CMP RDI, R10
  JNE @NotStartOfList
  
  ;
  ;  We are the head of list.
  ;
  MOV [PlayerFireActivePtr], R8
  CMP R8, 0
  JE @NothingToDo
  MOV SPRITE_STRUCT.pPrev[R8], 0
  JMP @UpdateInactiveList
@NotStartOfList:
  ;
  ; Assume R9 is non-null if we are not the start of the list.
  ;
  MOV SPRITE_STRUCT.pNext[R9], R8
  CMP R8, 0
  JE @NothingToDo

  ;
  ; Update R8
  ;
  MOV SPRITE_STRUCT.pPrev[R8], R9
@NothingToDo:
@UpdateInactiveList:  

  ;
  ; Add Fire to the inactive list
  ; 
  MOV R8, [PlayerFireInActivePtr]
  MOV SPRITE_STRUCT.pNext[RDI], R8 
  MOV SPRITE_STRUCT.pPrev[RDI], 0
  CMP R8, 0
  JZ @NoUpateToPrevious
  MOV SPRITE_STRUCT.pPrev[R8], RDI
@NoUpateToPrevious:
  MOV [PlayerFireInActivePtr], RDI
  MOV RDI, R12
  CMP RDI, 0
  JNE @FireLoop
  JMP @DisplayComplete
@DisplayFire:
  MOV R9, SPRITE_STRUCT.SpriteY[RDI]

  ADD RCX, SPRITE_STRUCT.SpriteVelY[RDI]
  MOV SPRITE_STRUCT.SpriteY[RDI], RCX

  MOV R8, SPRITE_STRUCT.SpriteX[RDI]
  MOV RDX, [SpritePointer]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplaySprite  
@CheckNext:  
  MOV RDI, SPRITE_STRUCT.pNext[RDI]
  CMP RDI, 0
  JNE @FireLoop

@NothingToFire:
@DisplayComplete:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_DisplayPlayerFire, _TEXT$00



;*********************************************************
;   Invaders_DisplayGameGraphics
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_DisplayGameGraphics, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV RDI, [GameActiveListPtr]
  CMP RDI, 0
  JE @NoActiveGamePieces

@GameDisplayLoop:
  
  ;
  ; Check Off Screen
  ;
  MOV RCX, SPRITE_STRUCT.SpriteY[RDI]
  ADD RCX, SPRITE_STRUCT.SpriteHeight[RDI]
  CMP RCX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  JAE @SpriteResetCheck

  MOV RCX, SPRITE_STRUCT.SpriteX[RDI]
  ADD RCX, SPRITE_STRUCT.SpriteWidth[RDI]
  CMP RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  JAE @SpriteResetCheck

  CMP SPRITE_STRUCT.SpriteX[RDI], 0
  JLE @SpriteResetCheck

  CMP SPRITE_STRUCT.SpriteY[RDI], 0
  JLE @SpriteResetCheck

  JMP @DisplayGameGfx

@SpriteResetCheck:
  ;
  ; Check if Sprite Should be Removed or reset.
  ;
  CMP SPRITE_STRUCT.KillOffscreen[RDI], 0
  JE @PutBackOnScreen
@SpriteRemove:  


 ;
 ; Decomission Off Screen
 ;
  MOV SPRITE_STRUCT.SpriteAlive[RDI], 0

  MOV R8, SPRITE_STRUCT.pNext[RDI]
  MOV R12, R8
  MOV R9, SPRITE_STRUCT.pPrev[RDI]
  MOV R10, [GameActiveListPtr]

  CMP RDI, R10
  JNE @NotStartOfList
  
  ;
  ;  We are the head of list.
  ;
  MOV [GameActiveListPtr], R8
  CMP R8, 0
  JE @NothingToDo
  MOV SPRITE_STRUCT.pPrev[R8], 0
  JMP @UpdateInactiveList
@NotStartOfList:
  ;
  ; Assume R9 is non-null if we are not the start of the list.
  ;
  MOV SPRITE_STRUCT.pNext[R9], R8
  CMP R8, 0
  JE @NothingToDo

  ;
  ; Update R8
  ;
  MOV SPRITE_STRUCT.pPrev[R8], R9
@NothingToDo:
@UpdateInactiveList:  

  ;
  ; Notify adding back to list.
  ;
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL SPRITE_STRUCT.pfnAddedBackToList[RDI]

  ;
  ; Add Graphics back to the inactive list
  ; 
  MOV R8, SPRITE_STRUCT.SpriteInactiveListPtr[RDI]
  MOV R8, [R8]
  MOV SPRITE_STRUCT.pNext[RDI], R8 
  MOV SPRITE_STRUCT.pPrev[RDI], 0
  CMP R8, 0
  JZ @NoUpateToPrevious
  MOV SPRITE_STRUCT.pPrev[R8], RDI
@NoUpateToPrevious:
  MOV R8, SPRITE_STRUCT.SpriteInactiveListPtr[RDI]
  MOV [R8], RDI
  MOV RDI, R12
  CMP RDI, 0
  JNE @GameDisplayLoop
  JMP @DisplayComplete

  ;
  ; Put the sprite back on screen.
  ;
@PutBackOnScreen:
  CMP SPRITE_STRUCT.SpriteY[RDI], 0
  JG @SkipYStart
  MOV SPRITE_STRUCT.SpriteY[RDI], 1
@SkipYStart:
  CMP SPRITE_STRUCT.SpriteX[RDI], 0
  JG @SkipXStart
  MOV SPRITE_STRUCT.SpriteX[RDI], 1
@SkipXStart:
  MOV R8, SPRITE_STRUCT.SpriteX[RDI]
  ADD R8, SPRITE_STRUCT.SpriteWidth[RDI]
  CMP R8, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  JB @SkipXEnd
  MOV R8, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  DEC R8
  SUB R8, SPRITE_STRUCT.SpriteWidth[RDI]
  MOV SPRITE_STRUCT.SpriteX[RDI], R8
@SkipXEnd:
  MOV R8, SPRITE_STRUCT.SpriteY[RDI]
  ADD R8, SPRITE_STRUCT.SpriteHeight[RDI]
  CMP R8, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  JB @SkipYEnd
  MOV R8, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  DEC R8
  SUB R8, SPRITE_STRUCT.SpriteHeight[RDI]
  MOV SPRITE_STRUCT.SpriteY[RDI], R8
@SkipYEnd:
    
@DisplayGameGfx:
  CMP SPRITE_STRUCT.SpriteAlive[RDI], 0
  JNE @DisplaySprite

  CMP SPRITE_STRUCT.ExplodePointer[RDI], 0
  JE @SpriteRemove

  MOV R9, SPRITE_STRUCT.SpriteY[RDI]
  MOV R8, SPRITE_STRUCT.SpriteX[RDI]
  MOV RDX, SPRITE_STRUCT.ExplodePointer[RDI]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplaySpriteNoLoop
  CMP RAX, 1
  JE @SpriteRemove
  JMP @CheckNext
  
 @DisplaySprite:
  
  ;
  ; Display Sprite and then update the sprite movement for next round.
  ;

  MOV R9, SPRITE_STRUCT.SpriteY[RDI]
  MOV R8, SPRITE_STRUCT.SpriteX[RDI]
  MOV RDX, SPRITE_STRUCT.ImagePointer[RDI]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplaySprite  

  ;
  ; Update Velocity for next frame.
  ;
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL SPRITE_STRUCT.pfnSpriteMovementUpdate[RDI]

@CheckNext:  
  MOV RDI, SPRITE_STRUCT.pNext[RDI]
  CMP RDI, 0
  JNE @GameDisplayLoop

@NoActiveGamePieces:
@DisplayComplete:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_DisplayGameGraphics, _TEXT$00



;*********************************************************
;   Invaders_ResetPlayerLeftRight
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_ResetPlayerLeftRight, _TEXT$00
.ENDPROLOG 
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
  RET

NESTED_END Invaders_ResetPlayerLeftRight, _TEXT$00





;*********************************************************
;   Invaders_DisplayGamePanel
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_DisplayGamePanel, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV R8, [PlayerScore]
  MOV RDX, OFFSET PlayerScoreFormat
  MOV RCX, OFFSET PlayerOutputText
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, 10
  MOV R8, 500
  MOV RDX, OFFSET PlayerOutputText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV R8, [PlayerLives]
  MOV RDX, OFFSET PlayerLivesText
  MOV RCX, OFFSET PlayerOutputText
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE-1
  MOV R9, 50
  MOV R8, 700
  MOV RDX, OFFSET PlayerOutputText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV R8, [PlayerSprite.HitPoints]
  MOV RDX, OFFSET PlayerHpText
  MOV RCX, OFFSET PlayerOutputText
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE-1
  MOV R9, 70
  MOV R8, 700
  MOV RDX, OFFSET PlayerOutputText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_DisplayGamePanel, _TEXT$00






;************************************************************************************************************************************************************************************************************************************
;  The following are testing functions.
;************************************************************************************************************************************************************************************************************************************


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

END