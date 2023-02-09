module Main exposing (main)

import Browser
import Browser.Events exposing (onResize)
import Confetti
import Css exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Json.Decode as D
import Math.Vector2 as Vec2 exposing (Vec2)
import Model exposing (Apple, Flags, Model, Resources, State, Vec, Yippee, initialState)
import Ports
import Random


type Msg
    = Frame { delta : Float, time : Float }
    | SaveDone
    | MouseMove Vec
    | AddAppleAt Vec
    | AddApple Apple
    | WindowResize Int Int
    | YippeeClicked
    | ConfettiMsg Confetti.Msg


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
init { maybeState, resources, windowSize } =
    let
        { pos, targetPos, flipped, apples, mousePos, focusPos } =
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
      , confetti = Confetti.init
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Frame data ->
            frame data model

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
            let
                cmsg =
                    Confetti.TriggerBurst model.mousePos.x (model.windowSize.y - model.mousePos.y)

                ( newModel, cmd ) =
                    update (ConfettiMsg cmsg) model
            in
            ( newModel, Cmd.batch [ Ports.playSound model.resources.yippeeSoundUrl, cmd ] )

        ConfettiMsg cmsg ->
            let
                ( confetti, cmd ) =
                    Confetti.update cmsg model.confetti
            in
            ( { model | confetti = confetti }, cmd |> Cmd.map ConfettiMsg )


frame : FrameData a -> State s -> ( State s, Cmd Msg )
frame frameData oldState =
    let
        newState =
            frameYippee frameData oldState
                |> frameApples frameData
    in
    ( newState, Ports.requestSave newState )


frameApples : FrameData f -> State s -> State s
frameApples frameData state =
    { state | apples = List.filterMap (frameApple frameData state) state.apples }


frameYippee : FrameData f -> State y -> State y
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
                |> Maybe.withDefault ( state.mousePos, movedMousePos state )

        diff =
            Vec2.sub (vec2 targetPos) (vec2 <| centerPos state)

        wantedMove =
            Vec2.dot diff (right2 1)

        pos =
            { y = state.pos.y, x = state.pos.x + delta * clamp -maxSpeed maxSpeed wantedMove }
    in
    { state | pos = pos, flipped = focusPos.x > pos.x, targetPos = targetPos, focusPos = focusPos }


frameApple : FrameData a -> State s -> Apple -> Maybe Apple
frameApple { delta } state apple =
    if appleEaten state apple then
        Nothing

    else
        let
            radius =
                20

            x =
                apple.pos.x + delta * apple.roll * radius

            y =
                apple.pos.y + velocity * delta |> Basics.max 0

            velocity =
                apple.velocity - 1000 * delta

            pos =
                { x = x, y = y }

            rotation =
                apple.rotation + delta * apple.roll

            roll =
                apple.roll - (delta * 0.5 |> clamp -(abs apple.roll) (abs apple.roll)) * sign apple.roll
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


sign x =
    if x < 0 then
        -1

    else
        1


vec2 =
    Vec2.fromRecord


vec =
    Vec2.toRecord


up2 y =
    vec2 { x = 0, y = y }


right2 x =
    vec2 { x = x, y = 0 }


view : Model -> Html Msg
view model =
    div []
        ([ viewYippee model.resources model
         , viewAppleButton model
         , Confetti.view model.confetti |> Html.map ConfettiMsg |> Html.Styled.fromUnstyled
         ]
            ++ List.map (viewApple model.resources) model.apples
        )


viewYippee : Resources -> Yippee a -> Html Msg
viewYippee resources { pos, flipped } =
    let
        xScale =
            if flipped then
                -1

            else
                1
    in
    img
        [ src resources.yippeeUrl
        , screenPosition pos
        , noDrag
        , front
        , onClick YippeeClicked
        , css
            [ all unset
            , Css.width (px 100)
            , opacity (num 90)
            , transforms
                [ centerX
                , scaleX xScale
                ]
            ]
        ]
        []


viewApple : Resources -> Apple -> Html Msg
viewApple { appleUrl } { pos, rotation } =
    img
        [ src appleUrl
        , screenPosition pos
        , front
        , css
            [ transforms
                [ centerX
                , rotate (rad rotation)
                ]
            , Css.width (px 40)
            ]
        ]
        []


viewAppleButton : Model -> Html Msg
viewAppleButton { resources, windowSize } =
    div
        [ front
        , css
            [ border3 (px 2) solid black
            , position fixed
            , bottom (px 0)
            , right (px 0)
            , padding (px 8)
            , backgroundColor white
            , opacity (num 0.9)
            ]
        ]
        [ img
            [ src resources.appleUrl
            , draggable "true"
            , preventDefaultOn "dragend" (decodeEventPos windowSize |> D.map (\x -> ( AddAppleAt x, True )))
            , css [ Css.width (px 40) ]
            ]
            []
        ]


screenPosition : Vec -> Attribute a
screenPosition { x, y } =
    css
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


front =
    css [ zIndex (int 10000) ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.frame Frame
        , Ports.saveDone (\_ -> SaveDone)
        , Ports.mouseMove MouseMove
        , onResize WindowResize
        , model.confetti |> Confetti.subscriptions |> Sub.map ConfettiMsg
        ]
