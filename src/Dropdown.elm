module Dropdown exposing
    ( Dropdown, Event(..), Msg, Settings
    , defaultSettings, init, initWithSettings, update, view
    )

{-| This library provides a dropdown that handles items of any type `t`.
Items are not part of this component's internal model, meaning that there is a
single source of truth: your own `Model`.
It sets the selected item by value, rather than by index, which can be useful
when the set of items is dynamic. User selection is communicated by returning
an Event that contains the selected item.


# Types

@docs Dropdown, Event, Msg, Settings


# Functions

@docs defaultSettings, init, initWithSettings, update, view

-}

import Html exposing (Html, a, button, div, li, span, text, ul)
import Html.Attributes exposing (class)
import Html.Events exposing (custom, onBlur, onClick)
import Json.Decode as Json


{-|

@docs Opaque type representing messages used to change internal state.

-}
type Msg t
    = Toggle State
    | Select t


{-|

@docs Events that are used to communicate changes in state relevant to
@docs users of this component.

-}
type Event t
    = Unchanged
    | ItemSelected t


{-|

@docs The Dropdown (opaque) model.

-}
type Dropdown
    = Dropdown Model


{-|

@docs Customization settings.

-}
type alias Settings =
    { placeHolder : String
    , containerClass : String
    , openedClass : String
    , closedClass : String
    , buttonClass : String
    , arrowUpClass : String
    , arrowDownClass : String
    , itemClass : String
    , activeItemClass : String
    }


{-| Internal state.
-}
type State
    = Opened
    | Closed


{-| Internal model.
-}
type alias Model =
    { settings : Settings
    , state : State
    }


{-|

@docs Initialize a Dropdown with default settings.

-}
init : Dropdown
init =
    Dropdown
        { settings = defaultSettings
        , state = Closed
        }


{-|

@docs Initialize a Dropdown with custom settings.

-}
initWithSettings : Settings -> Dropdown
initWithSettings settings =
    Dropdown
        { settings = settings
        , state = Closed
        }


{-|

@docs Default look and feel settings.

-}
defaultSettings : Settings
defaultSettings =
    { placeHolder = "Select ..."
    , containerClass = "dropdown"
    , openedClass = "dropdown-menu show"
    , closedClass = "dropdown-menu"
    , buttonClass = "button-as-dropdown dropdown-toggle form-control"
    , arrowUpClass = "arrow glyphicon glyphicon-triangle-top"
    , arrowDownClass = "arrow glyphicon glyphicon-triangle-bottom"
    , itemClass = "dropdown-item"
    , activeItemClass = " dropdown-item active"
    }


toggle : State -> State
toggle state =
    case state of
        Opened ->
            Closed

        Closed ->
            Opened


{-|

@docs Update a Dropdown. Returns the updated Dropdown and an Event
@docs that communicates changes that are relevant to the outside world, if
@docs any (e.g. item selection).

-}
update : Msg t -> Dropdown -> ( Dropdown, Event t )
update msg (Dropdown model) =
    case msg of
        Toggle state ->
            ( Dropdown { model | state = state }
            , Unchanged
            )

        Select item ->
            ( Dropdown { model | state = toggle model.state }
            , ItemSelected item
            )


{-|

@docs Render a Dropdown using provided items, optional selected item, and
@docs function that returns a string representation of an item.

-}
view : List t -> Maybe t -> (t -> String) -> Dropdown -> Html (Msg t)
view items selectedItem descriptionOf (Dropdown { settings, state }) =
    let
        ( clazz, newState, arrow ) =
            case state of
                Closed ->
                    ( settings.closedClass, Opened, settings.arrowDownClass )

                Opened ->
                    ( settings.openedClass, Closed, settings.arrowUpClass )

        isActive item =
            case selectedItem of
                Just selection ->
                    selection == item

                _ ->
                    False

        menuItems =
            List.map
                (\item ->
                    viewItem
                        item
                        descriptionOf
                        (isActive item)
                        settings.itemClass
                        settings.activeItemClass
                )
                items
    in
    div
        [ class settings.containerClass ]
        [ button
            [ class settings.buttonClass
            , onClick (Toggle newState)
            , onBlur (Toggle Closed)
            ]
            [ text
                (selectedItem
                    |> Maybe.map descriptionOf
                    |> Maybe.withDefault settings.placeHolder
                )
            , span [ class arrow ] []
            ]
        , ul
            [ class clazz
            ]
            menuItems
        ]


onItem : String -> msg -> Html.Attribute msg
onItem ev msg =
    Json.succeed msg
        |> Json.map (\value -> { message = value, preventDefault = False, stopPropagation = True })
        |> custom ev


viewItem : t -> (t -> String) -> Bool -> String -> String -> Html (Msg t)
viewItem item descriptionOf active itemClass activeItemClass =
    let
        attrs =
            if active then
                [ class activeItemClass, onItem "mousedown" (Select item) ]

            else
                [ class itemClass, onItem "mousedown" (Select item) ]
    in
    a
        attrs
        [ text (descriptionOf item) ]
