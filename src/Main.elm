module Main exposing (main)

import Browser
import Css exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Math.Vector2 as Vec2 exposing (Vec2)
import Model exposing (Apple, Flags, Model, Resources, State, Vec, Yippee)
import Ports


type Msg
    = Frame { delta : Float, time : Float }
    | SaveDone
    | MouseMove Vec


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view >> Html.Styled.toUnstyled
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        state =
            flags.state
                |> Maybe.withDefault
                    { yippee =
                        { pos = { x = 0, y = 0 }
                        , targetPos = { x = 0, y = 0 }
                        , flipped = True
                        }
                    , apples = []
                    }
    in
    ( { resources = flags.resources
      , state = state
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Frame data ->
            let
                ( state, cmd ) =
                    frame data model.state
            in
            ( { model | state = state }, cmd )

        MouseMove mousePos ->
            let
                state =
                    model.state

                yippee =
                    state.yippee

                targetPos =
                    case List.head model.state.apples of
                        Just apple ->
                            apple.pos

                        Nothing ->
                            mousePos

                yippee1 =
                    { yippee | targetPos = targetPos }

                state1 =
                    { state | yippee = yippee1 }
            in
            ( { model | state = state1 }, Cmd.none )

        SaveDone ->
            ( model, Cmd.none )


frame : { a | delta : Float } -> State -> ( State, Cmd Msg )
frame { delta } { yippee, apples } =
    let
        height =
            100

        wantedDist =
            200

        maxSpeed =
            100
    in
    let
        -- TODO: Add half height to y
        diff =
            Vec2.sub (Vec2.fromRecord yippee.targetPos) (Vec2.fromRecord yippee.pos)

        dist =
            Vec2.length diff

        targetAngle =
            atan2 (Vec2.getY diff) (Vec2.getX diff)

        wantedMove =
            cos targetAngle * (dist - wantedDist)

        pos =
            { y = yippee.pos.y, x = yippee.pos.x + delta * clamp -maxSpeed maxSpeed wantedMove }

        yippee1 =
            { yippee | pos = pos, flipped = Vec2.getX diff > 0 }
    in
    let
        state =
            { yippee = yippee1, apples = List.filter (\a -> not <| appleEaten yippee a) apples }
    in
    ( state, Ports.requestSave state )


appleEaten : Yippee -> Apple -> Bool
appleEaten yippee { pos } =
    Debug.log "dist" (Vec2.distanceSquared (vec2 yippee.pos) (vec2 pos)) < 100 * 100


clamp : Float -> Float -> Float -> Float
clamp a b x =
    if x < a then
        a

    else if b < x then
        b

    else
        x


vec2 =
    Vec2.fromRecord


view : Model -> Html Msg
view model =
    div []
        ([ viewYippee model.resources model.state.yippee ]
            ++ List.map (viewApple model.resources) model.state.apples
        )


viewYippee : Resources -> Yippee -> Html Msg
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
        , css
            [ transforms
                [ centerX
                , rotate (deg rotation)
                ]
            , Css.width (px 40)
            ]
        ]
        []


screenPosition : Vec -> Attribute a
screenPosition { x, y } =
    css
        [ position fixed
        , bottom (px y)
        , left (px x)
        ]


centerX =
    translateX (pct -50)


emptyAttr : Attribute a
emptyAttr =
    css []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.frame Frame
        , Ports.saveDone (\_ -> SaveDone)
        , Ports.mouseMove MouseMove
        ]
