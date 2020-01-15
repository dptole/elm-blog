module Utils.Css exposing (..)

import Svg.Comments

import Utils.Types

import Html
import Html.Attributes



htmlStyles : { special_msg : Utils.Types.SpecialMsg, pagination_scroll : Int } -> Html.Html msg
htmlStyles { special_msg, pagination_scroll } =
  let
    hide_overflow =
      case special_msg of
        Utils.Types.NoSpecial ->
          ""

        _ ->
          """
html,body{overflow: hidden;}
.sign-in-form > :nth-child(n+2) {margin-top: 10px;}
.sign-in-form > h1 {margin-top: 0;}
"""

    special_css =
      hide_overflow

  in
    Html.node
      "style"
      [ Html.Attributes.class "main_css" ]
      [ Html.text ( special_css ++ """
:root {
  --header-background-color: #333333;
  --body-background-color: #999999;
  --header-color: white;
  --default-border-color: darkslategrey;
  --default-button-color: var(--body-background-color);
  --input-text-border-width: 4px;
  --create-button-color: #8bc34a;
  --visited-link-color: #312073;
  --default-hover-table-line: #90a4ae;
}

* {
  font-family: Handlee;
  font-size: 18px;
  box-sizing: border-box;
  transition: all .4s;
}

html {
  background-color: var(--header-background-color);
}

body {
  padding: 0;
  margin: 0;
  animation: imgshow 2s;
}

hr {
  border: 1px solid #616161;
  margin: 20px 0;
}

table tbody {
  word-break: break-all;
}

input[type=button].btn-danger,
button.btn-danger
{
  --default-button-color: salmon;
  --default-border-color: salmon;
}

input[type=button].btn-create,
button.btn-create
{
  --default-button-color: var(--create-button-color);
  --default-border-color: var(--create-button-color);
}

input[type=button],
button
{
  border: 1px solid var(--default-border-color);
  background-color: var(--default-button-color);
  line-height: 150%;
}

input[type=button]:disabled,
button:disabled
{
  --default-button-color: darkgrey;
  --default-border-color: darkgrey;
  color: white;
}

input[type=text],
input[type=password],
textarea
{
  outline-color: dodgerblue;
  outline-style: solid;
  outline-width: 0;
  border: none;
  padding: 5px 10px;
  margin-bottom: 15px;
}

input[type=text]:focus,
input[type=password]:focus,
textarea:focus
{
  outline-width: var(--input-text-border-width);
}

table:not(.publishedpost):not(.postcomments) {
  background-color: transparent;
}

table.hoverable tbody tr:hover {
  background-color: var(--default-hover-table-line);
}

a {
  display: inline-block;
  text-decoration: none;
  color: blue;
  font-weight: bold;
}

a:visited {
  color: var(--visited-link-color);
}

div.header,
div.footer
{
  background-color: var(--header-background-color);
  color: var(--header-color);
  padding: 10px;
}

div.header > ul > li * {
  color: var(--header-color) !important;
  cursor: pointer;
}

div.header > ul > li a:hover,
div.header > ul > li a:focus
{
  text-decoration: underline;
}

div.header ul {
  list-style: none;
}

div.header > ul {
  margin: 0;
  padding: 0;
}

div.header > ul > li {
  display: inline-block;
}

div.header > ul > li + li:before {
  content: "|";
  padding: 0px 10px;
}

div.header > ul.right-ul > li > span:hover + ul,
div.header > ul.right-ul > li > span:active + ul,
div.header > ul.right-ul > li > span:focus + ul,
div.header > ul.right-ul > li > ul:hover
{
  opacity: 1;
  height: auto;
  padding: 10px 30px;
  background-color: var(--header-background-color);
}

div.header > ul.right-ul > li > ul > li > span.signoff-link:hover
{
  text-decoration: underline;
}

div.header > ul.right-ul > li > ul > li > ul
{
  padding-left: 1em;
}

div.header > ul.left-ul {
  display: inline;
}

div.header > ul.right-ul {
  float: right;
}

div.header > ul.right-ul > li > ul {
  transition: opacity .5s;
  list-style: none;
  overflow: hidden;
  height: 0;
  margin: 0;
  padding: 0;
  opacity: 0;
  position: absolute;
  background-color: white;
  box-shadow: 2px 2px 10px black;
  z-index: 100;
  right: 5px;
}

div.body-html,
div.body
{
  background-color: var(--body-background-color);
}

div.body {
  padding: 10px 10px 100px 10px;
  margin: 0 auto;
  width: 70%;
}

div.body > .loadingdotsafter {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 300px;
  width: 100%;
}

div.body .sign-up-container,
div.body .sign-in-container
{
  display: flex;
  justify-content: center;
  align-items: center;
}

div.body > div > h1:first-child,
div.body > div > div > h1:first-child,
div.body > div > div > div > h1:first-child,
div.body > form > h1:first-child
{
  margin: 20px 0;
}

.post-show-private-post {
  border-bottom-color: var(--body-background-color);
}

textarea.post-comment-textarea {
  width: 100%;
}

.post-comment-textarea-container {
  margin: 0 auto;
  width: 400px;
}

.post-show-private-post-status {
  font-weight: bold;
  text-transform: uppercase;
}

.post-show-private-actions td *,
.post-review-actions td *,
.comment-review-actions td *
{
  opacity: 0;
}

.post-show-private-post:hover + .post-show-private-actions,
.post-review-details-post:hover + .post-review-actions,
.comment-review-content:hover + .comment-review-actions
{
  background-color: var(--default-hover-table-line);
}

.post-show-private-post:hover + .post-show-private-actions td *,
.post-show-private-actions:hover td *,
.post-review-details-post:hover + .post-review-actions td *,
.post-review-actions:hover td *,
.comment-review-content:hover + .comment-review-actions td *,
.comment-review-actions:hover td *
{
  opacity: 1;
}

.post-show-private-actions button:nth-child(n+2),
.post-show-private-actions input[type=button]:nth-child(n+2)
{
  margin-left: 10px;
}

.post-show-private {
  width: 100%;
}


.post-review-prompt-rejection > *:nth-child(n+2),
.post-review-prompt-publication > *:nth-child(n+2)
{
  margin-left: 10px;
}

.post-show-remove > button:nth-child(n+2),
.post-show-remove > input[type=button]:nth-child(n+2),
.post-show-send-review > button:nth-child(n+2),
.post-show-send-review > input[type=button]:nth-child(n+2)
{
  margin-left: 10px;
}

.published-at {
  font-style: italic;
}

.text-red {
  color: red;
}

.text-black {
  color: black;
}

.sign-in-username:disabled {
  background-color: white;
  color: black;
}

.modal-container {
  opacity: 0;
  animation: imgshow .4s forwards;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  position: fixed;
  height: 100%;
  width: 100%;
  top: 0;
  left: 0;
  z-index: 101;
}

.modal-container > .modal-container-box {
  max-width: 400px;
  background-color: black;
  width: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: column;
  padding: 20px 0;
  box-sizing: border-box;
  position: relative;
}

.modal-container > .modal-container-box > * {
  width: 66%;
  text-align: center;
}

.modal-container > .modal-container-box > .modal-container-close {
  position: absolute;
  width: 30px;
  height: 30px;
  line-height: 30px;
  border-radius: 50%;
  background-color: black;
  color: white;
  font-weight: bold;
  right: -15px;
  top: -15px;
  font-size: 24px;
  cursor: pointer;
}

.modal-container > .modal-container-box button {
  color: white;
}

div.publishedpost-page-container {
  text-align: center;
}

img.publishedpost-page-image {
  max-height: 190px;
  max-width: 298px;
  animation: imgshow 2s;
}

img.loading-page-image {
  display: none;
}

table.publishedpost,
table.postcomments
{
  margin: 30px auto;
}

table.publishedpost td.publishedpost-page,
table.postcomments td.postcomments-message
{
  font-family: courier;
}

table.publishedpost td.publishedpost-page,
table.postcomments td.postcomments-message
{
  word-break: break-all;
  position: relative;
  box-shadow: 0 0 10px;
  width: 400px;
  height: 300px;
}

svg.postcomments-message {
  width: 400px;
  height: 300px;
}

table.comment-review {
  word-break: break-all;
  width: 100%;
}

table.publishedpost img.reviewpost-page-image {
  max-width: 400px;
  width: 100%;
}

table.publishedpost td.left-arrow,
table.postcomments td.left-arrow
{
  width: 50px;
}

table.publishedpost td.right-arrow,
table.postcomments td.right-arrow
{
  width: 50px;
}

table.postcomments td.postcomments-author,
table.postcomments td.postcomments-replies
{
  text-align: center;
}

table.publishedpost td.right-arrow > input,
table.postcomments td.right-arrow > input
{
  float: right;
}

.width-100 {
  width: 100%;
}

.txtloading-page-image {
  animation: imgblink 1s alternate infinite;
}

.loadingdotsafter:after {
  animation: loadingdotsafter 1s infinite;
  content: "";
}

.postcreate-page-container {
  margin-left: """ ++ ( String.fromInt pagination_scroll ) ++ """px;
  overflow: auto;
  display: block;
  margin: 20px auto;
  height: 410px;
  border: 1px solid black;
}

.postcreate-page-container > hr {
  margin: 10px 0;
}

.postcreate-page-container::-webkit-scrollbar {
  width: 10px;
  height: 10px;
  background-color: #888888;
}

.postcreate-page-container::-webkit-scrollbar-thumb {
  background-color: #333333;
}

.post-create-form .post-create-submit-message {
  margin-top; 10px;
  font-size: 20px;
}

.post-create-pagination {
  margin: 30px auto;
  max-width: 300px;
  text-align: center;
}

.post-create-next-page {
  float: right;
}

.post-create-previous-page {
  float: left;
}

.post-create-page-number {
  vertical-align: bottom;
}

.postcreate-page-block {
  padding: 10px;
  box-sizing: border-box;
}

.postcreate-page-block textarea {
  font-size: 24px;
}

.postcreate-page-block textarea,
.postcreate-page-block input[type=text]
{
  width: 100%;
}

.postcreate-page-block .post-create-page-kind {
  margin-bottom: 20px;
}

.post-create-form .post-create-title {
  width: 100%;
}

.post-create-tags-container {
  margin: 10px 0;
}

.post-create-tags > div {
  margin-top: 10px;
}

.post-create-tag > input[type=text] {
  margin: 0 10px 0 0;
}

.post-create-control > :nth-child(n+2),
.post-review-control > :nth-child(n+2),
.comment-review-control > :nth-child(n+2),
.post-review-add-note > *
{
  margin-left: 10px;
}

.comment-reply-container {
  margin-top: 20px;
}

.comment-reply-expand ~ .comment-reply-container {
  opacity: 0;
  height: 0;
  overflow: hidden;
}

.comment-reply-expand:checked ~ .comment-reply-container {
  opacity: 1;
  height: 100%;
}

.comment-reply-expand {
  width: 0;
  text-transform: uppercase;
  cursor: pointer;
}

.comment-reply-expand:before {
  content: "↓";
  float: left;
}

.comment-reply-expand:checked:before {
  content: "↑";
}

.comment-reply-expand:after {
  content: " Expand";
  margin-left: 10px;
}

.comment-reply-expand:checked:after {
  content: " Collapse";
}

.comment-reply-control > *:nth-child(n+2) {
  margin-left: 10px;
}

table.hoverable[rules=rows] tbody tr td {
  border-left: 1px solid #888888;
}

fieldset.comment-reply-recursive fieldset.comment-reply-recursive,
fieldset.comment-reply-recursive + fieldset.comment-reply-recursive
{
  margin-top: 20px;
}

div.comment-replies-container > div > fieldset.comment-reply-recursive > legend {
  margin-bottom: 10px;
}

.webgl-profile-avatar-container {
  display: flex;
}

.webgl-profile-avatar-container > canvas {
  margin-right: 20px;
  width: 300px;
  height: 300px;
  background-color: white;
}

.webgl-profile-avatar-container > canvas.grey-border {
  border: 1px solid grey;
}

.webgl-profile-avatar-container .webgl-tools-header {
  margin-top: 0;
  display: inline;
}

.webgl-tool-editing-exit {
  margin-right: 10px;
  vertical-align: middle;
}

.webgl-tools-prop-container > div {
  margin-top: 10px;
}

.webgl-tools-prop-colors-container > div {
  outline: 1px solid black;
}

.webgl-tools-prop-colors-container > div:focus {
  outline: 2px solid red;
}

.webgl-tools-prop-colors-container > div:nth-child(n+2) {
  margin-left: 5px;
}

.graph-flex-vert-spc-around canvas,
.graph-flex-vert-spc-around table
{
  box-shadow: 0 0 10px;
}

.graph-flex-vert-spc-around {
  display: flex;
  align-items: center;
  justify-content: space-around;
}

.errors-from-http {
  margin: 20px 0;
}

@media (max-width: 768px) {
  * {
    font-size: 24px;
  }

  .webgl-profile-avatar-container {
    flex-direction: column-reverse;
  }

  .post-comment-textarea-container {
    width: 100%;
  }

  div.body {
    padding: 10px 10px 100px 10px;
    width: 100%;
  }
}

@media (max-width: 319px) {
  html:after {
    content: "The device must be at least 320px wide";
    font-size: 24px;
    display: flex;
    align-items: center;
    height: 100vh;
    width: 100vw;
    text-align: center;
    padding: 20px;
    box-sizing: border-box;
    animation: imgshow 2s;
    color: white;
  }
  body {
    display: none;
  }
}

@keyframes imgblink {
  from { opacity: 1; }
  to { opacity: 0; }
}

@keyframes imgshow {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes loadingdotsafter {
  0%   { content: "\\A0\\A0\\A0"; }
  16%  { content: ".\\A0\\A0"; }
  33%  { content: "..\\A0"; }
  49%  { content: "..."; }
  68%  { content: "\\A0.."; }
  84%  { content: "\\A0\\A0."; }
  100% { content: "\\A0\\A0\\A0"; }
}

""" )
    ]


svgStyles : Utils.Types.SvgCommentsModel -> Html.Html msg
svgStyles model =
  let
    normal_transition_duration = 1.0

    line_animation_duration = normal_transition_duration * 2

    loading_animation_duration = normal_transition_duration / 2

    last_move_horizontal_line =
      case model.confs.last_sqms of
        ( x, y ) ->
          case model.last_move of
            ( mx, my ) ->
              if
                x == model.confs.sqm_x && mx > 0 ||
                y == model.confs.sqm_y && my < 0 ||
                (
                  mx == 0 &&
                  my == mx
                )
              then
                ""
              else
                "50% { opacity: 0; }"
          

    default_content = """
@keyframes loading-more-comments {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes rect-loading-more-comments {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes reply-line {
  0% { opacity: 0; }
  """ ++ last_move_horizontal_line ++ """
  100% { opacity: 1; }
}

svg {
  overflow: hidden;
}

svg .h-circle-comment,
svg .v-circle-comment,
svg .h-line-next-comment,
svg .v-line-next-comment,
svg .h-load-more-comments,
svg .v-load-more-comments,
svg .h-line-next-reply,
svg .v-line-next-reply,
div.svgcommentscontainer
{
  transition: all """ ++ ( String.fromFloat normal_transition_duration ) ++ """s;
  transition-timing-function: ease-in-out;
}

svg .h-line-next-reply
{
  animation: reply-line """ ++ ( String.fromFloat line_animation_duration ) ++ """s forwards;
}

svg .h-circle-comment,
svg .v-circle-comment
{
  cursor: pointer;
}

table td.postcomments-message .expandedcomment {
  background-color: white;
}

table.postcomments td.postcomments-message canvas {
  margin: 0 auto;
}

table.postcomments td.postcomments-message .loadingdotsafter {
  text-align: center;
}

div.svgcommentscontainer svg {
  position: absolute;
  top: 0;
  left: 0;
}

svg text.v-load-more-comments,
svg text.h-load-more-comments
{
  opacity: 0;
  animation: loading-more-comments """ ++ ( String.fromFloat loading_animation_duration ) ++ """s ease-in-out alternate infinite;
}

svg rect.v-text-loading-bg,
svg rect.h-text-loading-bg
{
  opacity: 0;
  animation: rect-loading-more-comments """ ++ ( String.fromFloat loading_animation_duration ) ++ """s ease-in-out forwards;
}

"""

    svg_height = model.confs.height

    svg_width = model.confs.width

    expanded_comment_height = svg_height - 20

    expanded_comment_width = svg_width - 20

    circle_comment_translate_y = model.confs.sqm_y * svg_height

    circle_comment_translate_x = model.confs.sqm_x * svg_width

    circle_comment = """
div.expanded-comment
{
  display: flex;
  justify-content: center;
  align-items: center;
  margin: 0 auto;
  background-color: rgba(0, 0, 0, 0.5);
  color: white;
  overflow: auto;
  box-sizing: border-box;
  padding: 10px;
  max-width: """ ++ ( String.fromInt expanded_comment_width ) ++ """px;
  max-height: """ ++ ( String.fromInt expanded_comment_height ) ++ """px;
}

svg .h-line-next-reply,
svg .v-line-next-reply,
svg .h-circle-comment,
svg .v-circle-comment,
svg .h-line-next-comment,
svg .v-line-next-comment
{
  transform: translate(
    -""" ++ ( String.fromInt circle_comment_translate_x ) ++ """px,
    """ ++ ( String.fromInt circle_comment_translate_y ) ++ """px
  );
}
"""
    svg_styles_content = default_content ++ circle_comment

  in
    Html.node
      "style"
      [ Html.Attributes.class "svg_css" ]
      [ Html.text svg_styles_content ]






