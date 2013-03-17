###
Copyright 2013 Aral Balkan <aral@aralbalkan.com>
Copyright 2012 mocking@gmail.com

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Forked from Distal by mocking@gmail.com (https://code.google.com/p/distal/)
###

tally = (root, obj) ->
  "use strict"

  #create a duplicate object which we can add properties to without affecting the original
  wrapper = ->

  wrapper:: = obj
  obj = new wrapper()
  resolve = tally.resolve
  node = root
  doc = root.ownerDocument
  querySelectorAll = !!root.querySelectorAll

  #optimize comparison check
  innerText = (if "innerText" of root then "innerText" else "textContent")

  #attributes which don't support setAttribute()
  altAttr =
    className: 1
    class: 1
    innerHTML: 1
    style: 1
    src: 1
    href: 1
    id: 1
    value: 1
    checked: 1
    selected: 1
    label: 1
    htmlFor: 1
    text: 1
    title: 1
    disabled: 1

  formInputHasBody =
    BUTTON: 1
    LABEL: 1
    LEGEND: 1
    FIELDSET: 1
    OPTION: 1


  #TAL attributes for querySelectorAll call
  qdef = tally
  attributeWillChange = qdef.attributeWillChange
  textWillChange = qdef.textWillChange
  qif = qdef.qif or "data-tally-if"
  qrepeat = qdef.qrepeat or "data-tally-repeat"
  qattr = qdef.qattr or "data-tally-attribute"
  qtext = qdef.qtext or "data-tally-text"
  qdup = qdef.qdup or "data-tally-dummy"

  #output formatter
  format = qdef.format
  qdef = qdef.qdef or "data-tally-def"
  TAL = "*[" + [qdef, qif, qrepeat, qattr, qtext].join("],*[") + "]"
  html = undefined
  getProp = (s) ->
    this[s]


  #there may be generated node that are siblings to the root node if the root node
  #itself was a repeater. Remove them so we don't have to deal with them later
  tmpNode = root.parentNode
  tmpNode.removeChild node  while (node = root.nextSibling) and (node.qdup or (node.nodeType is 1 and node.getAttribute(qdup)))

  #if we generate repeat nodes and are dealing with non-live NodeLists, then
  #we add them to the listStack[] and process them first as they won't appear inline
  #due to non-live NodeLists when we traverse our tree
  listStack = undefined
  posStack = [0]
  list = undefined
  pos = 0
  attr = undefined
  attr2 = undefined
  `var undefined = {}._`

  #get a list of concerned nodes within this root node. If querySelectorAll is
  #supported we use that but it is treated differently because it is a non-live NodeList.
  if querySelectorAll

    #remove all generated nodes (repeats), so we don't have to deal with them later.
    #Only need to do this for non-live NodeLists.
    list = root.querySelectorAll("*[" + qdup + "]")
    node.parentNode.removeChild node  while (node = list[pos++])
    pos = 0

  listStack = [(if querySelectorAll then root.querySelectorAll(TAL) else root.getElementsByTagName("*"))]

  list = [root]

  loop
    node = list[pos++]

    #when finished with the current list, there are generated nodes and
    #their children that need to be processed.
    while not node and (list = listStack.pop())
      pos = posStack.pop()
      node = list[pos++]
    break unless node

    #creates a shortcut to an object
    #e.g., <section qdef="feeds main.sidebar.feeds">
    attr = node.getAttribute(qdef)
    if attr
      attr = attr.split(" ")

      #add it to the object as a property
      html = resolve(obj, attr[1])

      #the 3rd parameter if exists is a numerical index into the array
      if attr2 = attr[2]
        obj["#"] = parseInt(attr2) + 1
        html = html[attr2]
      obj[attr[0]] = html

    #shown if object is truthy
    #e.g., <img qif="item.unread"> <img qif="item.count gt 1">
    attr = node.getAttribute(qif)
    if attr
      attr = attr.split(" ")
      attr = [attr[0].substr(4), "not", 0]  if attr[0].indexOf("not:") is 0
      obj2 = resolve(obj, attr[0])

      #if obj is empty array it is still truthy, so make it the array length
      obj2 = obj2.length  if obj2 and obj2.join and obj2.length > -1
      if attr.length > 2
        attr[2] = attr.slice(2).join(" ")  if attr[3]
        attr[2] *= 1  if typeof obj2 is "number"
        switch attr[1]
          when "not"
            attr = not obj2
          when "eq"
            attr = (obj2 is attr[2])
          when "ne"
            attr = (obj2 isnt attr[2])
          when "gt"
            attr = (obj2 > attr[2])
          when "lt"
            attr = (obj2 < attr[2])
          when "cn"
            attr = (obj2 and obj2.indexOf(attr[2]) >= 0)
          when "nc"
            attr = (obj2 and obj2.indexOf(attr[2]) < 0)
          else
            throw node
      else
        attr = obj2
      if attr
        node.style.display = ""  if obj.__tally is `undefined`
      else

        # Handle hiding differently based on whether we are running in Express
        # with Tally or on the client. (On the server we actually remove the
        # nodes instead of hiding them to cut down on traffic and so that they
        # can be used to populate templates with dummy data.)

        #skip over all nodes that are children of this node
        if querySelectorAll
          pos += node.querySelectorAll(TAL).length
        else
          pos += node.getElementsByTagName("*").length
        if obj.__tally isnt `undefined` and obj.__tally.server
          node.parentNode.removeChild node
        else
          node.style.display = "none"

        #stop processing the rest of this node as it is invisible
        continue

    #duplicate the current node x number of times where x is the length
    #of the resolved array. Create a shortcut variable for each iteration
    #of the loop.
    #e.g., <div qrepeat="item feeds.items">
    attr = node.getAttribute(qrepeat)

    if attr
      attr2 = attr.split(" ")

      #if live NodeList, remove adjacent repeated nodes
      unless querySelectorAll
        html = node.parentNode
        html.removeChild tmpNode  while (tmpNode = node.nextSibling) and (tmpNode.qdup or (tmpNode.nodeType is 1 and tmpNode.getAttribute(qdup)))

      throw attr2  unless attr2[1]
      objList = resolve(obj, attr2[1])

      if objList and objList.length

        # Don’t set the style if on the server (as we don’t on anything)
        node.style.display = ""  if obj.__tally is `undefined` or obj.__tally.server is no

        #allow this node to be treated as index zero in the repeat list
        #we do this by setting the shortcut variable to array[0]
        obj[attr2[0]] = objList[0]
        obj["#"] = 1
      else

        # Handling hiding differently depending on whether this is running on the
        # client or as part of Tally on the server.
        if obj.__tally isnt `undefined` and obj.__tally.server

          # Running in Tally as part of Express.
          # Delete the node
          if querySelectorAll
            pos += node.querySelectorAll(TAL).length
          else
            pos += node.getElementsByTagName("*").length

          # Will this mess up pos?
          node.parentNode.removeChild node
        else

          # Not running in Tally (assume its running in the client)
          # Just hide the object and skip its children.

          #we need to hide the repeat node if the object doesn't resolve
          node.style.display = "none"

          #skip over all nodes that are children of this node
          if querySelectorAll
            pos += node.querySelectorAll(TAL).length
          else
            pos += node.getElementsByTagName("*").length

        #stop processing the rest of this node as it is invisible
        continue
      if objList.length > 1

        #we need to duplicate this node x number of times. But instead
        #of calling cloneNode x times, we get the outerHTML and repeat
        #that x times, then innerHTML it which is faster
        html = new Array(objList.length - 1)
        len = html.length
        i = len

        while i > 0
          html[len - i] = i
          i--
        tmpNode = node.cloneNode(true)
        tmpNode.checked = false  if "form" of tmpNode
        tmpNode.setAttribute qdef, attr
        tmpNode.removeAttribute qrepeat
        tmpNode.setAttribute qdup, "1"
        tmpNode = tmpNode.outerHTML or doc.createElement("div").appendChild(tmpNode).parentNode.innerHTML

        #we're doing something like this:
        #html = "<div qdef=" + [1,2,3].join("><div qdef=") + ">"
        prefix = tmpNode.indexOf(" " + qdef + "=\"" + attr + "\"")
        prefix = tmpNode.indexOf(" " + qdef + "='" + attr + "'")  if prefix is -1
        prefix = prefix + qdef.length + 3 + attr.length
        html = tmpNode.substr(0, prefix) + " " + html.join(tmpNode.substr(prefix) + tmpNode.substr(0, prefix) + " ") + tmpNode.substr(prefix)
        tmpNode = doc.createElement("div")

        #workaround for IE which can't innerHTML tables and selects
        if "cells" of node and not ("tBodies" of node) #TR
          tmpNode.innerHTML = "<table>" + html + "</table>"
          tmpNode = tmpNode.firstChild.tBodies[0].childNodes
        else if "cellIndex" of node #TD
          tmpNode.innerHTML = "<table><tr>" + html + "</tr></table>"
          tmpNode = tmpNode.firstChild.tBodies[0].firstChild.childNodes
        else if "selected" of node and "text" of node #OPTION, OPTGROUP
          tmpNode.innerHTML = "<select>" + html + "</select>"
          tmpNode = tmpNode.firstChild.childNodes
        else
          tmpNode.innerHTML = html
          tmpNode = tmpNode.childNodes
        prefix = node.parentNode
        attr2 = node.nextSibling
        if querySelectorAll or node is root

          #push the current list and index to the stack and process the repeated
          #nodes first. We need to do this inline because some variable may change
          #value later, if the become redefined.
          listStack.push list
          posStack.push pos

          #add this node to the stack so that it is processed right before we pop the
          #main list off the stack. This will be the last node to be processed and we
          #use it to assign our repeat variable to array index 0 so that the node's
          #children, which are also at array index 0, will be processed correctly
          list = getAttribute: getProp
          list[qdef] = attr + " 0"
          listStack.push [list]
          posStack.push 0

          #clear the current list so that in the next round we grab another list
          #off the stack
          list = []
          i = tmpNode.length - 1

          while i >= 0
            html = tmpNode[i]

            #we need to add the repeated nodes to the listStack because
            #we are either (1) dealing with a live NodeList and we are still at
            #the root node so the newly created nodes are adjacent to the root
            #and so won't appear in the NodeList, or (2) we are dealing with a
            #non-live NodeList, so we need to add them to the listStack
            listStack.push (if querySelectorAll then html.querySelectorAll(TAL) else html.getElementsByTagName("*"))
            posStack.push 0
            listStack.push [html]
            posStack.push 0
            html.qdup = 1
            prefix.insertBefore html, attr2
            i--
        else
          i = tmpNode.length - 1

          while i >= 0
            html = tmpNode[i]
            html.qdup = 1
            prefix.insertBefore html, attr2
            i--
        prefix.selectedIndex = -1

    #set multiple attributes on the node
    #e.g., <div qattr="value item.text; disabled item.disabled">
    attr = node.getAttribute(qattr)
    if attr
      name = undefined
      value = undefined
      html = attr.split("; ")
      i = html.length - 1

      while i >= 0
        attr = html[i].split(" ")
        name = attr[0]
        throw attr  unless attr[1]
        value = resolve(obj, attr[1])
        value = ""  if value is `undefined`
        attributeWillChange node, name, value  if attributeWillChange
        value = attr(value)  if attr = attr[2] and format[attr[2]]
        if altAttr[name]
          switch name
            when "innerHTML" #should use "qtext"
              throw node
            when "disabled", "checked", "selected"
              node[name] = !!value
            when "style"
              node.style.cssText = value
            when "text" #option.text unstable in IE
              node[(if querySelectorAll then name else innerText)] = value
            when "class"
              node["className"] = value
            else
              node[name] = value
        else
          node.setAttribute name, value
        i--

    #sets the innerHTML on the node
    #e.g., <div qtext="html item.description">
    attr = node.getAttribute(qtext)
    if attr
      attr = attr.split(" ")
      html = (attr[0] is "html")
      attr2 = resolve(obj, attr[(if html then 1 else 0)])
      attr2 = ""  if attr2 is `undefined`
      textWillChange node, attr2  if textWillChange
      attr2 = attr(attr2)  if (attr = attr[(if html then 2 else 1)]) and (attr = format[attr])
      if html
        node.innerHTML = attr2
      else
        node[(if "form" of node and not formInputHasBody[node.tagName] then "value" else innerText)] = attr2
#end while

#follows the dot notation path to find an object within an object: obj["a"]["b"]["1"] = c;
tally.resolve = (obj, seq, x, lastObj) ->

  #if fully qualified path is at top level: obj["a.b.d"] = c
  return (if (typeof x is "function") then x.call(obj, seq) else x) if x = obj[seq]

  seq = seq.split(".")
  x = 0

  while seq[x] and (lastObj = obj) and (obj = obj[seq[x++]])
    ;

  (if (typeof obj is "function") then obj.call(lastObj, seq.join(".")) else obj)


#number formatters
tally.format = ",.": (v, i) ->
  i = v * 1
  (if isNaN(i) then v else ((if i % 1 then i.toFixed(2) else parseInt(i, 10) + "")).replace(/(^\d{1,3}|\d{3})(?=(?:\d{3})+(?:$|\.))/g, "$1,"))


#support RequireJS module pattern
if typeof define is "function" and define.amd
  define "tally", ->
    tally
else
  window.tally = tally
