 xquery version "3.0";

module namespace gallery="http://exist-db.org/xquery/gallery";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";

declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace html="http://www.w3.org/1999/xhtml";


declare 
    %templates:wrap function gallery:edit-gallery-items($node as node(), $model as map(*)) {
        let $entries := gallery:get-slideshow-editor-dummy-atom-feed()
        let $imageList :=
            for $entry in $entries//atom:entry
                return
                <li id="{$entry/atom:id}" class="container gallery-item-row img-rounded">
                    <div class="row">
                        <div class="span2 gallery-item-image">
                            <a title="{$entry/atom:title/text()}" name="{$entry/atom:title/text()}" class="thumb" target="blank_"
                                href="http://farm3.static.flickr.com/{data($entry/atom:link/@href)}.jpg">
                                <img alt="{$entries/atom:title}" class="img-polaroid" 
                                     src="http://farm3.static.flickr.com/{data($entry/atom:link/@href)}_s.jpg"/>
                            </a>
                        </div>
                        <div class="span10 gallery-item-caption">
                            <h3>{$entry/atom:title}</h3>
                            <div id="{$entry/atom:id}-desc"class="image-desc">{$entry/atom:content/*}</div>
                            <div class="gallery-item-controls pull-right">
                                <a class="btn" onclick="showModal('{$entry/atom:id}')"><i class="icon-edit"></i></a>
                                <a class="btn" onclick="removeItem('{$entry/atom:id}')"><i class="icon-remove"></i></a>
                                <a class="btn" onclick="moveUp('{$entry/atom:id}')"><i class="icon-arrow-up"></i></a>
                                <a class="btn" onclick="moveDown('{$entry/atom:id}')"><i class="icon-arrow-down"></i></a>
                            </div>
                        </div>
                    </div>
                </li>
        return
            <ul id="gallery-items">
                { $imageList }
            </ul>
};

declare %private function gallery:gallery-selectable() {
        let $entries := gallery:get-slideshow-editor-dummy-atom-feed()
        let $imageList := 
            for $entry at $index in $entries//atom:entry
                return 
                    <li class="ui-widget-content" image-id="{$entry/atom:id/text()}">
                        <img alt="{$entries/atom:title}" src="http://farm3.static.flickr.com/{data($entry/atom:link/@href)}_s.jpg"/>
                        <div style="display:none">
                            <p class="atom-id">{$entry/atom:id/text()}</p>
                            <p class="atom-published">{$entry/atom:published/text()}</p>
                            <p class="atom-updated">{$entry/atom:updated/text()}</p>
                            <p class="atom-author">{$entry/atom:author/atom:name/text()}</p>
                            <p class="atom-title">{$entry/atom:title/text()}</p>
                            <p class="atom-content">{$entry/atom:content/html:div/text()}</p>
                        </div>
                    </li>
        return 
            <div id="thumbs" class="navigation">
                <ul id="gallery-selection" class="thumbs noscript">
                    { $imageList }
                </ul>
            </div>
};


declare 
    %templates:wrap
    %templates:default("collection", "c_b9827ec8-6b66-5d98-9f5e-ca12b58044c4") 
    function gallery:search($node as node(), $model as map(*), $collection as xs:string, $query as xs:string?, $cached as item()*) {
    if ($query or $cached) then
        let $result := 
            if ($query) then
                (: @TODO  :)
                collection('/db/resources/commons')//vra:vra/vra:work[@refid=$collection]
            else
                $cached
        return (
            map {
                "result" := $result,
                "query" := $query
            },
            session:set-attribute("cached", $result)
        )
    else
        (
            map {
                "result" := collection('/db/resources/commons')//vra:vra/vra:work[@refid=$collection]
            }
        )
};

declare
    %templates:wrap
    %templates:default("start", 1)
    %templates:default("max", 10)
function gallery:search-result($node as node(), $model as map(*), $start as xs:integer, $max as xs:integer) {
    let $filteredResult := subsequence($model("result"), $start, $max)
    for $entry at $index in $filteredResult
        return
            templates:process($node/node(), map:new(($model, map {"entry" := $entry, "index" := ($start + $index -1)})))            
};

declare 
    %templates:default("start", 1)
    %templates:default("max", 10)
function gallery:pagination-previous($node as node(), $model as map(*), $start as xs:integer, $max as xs:integer) {
    let $total := count($model("result"))
    return
        if ($start > 1) then
            element { node-name($node) } {
                $node/@* except $node/@href,
                attribute href { "javascript:loadImages("||$start - $max || "," || $max || ")" },
                $node/node()
            }
        else
            ()
};

declare 
    %templates:default("start", 1)
    %templates:default("max", 10)
function gallery:pagination-next($node as node(), $model as map(*), $start as xs:integer, $max as xs:integer) {
    let $total := count($model("result"))
    return
        if ($start + $max < $total) then
            element { node-name($node) } {
                $node/@* except $node/@href,
                attribute href { "javascript:loadImages("||$start + $max || "," || $max || ")" },
                $node/node()
            }
        else
            ()
};

declare
    %templates:wrap
    function gallery:result-image($node as node(), $model as map(*)) {    
        let $entry := $model("entry")    
        return 
            for $image in $entry//vra:relationSet
                let $imageId := substring($image/vra:relation[1]/@relids , 3)
                return 
                    if($imageId) 
                    then (
                            <img src="http://kjc-ws2.kjc.uni-heidelberg.de:83/images/service/download_uuid/priya_paul/{$imageId}?width=100&amp;height=100&amp;crop_type=middle" class="relatedImage"/>,                           
                            <div style="display:none">
                                <p class="ref-id">{$imageId}</p>
                            </div>
                    )else ()
    };


declare 
    %templates:wrap 
    function gallery:slideshow-editor-gallery($node as node(), $model as map(*)) {
        let $vraWorkRecords  := collection('/db/resources/commons/Priya_Paul_Collection')/vra:vra/vra:work
        let $imageList := for $vraWorkRecord in $vraWorkRecords[position() le 10]
            for $image in $vraWorkRecord//vra:relationSet
                let $imageId := substring($image/vra:relation[1]/@relids , 3)
                    return 
                        <li class="ui-widget-content" image-id="{$imageId}">                
                            <img src="http://kjc-ws2.kjc.uni-heidelberg.de:83/images/service/download_uuid/priya_paul/{$imageId}?width=100&amp;height=100&amp;crop_type=middle" class="relatedImage"/>                            
                            <div style="display:none">
                                <p class="ref-id">{$imageId}</p>
                            </div>
                        </li>
    return 
        <div id="thumbs" class="navigation">
            <ul id="gallery-selection" class="thumbs noscript">
                { $imageList }
            </ul>
        </div>
        
};


declare %private function gallery:get-slideshow-editor-dummy-atom-feed() {    
    <atom:feed>
        <atom:entry>
            <atom:id>b918effb-589a-494a-801b-cd77a762b1e7</atom:id>
            <atom:published>2013-01-15T09:04:14.452+01:00</atom:published>
            <atom:updated>2013-04-24T23:27:02.251+02:00</atom:updated>
            <atom:author>
                <atom:name>bine</atom:name>
            </atom:author>
            <atom:title>Blume 1</atom:title>
            <atom:link type="image/jpeg" href="3261/2538183196_8baf9a8015"/>
            <atom:content xmlns="http://www.w3.org/1999/xhtml" type="xhtml">
                <div>
                    Lorem ipsum dolor sit amet, blume1 consetetur sadipscing elitr, 
                    sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, 
                    sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
                </div>
            </atom:content>
        </atom:entry>
        <atom:entry>
            <atom:id>c918effb-589a-494a-802b-cd77a762b1e7</atom:id>
            <atom:published>2013-01-15T09:04:14.452+01:00</atom:published>
            <atom:updated>2013-04-24T23:27:02.251+02:00</atom:updated>
            <atom:author>
                <atom:name>bine</atom:name>
            </atom:author>
            <atom:title>Blume 2</atom:title>
            <atom:link type="image/jpeg" href="2404/2538171134_2f77bc00d9"/>
            <atom:content xmlns="http://www.w3.org/1999/xhtml" type="xhtml">
                <div>
                    Lorem ipsum dolor sit amet, Blume 2 consetetur sadipscing elitr, 
                    sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, 
                    sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
                </div>
                <div>
                    Lorem ipsum dolor sit amet, Blume 2 consetetur sadipscing elitr, 
                    sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, 
                    sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
                </div>
                <div>
                    Lorem ipsum dolor sit amet, Blume 2 consetetur sadipscing elitr, 
                    sed diam nonumy eirmod tempor ut labore et dolore magna aliquyam erat, 
                    sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
                </div>
            </atom:content>
        </atom:entry>
        <atom:entry>
            <atom:id>d918effb-589a-494a-803b-cd77a762b1e7</atom:id>
            <atom:published>2013-01-15T09:04:14.452+01:00</atom:published>
            <atom:updated>2013-04-24T23:27:02.251+02:00</atom:updated>
            <atom:author>
                <atom:name>bine</atom:name>
            </atom:author>
            <atom:title>Blume 3</atom:title>
            <atom:link type="image/jpeg" href="2093/2538168854_f75e408156"/>
            <atom:content xmlns="http://www.w3.org/1999/xhtml" type="xhtml">
                <div>
                    Lorem ipsum dolor sit amet, blume 3 consetetur sadipscing elitr, 
                    sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, 
                    sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
                </div>
            </atom:content>
        </atom:entry>
        <atom:entry>
            <atom:id>e918effb-589a-494a-804b-cd77a762b1e7</atom:id>
            <atom:published>2013-01-15T09:04:14.452+01:00</atom:published>
            <atom:updated>2013-04-24T23:27:02.251+02:00</atom:updated>
            <atom:author>
                <atom:name>bine</atom:name>
            </atom:author>
            <atom:title>Blume 4</atom:title>
            <atom:link type="image/jpeg" href="3153/2538167690_c812461b7b"/>
            <atom:content xmlns="http://www.w3.org/1999/xhtml" type="xhtml">
                <div>
                    Lorem ipsum dolor sit amet, blume 4 consetetur sadipscing elitr, 
                    sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, 
                    sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
                </div>
            </atom:content>
        </atom:entry>
        <atom:entry>
            <atom:id>e918effb-589a-494a-805b-cd77a762b1e99</atom:id>
            <atom:published>2013-01-15T09:04:14.452+01:00</atom:published>
            <atom:updated>2013-04-24T23:27:02.251+02:00</atom:updated>
            <atom:author>
                <atom:name>bine</atom:name>
            </atom:author>
            <atom:title>Blume 5</atom:title>
            <atom:link type="image/jpeg" href="3150/2538167224_0a6075dd18"/>
            <atom:content xmlns="http://www.w3.org/1999/xhtml" type="xhtml">
                <div>
                    Lorem ipsum dolor sit amet, blume 5 consetetur sadipscing elitr, 
                    sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, 
                    sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
                </div>
            </atom:content>
        </atom:entry>
        <atom:entry>
            <atom:id>b918effb-589a-494a-811b-cd77a762b1e7</atom:id>
            <atom:published>2013-01-15T09:04:14.452+01:00</atom:published>
            <atom:updated>2013-04-24T23:27:02.251+02:00</atom:updated>
            <atom:author>
                <atom:name>bine</atom:name>
            </atom:author>
            <atom:title>Rose 1</atom:title>
            <atom:link type="image/jpeg" href="3204/2537348699_bfd38bd9fd"/>
            <atom:content xmlns="http://www.w3.org/1999/xhtml" type="xhtml">
                <div>
                    Lorem ipsum dolor sit amet, rose 1 consetetur sadipscing elitr, 
                    sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, 
                    sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
                </div>
            </atom:content>
        </atom:entry>
        <atom:entry>
            <atom:id>c918effb-589a-494a-812b-cd77a762b1e7</atom:id>
            <atom:published>2013-01-15T09:04:14.452+01:00</atom:published>
            <atom:updated>2013-04-24T23:27:02.251+02:00</atom:updated>
            <atom:author>
                <atom:name>bine</atom:name>
            </atom:author>
            <atom:title>Rose 2</atom:title>
            <atom:link type="image/jpeg" href="3124/2538164582_b9d18f9d1b"/>
            <atom:content xmlns="http://www.w3.org/1999/xhtml" type="xhtml">
                <div>
                    Lorem ipsum dolor sit amet, rose 2 consetetur sadipscing elitr, 
                    sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, 
                    sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
                </div>
            </atom:content>
        </atom:entry>
        <atom:entry>
            <atom:id>d918effb-589a-494a-813b-cd77a762b1e7</atom:id>
            <atom:published>2013-01-15T09:04:14.452+01:00</atom:published>
            <atom:updated>2013-04-24T23:27:02.251+02:00</atom:updated>
            <atom:author>
                <atom:name>bine</atom:name>
            </atom:author>
            <atom:title>Rose 3</atom:title>
            <atom:link type="image/jpeg" href="3205/2538164270_4369bbdd23"/>
            <atom:content xmlns="http://www.w3.org/1999/xhtml" type="xhtml">
                <div>
                    Lorem ipsum dolor sit amet, rose 3 consetetur sadipscing elitr, 
                    sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, 
                    sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
                </div>
            </atom:content>
        </atom:entry>
        <atom:entry>
            <atom:id>e918effb-589a-494a-814b-cd77a762b1e7</atom:id>
            <atom:published>2013-01-15T09:04:14.452+01:00</atom:published>
            <atom:updated>2013-04-24T23:27:02.251+02:00</atom:updated>
            <atom:author>
                <atom:name>bine</atom:name>
            </atom:author>
            <atom:title>Rose 4</atom:title>
            <atom:link type="image/jpeg" href="3211/2538163540_c2026243d2"/>
            <atom:content xmlns="http://www.w3.org/1999/xhtml" type="xhtml">
                <div>
                    Lorem ipsum dolor sit amet, rose 4 consetetur sadipscing elitr, 
                    sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, 
                    sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
                </div>
            </atom:content>
        </atom:entry>
        <atom:entry>
            <atom:id>e918effb-589a-494a-815b-cd77a762b1e99</atom:id>
            <atom:published>2013-01-15T09:04:14.452+01:00</atom:published>
            <atom:updated>2013-04-24T23:27:02.251+02:00</atom:updated>
            <atom:author>
                <atom:name>bine</atom:name>
            </atom:author>
            <atom:title>Rose 5</atom:title>
            <atom:link type="image/jpeg" href="2315/2537343449_f933be8036"/>
            <atom:content xmlns="http://www.w3.org/1999/xhtml" type="xhtml">
                <div>
                    Lorem ipsum dolor sit amet, rose 5 consetetur sadipscing elitr, 
                    sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, 
                    sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
                </div>
            </atom:content>
        </atom:entry>
        <atom:entry>
            <atom:id>e918effb-589a-494a-816b-cd77a762b1e99</atom:id>
            <atom:published>2013-01-15T09:04:14.452+01:00</atom:published>
            <atom:updated>2013-04-24T23:27:02.251+02:00</atom:updated>
            <atom:author>
                <atom:name>bine</atom:name>
            </atom:author>
            <atom:title>Rose 6</atom:title>
            <atom:link type="image/jpeg" href="2167/2082738157_436d1eb280"/>
            <atom:content xmlns="http://www.w3.org/1999/xhtml" type="xhtml">
                <div>
                    Lorem ipsum dolor sit amet, rose 6 consetetur sadipscing elitr, 
                    sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, 
                    sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
                </div>
            </atom:content>
        </atom:entry>
    </atom:feed>
};