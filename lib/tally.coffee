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

  # Create a duplicate object which we can add properties to without affecting the original.
  wrapper = ->

  wrapper:: = obj
  obj = new wrapper()
  resolve = tally.resolve
  node = root
  doc = root.ownerDocument
  querySelectorAll = !!root.querySelectorAll

  # Create an empty options object if one was not passed so we don’t have to keep checking for it later.
  obj.__tally = {} if obj.__tally is undefined

  # Shortcut to flag: are we running on the server?
  isRunningOnServer = obj.__tally.server

  # Render static option.
  shouldRenderStatic = isRunningOnServer and obj.__tally.renderStatic

  # Optimize comparison check.
  innerText = (if "innerText" of root then "innerText" else "textContent")

  # Attributes that don't support setAttribute()
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


  # TAL attributes for querySelectorAll call
  qdef = tally
  attributeWillChange = qdef.attributeWillChange
  textWillChange = qdef.textWillChange
  qif = qdef.qif or "data-tally-if"
  qrepeat = qdef.qrepeat or "data-tally-repeat"
  qattr = qdef.qattr or "data-tally-attribute"
  qtext = qdef.qtext or "data-tally-text"
  qdup = qdef.qdup or "data-tally-dummy"

  # Output formatter.
  format = qdef.format
  qdef = qdef.qdef or "data-tally-alias"
  TAL = "*[" + [qdef, qif, qrepeat, qattr, qtext].join("],*[") + "]"
  html = undefined
  getProp = (s) ->
    this[s]

  # There may be generated nodes that are siblings to the root node if the root node
  # itself was a repeater. Remove them so we don't have to deal with them later.
  tmpNode = root.parentNode
  tmpNode.removeChild node  while (node = root.nextSibling) and (node.qdup or (node.nodeType is 1 and node.getAttribute(qdup)))

  # If we generate repeat nodes and are dealing with non-live NodeLists, then
  # we add them to the listStack[] and process them first as they won't appear inline
  # due to non-live NodeLists when we traverse our tree.
  listStack = undefined
  posStack = [0]
  list = undefined
  pos = 0
  attr = undefined
  attr2 = undefined
  `var undefined = {}._`

  # Get a list of concerned nodes within this root node. If querySelectorAll is
  # supported we use that but it is treated differently because it is a non-live NodeList.
  if querySelectorAll

    # Remove all generated nodes (repeats), so we don't have to deal with them later.
    # Only need to do this for non-live NodeLists.
    list = root.querySelectorAll("*[" + qdup + "]")
    node.parentNode.removeChild node  while (node = list[pos++])
    pos = 0

  listStack = [(if querySelectorAll then root.querySelectorAll(TAL) else root.getElementsByTagName("*"))]

  list = [root]

  loop
    node = list[pos++]

    # When finished with the current list, there are generated nodes and
    # their children that need to be processed.
    while not node and (list = listStack.pop())
      pos = posStack.pop()
      node = list[pos++]
    break unless node

    # Creates an alias for an object
    # e.g., <section data-tally-alias='feeds main.sidebar.feeds'>
    attr = node.getAttribute(qdef)
    if attr
      attr = attr.split(" ")

      # Add it to the object as a property.
      html = resolve(obj, attr[1])

      # The 3rd parameter, if it exists, is a numerical index into the array.
      if attr2 = attr[2]
        obj["#"] = parseInt(attr2) + 1
        html = html[attr2]
      obj[attr[0]] = html

    # Shown if object is truthy.
    # e.g., <img data-tally-if='item.unread'> <img data-tally-if='item.count isGreaterThan 1'>
    attr = node.getAttribute(qif)
    if attr
      attr = attr.split(" ")
      attr = [attr[0].substr(4), "not", 0]  if attr[0].indexOf("not:") is 0
      obj2 = resolve(obj, attr[0])

      # If obj is empty array it is still truthy, so make it the array length.
      obj2 = obj2.length  if obj2 and obj2.join and obj2.length > -1
      if attr.length > 2
        attr[2] = attr.slice(2).join(" ")  if attr[3]
        attr[2] *= 1  if typeof obj2 is "number"
        switch attr[1]
          when "not"
            attr = not obj2
          when "is"     # In Distal, this is eq (equal to)
            attr = (obj2 is attr[2])
          when "isNot"     # In Distal, this is ne (not equal to)
            attr = (obj2 isnt attr[2])
          when "isGreaterThan"     # In Distal, this is gt (greater than)
            attr = (obj2 > attr[2])
          when "isLessThan"     # In Distal, this is lt (less than)
            attr = (obj2 < attr[2])
          when "contains"     # In Distal, this is cn (contains)
            attr = (obj2 and obj2.indexOf(attr[2]) >= 0)
          when "doesNotContain"     # In Distal this is nc (does not contain)
            attr = (obj2 and obj2.indexOf(attr[2]) < 0)
          else
            throw new Error(node)
      else
        attr = obj2
      if attr
        if not shouldRenderStatic
          if node.style.removeProperty
            node.style.removeProperty 'display'
          else
            node.style.removeAttribute 'display'
        # node.style.display = "" if not shouldRenderStatic
      else

        # Handle hiding differently based on whether user has flagged that
        # we should render static HTML from the server. (If so, remove the
        # nodes instead of hiding them to cut down on traffic.)

        # Skip over all nodes that are children of this node.
        if querySelectorAll
          pos += node.querySelectorAll(TAL).length
        else
          pos += node.getElementsByTagName("*").length

        if shouldRenderStatic
          node.parentNode.removeChild node
        else
          node.style.display = "none"

        # Stop processing the rest of this node as it is invisible.
        continue

    # Duplicate the current node x number of times where x is the length
    # of the resolved array. Create a shortcut variable for each iteration
    # of the loop.
    # e.g., <div data-tally-repeat='item feeds.items'>
    attr = node.getAttribute(qrepeat)

    if attr
      attr2 = attr.split(" ")

      #if live NodeList, remove adjacent repeated nodes
      unless querySelectorAll
        html = node.parentNode
        html.removeChild tmpNode  while (tmpNode = node.nextSibling) and (tmpNode.qdup or (tmpNode.nodeType is 1 and tmpNode.getAttribute(qdup)))

      throw new Error(attr2) unless attr2[1]
      objList = resolve(obj, attr2[1])

      if objList and objList.length

        # Don’t set the style if on the server (as we don’t on anything)
        # node.style.display = ""  if not shouldRenderStatic
        if not shouldRenderStatic
          if node.style.removeProperty
            node.style.removeProperty 'display'
          else
            node.style.removeAttribute 'display'


        # Allow this node to be treated as index zero in the repeat list
        # we do this by setting the shortcut variable to array[0]
        obj[attr2[0]] = objList[0]
        obj["#"] = 1
      else

        if shouldRenderStatic
          # Delete the node
          if querySelectorAll
            pos += node.querySelectorAll(TAL).length
          else
            pos += node.getElementsByTagName("*").length

          # Will this mess up pos?
          node.parentNode.removeChild node
        else

          # Just hide the object and skip its children.

          # We need to hide the repeat node if the object doesn't resolve.
          node.style.display = "none"

          # Skip over all nodes that are children of this node.
          if querySelectorAll
            pos += node.querySelectorAll(TAL).length
          else
            pos += node.getElementsByTagName("*").length

        # Stop processing the rest of this node as it is invisible.
        continue

      if objList.length > 1

        # We need to duplicate this node x number of times. But instead
        # of calling cloneNode x times, we get the outerHTML and repeat
        # that x times, then innerHTML it which is faster.
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

        # We're doing something like this:
        # html = "<div data-tally-alias=' + [1,2,3].join('><div data-tally-alias=') + '>'
        prefix = tmpNode.indexOf(" " + qdef + "=\"" + attr + "\"")
        prefix = tmpNode.indexOf(" " + qdef + "='" + attr + "'")  if prefix is -1
        prefix = prefix + qdef.length + 3 + attr.length
        html = tmpNode.substr(0, prefix) + " " + html.join(tmpNode.substr(prefix) + tmpNode.substr(0, prefix) + " ") + tmpNode.substr(prefix)
        tmpNode = doc.createElement("div")

        # Workaround for IE which can't innerHTML tables and selects.
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

          # Push the current list and index to the stack and process the repeated
          # nodes first. We need to do this inline because some variable may change
          # value later, if the become redefined.
          listStack.push list
          posStack.push pos

          # Add this node to the stack so that it is processed right before we pop the
          # main list off the stack. This will be the last node to be processed and we
          # use it to assign our repeat variable to array index 0 so that the node's
          # children, which are also at array index 0, will be processed correctly.
          list = getAttribute: getProp
          list[qdef] = attr + " 0"
          listStack.push [list]
          posStack.push 0

          # Clear the current list so that in the next round we grab another list
          # off the stack.
          list = []
          i = tmpNode.length - 1

          while i >= 0
            html = tmpNode[i]

            # We need to add the repeated nodes to the listStack because
            # we are either (1) dealing with a live NodeList and we are still at
            # the root node so the newly created nodes are adjacent to the root
            # and so won't appear in the NodeList, or (2) we are dealing with a
            # non-live NodeList, so we need to add them to the listStack.
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

    #
    # Set multiple attributes on the node.
    # e.g., <div data-tally-attribute='value item.text; disabled item.disabled'>
    #

    # Catch empty data-tally-attribute attributes to help in debugging.
    attr = node.getAttribute(qattr)

    if attr

      # Ignore empty spaces
      attr = attr.trim()

      if attr == ''
        throw new Error('empty data-tally-attribute definition on element: ' + node.outerHTML)

      name = undefined
      value = undefined
      html = attr.split("; ")
      i = html.length - 1

      while i >= 0
        attr = html[i].split(" ")
        name = attr[0]

        if not name
          throw new Error('missing attribute name for attribute ' + i + ': ' + node.outerHTML)

        if not attr[1]
          throw new Error('missing attribute value for attribute ' + i + ' (‘' + name + '’): '  + node.outerHTML)

        value = resolve(obj, attr[1])
        value = ""  if value is `undefined`
        attributeWillChange node, name, value  if attributeWillChange
        value = attr(value)  if attr = attr[2] and format[attr[2]]
        if altAttr[name]
          switch name
            when "innerHTML" #should use "qtext"
              throw new Error(node)
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
    else
      # Try and catch any empty data-tally-attribute attributes to help the user debug.
      if node.hasAttribute
        if node.hasAttribute(qattr)
          throw new Error('empty data-tally-attribute definition on element: ' + node.outerHTML)

    # Sets the innerHTML on the node.
    # e.g., <div data-tally-text='html item.description'>
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

# Follows the dot notation path to find an object within an object: obj["a"]["b"]["1"] = c;
tally.resolve = (obj, seq, x, lastObj) ->

  #if fully qualified path is at top level: obj["a.b.d"] = c
  return (if (typeof x is "function") then x.call(obj, seq) else x) if x = obj[seq]

  seq = seq.split(".")
  x = 0

  while seq[x] and (lastObj = obj) and (obj = obj[seq[x++]])
    ;

  (if (typeof obj is "function") then obj.call(lastObj, seq.join(".")) else obj)


# Number formatters
tally.format = ",.": (v, i) ->
  i = v * 1
  (if isNaN(i) then v else ((if i % 1 then i.toFixed(2) else parseInt(i, 10) + "")).replace(/(^\d{1,3}|\d{3})(?=(?:\d{3})+(?:$|\.))/g, "$1,"))


# Support RequireJS module pattern
if typeof define is "function" and define.amd
  define "tally", ->
    tally
else
  window.tally = tally
