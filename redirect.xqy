(:
Copyright 2012 MarkLogic Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
:)


xquery version "1.0-ml";
import module namespace rest="http://marklogic.com/appservices/rest" at "/MarkLogic/appservices/utils/rest.xqy";
import module namespace requests="http://marklogic.com/heatmap/requests" at "requests.xqy";

(: Process requests to be handled by this endpoint module. :)
let $request := $requests:options/rest:request [@endpoint = "/redirect.xqy"][1]
let $params  := rest:process-request($request)

(: Get parameter/value map from request. :)
let $query  := fn:string-join(
    for $param in map:keys($params)
    where $param != "__ml_redirect__"
    return
      for $value in map:get($params, $param)
      return
        fn:concat($param, "=", fn:string($value)), "&amp;")

(: Return the adjusted url along with any parameters. :)
let $ruri   := fn:concat(map:get($params, "__ml_redirect__"),
                      if ($query = "") then ""
                      else fn:concat("?", $query))
(: Set response code and redirect to new URL. :)
return
  (xdmp:set-response-code(301, "Moved permanently"),
   xdmp:redirect-response($ruri))