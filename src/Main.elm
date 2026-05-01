module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Markdown
import Url
import Url.Parser as Parser exposing (Parser, (</>))


type alias PostMetadata =
    { slug : String
    , title : String
    , date : String
    , summary : String
    }


postsMetadata : List PostMetadata
postsMetadata =
    [
      { slug = "ai-debilitation"
      , title = "ai debilitation and the value of sporadic thoughts"
      , date = "April 26, 2026"
      , summary = "think man think"
      },
      { slug = "next-gen-generators"
      , title = "next(generators)"
      , date = "January 21, 2021"
      , summary = "generators beyond the basics"
      }
    ]


-- ROUTING
type Route
    = Home
    | PostDetail String
    | NotFound


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map PostDetail (Parser.s "post" </> Parser.string)
        ]


-- MODEL
type alias Model =
    { key : Nav.Key
    , route : Route
    , contents : Dict String String   -- slug -> markdown body
    }


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotContent String (Result Http.Error String)


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        route =
            Parser.parse parser url |> Maybe.withDefault NotFound
    in
    ( { key = key
      , route = route
      , contents = Dict.empty
      }
    , case route of
        PostDetail slug ->
            fetchContent slug

        _ ->
            Cmd.none
    )


fetchContent : String -> Cmd Msg
fetchContent slug =
    Http.get
        { url = "/posts/" ++ slug ++ ".md"
        , expect = Http.expectString (GotContent slug)
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked (Browser.Internal url) ->
            let
                newRoute =
                    Parser.parse parser url |> Maybe.withDefault NotFound
            in
            case newRoute of
                PostDetail slug ->
                    if Dict.member slug model.contents then
                        ( { model | route = newRoute }
                        , Nav.pushUrl model.key (Url.toString url)
                        )
                    else
                        ( { model | route = newRoute }
                        , Cmd.batch
                            [ fetchContent slug
                            , Nav.pushUrl model.key (Url.toString url)
                            ]
                        )

                _ ->
                    ( { model | route = newRoute }
                    , Nav.pushUrl model.key (Url.toString url)
                    )

        LinkClicked (Browser.External href) ->
            ( model, Nav.load href )

        UrlChanged url ->
            let
                newRoute =
                    Parser.parse parser url |> Maybe.withDefault NotFound
            in
            case newRoute of
                PostDetail slug ->
                    if Dict.member slug model.contents then
                        ( { model | route = newRoute }, Cmd.none )
                    else
                        ( { model | route = newRoute }, fetchContent slug )

                _ ->
                    ( { model | route = newRoute }, Cmd.none )

        GotContent slug result ->
            case result of
                Ok body ->
                    ( { model | contents = Dict.insert slug body model.contents }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )


-- VIEW
view : Model -> Browser.Document Msg
view model =
    { title = "dankey@blog"
    , body =
        [ div [ style "position" "fixed"
              , style "top" "25px"
              , style "left" "40px"
              , style "z-index" "100"
              ]
            [ a [ href "/"
                , style "color" "#f0f0f0"
                , style "text-decoration" "none"
                , style "font-size" "1.65em"
                , style "font-weight" "700"
                , style "font-family" "'quicksand'"
                , style "letter-spacing" "-0.5px"
                , style "z-index" "-1"
                ]
                [ text "dankey@blog" ]
            ]
        , div [ style "max-width" "760px"
              , style "margin" "100px auto 40px auto"
              , style "padding" "55px 45px 60px 45px"
              , style "padding" "0 40px 50px 40px"
              , style "font-family" "'quicksand'"
              , style "line-height" "1.65"
              , style "font-size" "1.05em"
              , style "background" "rgba(30, 30, 38, 0.88)"
              , style "border-radius" "18px"
              , style "box-shadow" "0 25px 50px rgba(0, 0, 0, 0.35)"
              , style "color" "#f0f0f0"
              ]
            [ case model.route of
                Home ->
                    viewHome

                PostDetail slug ->
                    viewPost model slug

                NotFound ->
                    viewNotFound
            ]
        ]
    }


viewHome : Html Msg
viewHome =
    div []
        [ div [ style "color" "#666", style "padding-top" "20px" ] []
        , div [] (List.map viewPostTeaser postsMetadata)
        ]


viewPostTeaser : PostMetadata -> Html Msg
viewPostTeaser post =
    div [ style "margin-bottom" "40px", style "border-bottom" "1px solid #ddd", style "padding-bottom" "25px" ]
        [ h3 [] [ a [ href ("/post/" ++ post.slug), style "text-decoration" "none", style "color" "#0066cc" ] [ text post.title ] ]
        , p [ style "color" "#666", style "margin" "4px 0 12px 0" ] [ text post.date ]
        , p [] [ text post.summary ]
        ]


viewPost : Model -> String -> Html Msg
viewPost model slug =
    case List.filter (\p -> p.slug == slug) postsMetadata |> List.head of
        Just post ->
            case Dict.get slug model.contents of
                Just body ->
                    let defaults = Markdown.defaultOptions in

                    div []
                        [ h6 [ class "post-title" ] [ text post.title ]
                        , p [ class "post-date" ] [ text post.date ]
                        , Markdown.toHtmlWith { defaults | sanitize = False }  [ class "markdown-content" ] body
                        ]

                Nothing ->
                    text ""

        Nothing ->
            viewNotFound


viewNotFound : Html Msg
viewNotFound =
    div []
        [ h2 [] [ text "404 — Page not found" ]
        , a [ href "/" ] [ text "← Go home" ]
        ]


-- MAIN
main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }
