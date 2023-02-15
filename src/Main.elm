module Main exposing (main)

import Browser
import Browser.Events exposing (onResize)
import Confetti
import Css exposing (..)
import Css.Transitions exposing (easeInOut, transition)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Json.Decode as D
import Math.Vector2 as Vec2 exposing (Vec2)
import Model exposing (Apple, Flags, Model, Resources, State, Vec, Yippee, initialState)
import Ports
import Process exposing (sleep)
import Random exposing (generate)
import Random.Float
import Task


type Msg
    = Frame { delta : Float, time : Float }
    | SaveDone
    | MouseMove Vec
    | AddAppleAt Vec
    | AddApple Apple
    | WindowResize Int Int
    | YippeeClicked
    | ConfettiMsg Confetti.Msg
    | SpawnConfetti
    | AudioFinished String
    | IncreaseHappiness Float
    | YippeeScream
    | Delayed Msg Float
    | FullscreenChange Bool


type alias FrameData a =
    { a | delta : Float, time : Float }


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view >> Html.Styled.toUnstyled
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init { maybeState, resources, windowSize, url } =
    let
        { pos, targetPos, flipped, apples, mousePos, focusPos, happiness, jump } =
            maybeState |> Maybe.withDefault initialState
    in
    ( { pos = pos
      , targetPos = targetPos
      , focusPos = focusPos
      , mousePos = mousePos
      , flipped = flipped
      , apples = apples
      , resources = resources
      , windowSize = windowSize
      , happiness = happiness
      , jump = jump
      , confetti = Confetti.init
      , sounds = []
      , url = url
      , fullscreen = False
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Frame data ->
            frame data model

        FullscreenChange fullscreen ->
            ( { model | fullscreen = fullscreen }, Cmd.none )

        MouseMove mousePos ->
            ( { model | mousePos = mousePos }, Cmd.none )

        AddAppleAt pos ->
            addAppleAt pos model

        AddApple apple ->
            ( { model | apples = apple :: model.apples }, Cmd.none )

        WindowResize x y ->
            ( { model | windowSize = { x = toFloat x, y = toFloat y } }, Cmd.none )

        SaveDone ->
            ( model, Cmd.none )

        YippeeClicked ->
            jumpYippee model

        SpawnConfetti ->
            let
                cmsg =
                    Confetti.TriggerBurst model.pos.x (model.windowSize.y - model.pos.y)
            in
            update (ConfettiMsg cmsg) model

        ConfettiMsg cmsg ->
            let
                ( confetti, cmd ) =
                    Confetti.update cmsg model.confetti
            in
            ( { model | confetti = confetti }, cmd |> Cmd.map ConfettiMsg )

        AudioFinished url ->
            ( { model | sounds = List.filter ((/=) url) model.sounds }, Cmd.none )

        IncreaseHappiness value ->
            { model | happiness = model.happiness + value }
                |> yippeeMood

        YippeeScream ->
            yippeeScream model

        Delayed cont seconds ->
            ( model, delay seconds cont )


frame : FrameData a -> Model -> ( Model, Cmd Msg )
frame frameData oldState =
    let
        ( newState, cmd ) =
            frameYippee frameData oldState
                |> frameApples frameData
    in
    ( newState, Cmd.batch [ cmd, Ports.requestSave newState ] )


frameApples : FrameData f -> State s -> ( State s, Cmd Msg )
frameApples frameData state =
    let
        apples =
            List.filterMap (frameApple frameData state) state.apples

        eaten =
            List.length state.apples - List.length apples |> Basics.max 0
    in
    ( { state
        | apples = List.filterMap (frameApple frameData state) state.apples
      }
    , Cmd.batch <| List.repeat eaten (Random.generate IncreaseHappiness (Random.Float.normal 1 0.2))
    )


frameYippee : FrameData f -> Model -> Model
frameYippee { delta } state =
    let
        maxSpeed =
            100
    in
    let
        ( focusPos, targetPos ) =
            state.apples
                |> List.head
                |> Maybe.map (.pos >> (\x -> ( x, x )))
                |> Maybe.withDefault
                    (if state.fullscreen then
                        ( state.windowSize |> vec2 |> Vec2.scale 0.5 |> vec, { x = 0, y = 0 } )

                     else
                        ( state.mousePos, movedMousePos state )
                    )

        diff =
            Vec2.sub (vec2 targetPos) (vec2 <| centerPos state)

        wantedMove =
            Vec2.dot diff (right2 1)

        pos =
            { y = state.pos.y, x = state.pos.x + delta * clamp -maxSpeed maxSpeed wantedMove }

        jump =
            state.jump - 1.2 * delta |> Basics.max 0

        flipped =
            if jump == 0 then
                focusPos.x > pos.x

            else
                state.flipped
    in
    { state | pos = pos, flipped = flipped, targetPos = targetPos, focusPos = focusPos, jump = jump }


yippeeMood : Model -> ( Model, Cmd Msg )
yippeeMood yippee =
    if yippee.happiness < 7 then
        ( yippee, Cmd.none )

    else
        ( { yippee | happiness = 0 }
        , Random.generate (Delayed YippeeScream) (Random.Float.normal 0.5 0.2)
        )


jumpYippee : Yippee y -> ( Yippee y, Cmd Msg )
jumpYippee yippee =
    ( { yippee | jump = 1 }
    , Random.Float.normal 0.5 0.2 |> generate IncreaseHappiness
    )


yippeeScream : Model -> ( Model, Cmd Msg )
yippeeScream model =
    ( { model | sounds = model.resources.yippeeSoundUrl :: model.sounds } |> Debug.log "Screaming!"
    , delay 0.5 SpawnConfetti
    )


frameApple : FrameData a -> State s -> Apple -> Maybe Apple
frameApple { delta } state apple =
    let
        radius =
            20
    in
    if appleEaten state apple then
        Nothing

    else
        let
            y =
                apple.pos.y + velocity * delta |> Basics.max 0

            x =
                apple.pos.x + delta * apple.roll * radius

            velocity =
                if apple.pos.y > 0 then
                    apple.velocity - 1000 * delta

                else
                    abs apple.velocity - 800 |> Basics.max 0

            pos =
                { x = x, y = y }

            rotation =
                apple.rotation + delta * apple.roll

            roll =
                if y == 0 then
                    apple.roll - (delta * 0.5 |> clamp -(abs apple.roll) (abs apple.roll)) * sign apple.roll

                else
                    apple.roll
        in
        Just { pos = pos, rotation = rotation, roll = roll, velocity = velocity }


appleEaten : Yippee a -> Apple -> Bool
appleEaten yippee { pos } =
    Vec2.distanceSquared (vec2 yippee.pos) (vec2 pos) < 50 * 50


addAppleAt : Vec -> State a -> ( State a, Cmd Msg )
addAppleAt pos state =
    ( state
    , Random.float -3 3
        |> Random.generate
            (\roll ->
                AddApple { pos = pos, rotation = 0, roll = roll, velocity = 200 }
            )
    )


movedMousePos : State s -> Vec
movedMousePos state =
    let
        wantedDist =
            200
    in
    vec2 state.mousePos
        |> Vec2.sub (vec2 <| centerPos state)
        |> Vec2.normalize
        |> Vec2.scale wantedDist
        |> Vec2.add (vec2 state.mousePos)
        |> vec


centerPos : Yippee y -> Vec
centerPos { pos } =
    { x = pos.x, y = pos.y + 50 }


clamp : Float -> Float -> Float -> Float
clamp a b x =
    if x < a then
        a

    else if b < x then
        b

    else
        x


sign : number -> number
sign x =
    if x < 0 then
        -1

    else
        1


vec2 : Vec -> Vec2
vec2 =
    Vec2.fromRecord


vec : Vec2 -> Vec
vec =
    Vec2.toRecord


up2 : Float -> Vec2
up2 y =
    vec2 { x = 0, y = y }


right2 : Float -> Vec2
right2 x =
    vec2 { x = x, y = 0 }


delay : Float -> msg -> Cmd msg
delay seconds msg =
    sleep (seconds * 1000) |> Task.perform (always msg)


view : Model -> Html Msg
view model =
    div [ cssUnset [ zIndex <| int 1000 ] ]
        (List.map viewSound model.sounds
            ++ [ viewYippee model.resources model
               , viewAppleButton model
               , Confetti.view model.confetti |> Html.map ConfettiMsg |> Html.Styled.fromUnstyled
               ]
            ++ List.map (viewApple model.resources) model.apples
        )


viewYippee : Resources -> Yippee a -> Html Msg
viewYippee resources { pos, flipped, jump } =
    let
        xScale =
            if flipped then
                -1

            else
                1
    in
    img
        [ src resources.yippeeUrl
        , noDrag
        , onClick YippeeClicked
        , cssUnset
            [ Css.width (px 100)
            , screenPosition { x = pos.x, y = pos.y + 200 * (1 - (2 * jump - 1) ^ 2 |> Basics.max 0) }
            , opacity (num 90)
            , if jump == 0 then
                transition [ Css.Transitions.transform3 200 0 easeInOut ]

              else
                Css.batch []
            , transforms
                [ centerX
                , scaleX xScale
                , rotate (deg <| -jump * 360)
                ]
            ]
        ]
        []


viewApple : Resources -> Apple -> Html Msg
viewApple { appleUrl } { pos, rotation } =
    img
        [ src appleUrl
        , cssUnset
            [ screenPosition pos
            , transforms
                [ centerX
                , rotate (rad rotation)
                ]
            , Css.width (px 40)
            ]
        ]
        []


viewAppleButton : Model -> Html Msg
viewAppleButton { resources, windowSize, fullscreen } =
    let moveAway bool = 
            transform
                (translateX <|
                    pct <|
                        if bool then
                            80

                        else
                            0
                )
    in
    div
        [ cssUnset
            [ border3 (px 2) solid black
            , position fixed
            , bottom (px 0)
            , right (px 0)
            , moveAway fullscreen
            , hover [moveAway False]
            , transition [ Css.Transitions.transform3 300 0 easeInOut ]
            , padding (px 8)
            , backgroundColor white
            , opacity (num 0.9)
            ]
        ]
        [ img
            [ src resources.appleUrl
            , draggable "true"
            , preventDefaultOn "dragend" (decodeEventPos windowSize |> D.map (\x -> ( AddAppleAt x, True )))
            , cssUnset [ Css.width (px 40) ]
            ]
            []
        ]


viewSound : String -> Html Msg
viewSound url =
    audio
        [ src url
        , cssUnset []
        , autoplay True
        , on "ended" (D.succeed <| AudioFinished url)
        ]
        []


screenPosition : Vec -> Style
screenPosition { x, y } =
    Css.batch
        [ position fixed
        , bottom (px y)
        , left (px x)
        ]


decodeEventPos : Vec -> D.Decoder Vec
decodeEventPos windowSize =
    D.map2 Vec
        (D.field "clientX" D.float)
        (D.field "clientY" D.float
            |> D.map (\y -> windowSize.y - y)
        )


noDrag =
    preventDefaultOn "dragstart" (D.succeed ( SaveDone, True ))


black =
    rgb 0 0 0


white =
    rgb 255 255 255


centerX =
    translateX (pct -50)


cssUnset list =
    css [ important (all unset :: list |> Css.batch) ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.frame Frame
        , Ports.saveDone (\_ -> SaveDone)
        , Ports.mouseMove MouseMove
        , onResize WindowResize
        , Ports.onFullscreenChange FullscreenChange
        , model.confetti |> Confetti.subscriptions |> Sub.map ConfettiMsg
        ]
