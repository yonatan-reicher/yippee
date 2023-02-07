module Model exposing (Apple, Flags, Model, Resources, State, Vec, Yippee)


type alias Flags =
    Model1 (Maybe State)


type alias Model1 state =
    { state : state
    , resources : Resources
    }


type alias Model =
    Model1 State


type alias State =
    { yippee : Yippee
    , apples : List Apple
    }


type alias Yippee =
    { pos : Vec
    , targetPos : Vec
    , flipped : Bool
    }


type alias Apple =
    { pos : Vec
    , rol : Float
    , rotation : Float
    }


type alias Resources =
    { yippeeUrl : String
    , appleUrl : String
    }


type alias Vec =
    { x : Float, y : Float }
