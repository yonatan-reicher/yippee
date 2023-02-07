module Main exposing (main)

import Browser
import Css exposing (..)
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
        { pos, targetPos, flipped, apples, mousePos } =
            maybeState |> Maybe.withDefault initialState
    in
    ( { pos = pos
      , targetPos = targetPos
      , mousePos = mousePos
      , flipped = flipped
      , apples = apples
      , resources = resources
      , windowSize = windowSize
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

        AddApple apple -> ( { model | apples = apple :: model.apples }, Cmd.none)

        SaveDone ->
            ( model, Cmd.none )


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
        height =
            100

        wantedDist =
            200

        maxSpeed =
            100
    in
    let
        targetPos = state.apples |> List.head |> Maybe.map .pos |> Maybe.withDefault state.mousePos
        diff =
            Vec2.sub (vec2 targetPos) (Vec2.add (vec2 state.pos) (up2 <| 0.5 * height))

        dist =
            Vec2.length diff

        targetAngle =
            atan2 (Vec2.getY diff) (Vec2.getX diff)

        wantedMove =
            cos targetAngle * (dist - wantedDist)

        pos =
            { y = state.pos.y, x = state.pos.x + delta * clamp -maxSpeed maxSpeed wantedMove }
    in
    { state | pos = pos, flipped = Vec2.getX diff > 0, targetPos = targetPos }
    


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

            y = apple.pos.y + velocity * delta |> Basics.max 0

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
    Debug.log "dist" (Vec2.distanceSquared (vec2 yippee.pos) (vec2 pos)) < 200 * 300


addAppleAt : Vec -> State a -> ( State a, Cmd Msg )
addAppleAt pos state =
    (state, Random.float -3 3 |> Random.generate (\roll -> 
            AddApple { pos = pos, rotation = 0, roll = roll, velocity = 200 }))


clamp : Float -> Float -> Float -> Float
clamp a b x =
    if x < a then
        a

    else if b < x then
        b

    else
        x
        

sign x = if x < 0 then -1 else 1


vec2 =
    Vec2.fromRecord


up2 y =
    vec2 { x = 0, y = y }


view : Model -> Html Msg
view model =
    div []
        ([ viewYippee model.resources model
         , viewAppleButton model
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
        , front
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
            , on "dragend" (decodeEventPos windowSize |> D.map (Debug.log "value") |> D.map AddAppleAt)
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
        ]
