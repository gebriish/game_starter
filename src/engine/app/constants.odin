package app

import "engine:utils"

vec2 :: utils.vec2
vec4 :: utils.vec4

ivec2 :: utils.ivec2
ivec4 :: utils.ivec4

MAX_GAMEPADS :: 2

KeyCode :: enum u32 {
  Space         ,
  Apostrophe    , 
  Comma         , /* , */
  Minus         , /* - */
  Period        , /* . */
  Slash         , /* / */
  Semicolon     , /* ; */
  Equal         , /* :: */
  Left_Bracket  , /* [ */
  Backslash     , /* \ */
  Right_Bracket , /* ] */
  Grave_Accent  , /* ` */
  World_1       , /* non-us #1 */
  World_2       , /* non-us #2 */

  Zero  ,
  One   ,
  Two   ,
  Three ,
  Four  ,
  Five  ,
  Six   ,
  Seven ,
  Eight ,
  Nine  ,

  A ,
  B ,
  C ,
  D ,
  E ,
  F ,
  G ,
  H ,
  I ,
  J ,
  K ,
  L ,
  M ,
  N ,
  O ,
  P ,
  Q ,
  R ,
  S ,
  T ,
  U ,
  V ,
  W ,
  X ,
  Y ,
  Z ,

  Escape       ,
  Enter        ,
  Tab          ,
  Backspace    ,
  Insert       ,
  Delete       ,
  Right        ,
  Left         ,
  Down         ,
  Up           ,
  Page_Up      ,
  Page_Down    ,
  Home         ,
  End          ,
  Caps_Lock    ,
  Scroll_Lock  ,
  Num_Lock     ,
  Print_Screen ,
  Pause        ,

  F1  ,
  F2  ,
  F3  ,
  F4  ,
  F5  ,
  F6  ,
  F7  ,
  F8  ,
  F9  ,
  F10 ,
  F11 ,
  F12 ,
  F13 ,
  F14 ,
  F15 ,
  F16 ,
  F17 ,
  F18 ,
  F19 ,
  F20 ,
  F21 ,
  F22 ,
  F23 ,
  F24 ,
  F25 ,

  KP_0 ,
  KP_1 ,
  KP_2 ,
  KP_3 ,
  KP_4 ,
  KP_5 ,
  KP_6 ,
  KP_7 ,
  KP_8 ,
  KP_9 ,

  KP_Decimal  ,
  KP_Divide   ,
  KP_Multiply ,
  KP_Subtract ,
  KP_Add      ,
  KP_Enter    ,
  KP_Equal    ,

  Left_Shift    ,
  Left_Control  ,
  Left_Alt      ,
  Left_Super    ,
  Right_Shift   ,
  Right_Control ,
  Right_Alt     ,
  Right_Super   ,
  Menu          ,
}

MouseCode :: enum u32 {
  Button_1 = 0, /* left */
  Button_2, /* right */
  Button_3, /* middle */
  Button_4,
  Button_5,
  Button_6,
  Button_7,
  Button_8,
}

GamepadCode :: enum u32 {
  A = 0, // Cross
  B, // Circle
  X, // Square
  Y, // Triangle
  Left_Bumper,
  Right_Bumper,
  Back,        // Share on PlayStation
  Start,       // Options on PlayStation
  Guide,       // PS button on PlayStation
  Left_Thumb,
  Right_Thumb,
  DPad_Up,
  DPad_Right,
  DPad_Down,
  DPad_Left,
}

GamepadAxis :: enum {
  Left_X = 0,
  Left_Y,
  Right_X,
  Right_Y,
  Left_Trigger,
  Right_Trigger,
}

