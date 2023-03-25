module YippeeParticles exposing (Model, Msg(..), init, update, view, subscriptions)


import Html exposing (Html)
import Html.Attributes exposing (style)
import Particle exposing (Particle)
import Particle.System as System exposing (System)
import Random exposing (Generator)
import Random.Extra
import Random.Float exposing (normal)
import Svg exposing (Svg)
import Svg.Attributes as SAttrs


type alias Model = 
    { system : System MyParticle 
    }


type Msg
    = HappyHearts
    | ScreamConfetti
    | ParticleMsg (System.Msg MyParticle)


type MyParticle
    = Confetti Confetti
    | Heart


type Confetti
    = Square
        { color : Color
        , rotations : Float
        , rotationOffset : Float
        }
    | Streamer
        { color : Color
        , length : Int
        }

type Color
    = Red
    | Pink
    | Yellow
    | Green
    | Blue



init : Model
init = Model <| System.init <| Random.initialSeed 0


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        ScreamConfetti x y ->
            ( { model | system = System.burst (Random.list 100 (particleAt x y)) model.system }
            , Cmd.none
            )

        ParticleMsg particleMsg ->
            ( { model | system = System.update particleMsg model.system }
            , Cmd.none
            )



-- views


view : Model -> Html msg
view model =
    Html.main_
        []
        [ System.view viewConfetti
            [ style "width" "100%"
            , style "height" "100%"
            , style "z-index" "1"
            , style "position" "fixed"
            , style "top" "0"
            , style "right" "0"
            , style "pointer-events" "none"
            ]
            model.system
        {-
        , Html.img
            [ Attrs.src "tada.png"
            , Attrs.width 64
            , Attrs.height 64
            , Attrs.alt "\"tada\" emoji from Mutant Standard"
            , style "position" "absolute"
            , style "left" (String.fromFloat (mouseX - 20) ++ "px")
            , style "top" (String.fromFloat (mouseY - 30) ++ "px")
            , style "user-select" "none"
            , style "cursor" "none"
            , style "z-index" "0"
            ]
            []
        -}
        ]

