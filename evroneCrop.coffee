$ = jQuery

$.fn.extend
  evroneCrop: (options) ->
    settings =
      preview: false #pass an IMG DOM Element to display preview;
      ratio: false #pass a number > 0 to fix ratio, e.g 1 for square or 16/9 for 16/9 ratio
      setSelect: false #pass coordinates for setting select after initializing, e.g {x: 0, y: 0, w: 100, h: 100} or "center"
      #dont pass h if you have ratio enabled
      size: false
      log: false
      
    
    settings = $.extend settings, options
    
    return @each () ->
      new EvroneCrop this, settings

class EvroneCrop
  constructor: (@element, @settings) ->
    @canvas = @constructCanvas()
    @ctx = @setCanvas()
    @storePlace = @settings.store
    #get original image size
    tmp_img = new Image()
    tmp_img.src = $(@element).attr 'src'
    $(tmp_img).bind 'load', () =>
      @originalSize = tmp_img.width
      @darkenCanvas() #nothing but darken canvas
      if @settings.setSelect then @setSelect() else @setSelectionTool()
    
  constructCanvas: ->
    canvas = document.createElement('canvas')
    c = $(canvas)
    c.css('position', 'absolute')
    c.addClass 'evroneCropCanvas'
    $(@element).after(c).next()
      
  setCanvas: ->
     @canvas.offset($(@element).offset()) #set canvas position to left top corner of image
     c = @canvas[0]
     c.width = @element.width
     c.height = @element.height
     c.getContext('2d') #return canvas context
     
  darkenCanvas: ->
    c = @canvas[0]
    @ctx.fillStyle = "rgba(0, 0, 0, 0.5)"
    @ctx.fillRect 0, 0, c.width, c.height
    
  setSelect: ->
    if @settings.ratio
      if @settings.setSelect == 'center'
        #setting select center with ratio enabled
        if @canvas.width() > @canvas.height()  
          @initY = Math.floor(@canvas.height()/4)
          @moveH = Math.floor(@canvas.height()/2)
          @moveW = @moveH*@settings.ratio
          @initX = Math.floor((@canvas.width()-@moveW)/2)
        else
          @initX = Math.floor(@canvas.width()/4)
          @moveW = Math.floor(@canvas.width()/2)
          @moveH = @moveW*@settings.ratio
          @initY = Math.floor((@canvas.height()-@moveH)/2)
      else if typeof @settings.setSelect == 'object'
        @initX = @settings.setSelect.x
        @initY = @settings.setSelect.y
        @moveW = @settings.setSelect.w
        @moveH = @moveW/@settings.ratio
        
    else #if ratio == false
      if @settings.setSelect == 'center'
        #setting select center without ratio
        @initX = Math.floor(@canvas.width()/4)
        @initY = Math.floor(@canvas.height()/4)
        @moveW = Math.floor(@canvas.width()/2)
        @moveH = Math.floor(@canvas.height()/2)
      else if typeof @settings.setSelect == 'object'
        @initX = @settings.setSelect.x
        @initY = @settings.setSelect.y
        @moveW = @settings.setSelect.w
        @moveH = @settings.setSelect.h
      
      
    @selection = new Rect @initX, @initY, @moveW, @moveH, 3
    @updateCanvas @initX, @initY, @moveW, @moveH, @canvas, @ctx
    @createCorners()
    @store()
    @dragMouseDown()
    
  setSelectionTool: ->
    @canvas.mousedown (e) =>
      coords = { x: e.pageX - @canvas.offset().left, y: e.pageY - @canvas.offset().top }
      @initX = coords.x
      @initY = coords.y
      @canvas.mousemove (e) ->
        dragMouseMove(e)
      @canvas.mouseup (e) ->
        dragMouseUp(e)
      
      dragMouseMove = (e) =>
        coords = { x: e.pageX - @canvas.offset().left, y: e.pageY - @canvas.offset().top }
        return false if coords.x < 1 or coords.y < 1 or coords.x > @canvas.width()-1 or coords.y > @canvas.height-1
        @moveW = coords.x - @initX
        if @settings.ratio then @moveH = @moveW*@settings.ratio else @moveH = coords.y - @initY
        @selection = new Rect @initX, @initY, @moveW, @moveH, 3
        @updateCanvas @initX, @initY, @moveW, @moveH, @canvas, @ctx
        
      dragMouseUp = (e) =>
        @canvas.unbind 'mousemove'#, dragMouseMove
        @canvas.unbind 'mouseup'#, dragMouseUp
        @canvas.unbind 'mousedown'#, dragMouseUp
        @selection.drag 0, 0, @canvas
        @selection.fix()
        @updateInits()
        @createCorners()
        @store()
        @dragMouseDown()
  
  updateCanvas: (x, y, w, h, canvas, ctx) ->
    c = canvas[0]
    ctx.fillStyle = "rgba(0, 0, 0, 0.5)"
    ctx.clearRect 0, 0, c.width, c.height
    ctx.fillRect 0, 0, c.width, c.height
    ctx.clearRect x, y, w, h
    
    if @settings.preview
      $(@settings.preview).attr('src', @done())
    
    #console.time('done')
    window[@store] = @done()
    #console.timeEnd('done')
      
    
  createCorners: ->
    c = @canvas[0]
    ctx = @ctx
    ctx.fillStyle = "#ffffff"
    ctx.strokeStyle = "rgba(0, 0, 0, 1)"
    @corners = []
    for point in @selection.summits
      r = new Rect point.x-3, point.y-3, 8, 8
      r.parent = point
      @corners.push r
      ctx.fillRect point.x-3, point.y-3, 8, 8
      ctx.strokeRect point.x-3, point.y-3, 8, 8
    
  updateInits: ->
    @initX = @selection.xywh.x
    @initY = @selection.xywh.y
    @moveW = @selection.xywh.w
    @moveH = @selection.xywh.h
    
  dragMouseDown: () ->
    @canvas.mousedown (e) =>
      coords = { x: e.pageX - @canvas.offset().left, y: e.pageY - @canvas.offset().top }
      if @selection.hasPoint coords.x, coords.y
        @dragInitX = coords.x
        @dragInitY = coords.y
        @canvas.mousemove (e) ->
          dragMouseMove(e)
        @canvas.mouseup (e) ->
          dragMouseUp(e)
        
        dragMouseMove = (e) =>
          coords = { x: e.pageX - @canvas.offset().left, y: e.pageY - @canvas.offset().top }
          @dragMoveW = coords.x - @dragInitX
          @dragMoveH = coords.y - @dragInitY
          @selection.drag @dragMoveW, @dragMoveH, @canvas
          c = @selection.xywh2()
          @updateCanvas(c.x, c.y, c.w, c.h, @canvas, @ctx)
          
      	  
        dragMouseUp = (e) =>
          @canvas.unbind 'mousemove'#, dragMouseMove
          @canvas.unbind 'mouseup'#, dragMouseUp
          @initX += @dragMoveW
          @initY += @dragMoveH
          @selection.fix()
          @updateInits()
          c = @selection.xywh2()
          @updateCanvas(c.x, c.y, c.w, c.h, @canvas, @ctx)
          @store()
          @createCorners()
          
      else
        for corner in @corners
          if corner.hasPoint coords.x, coords.y
            for summit in @selection.summits
              if summit.x == corner.parent.x and summit.y == corner.parent.y
                i = $.inArray summit, @selection.summits
                @resizeInitX = summit.x
                @resizeInitY = summit.y
                @canvas.mousemove (e) ->
                  resizeMouseMove(e)
                @canvas.mouseup (e) ->
                  resizeMouseUp(e)
                
                resizeMouseMove = (e) =>
                  coords = { x: e.pageX - @canvas.offset().left, y: e.pageY - @canvas.offset().top }
                  return false if coords.x < 1 or coords.y < 1 or coords.x > @canvas.width()-1 or coords.y > @canvas.height-1
                  
                  a = coords.x - @resizeInitX
                  if @settings.ratio
                    switch i
                      when 0
                        b = a
                      when 2
                        b = a
                      when 1
                        b = -1*a
                      when 3
                        b = -1*a
                  else
                    b = coords.y - @resizeInitY
                    
                  @selection.translate i, @resizeInitX+a, @resizeInitY+b
                  c = @selection.xywh()
                  @updateCanvas(c.x, c.y, c.w, c.h, @canvas, @ctx)
      
                resizeMouseUp = (e) =>
                  @canvas.unbind 'mousemove'#, resizeMouseMove
                  @canvas.unbind 'mouseup'#, resizeMouseUp
                  @updateInits()
                  @store()
                  @createCorners()
      
  done: ->
    tmp_canvas = document.createElement 'canvas'
    image = @element
    imageCSSW = $(image).width()
    m = @originalSize/imageCSSW
    @log "imageCSSW: #{imageCSSW}"
    @log "originalSize: #{@originalSize}"
    @log "m: #{m}"
    ctx = tmp_canvas.getContext '2d'
    xywh = @selection.xywh()
    
    if typeof(m != 'undefined')
      xywh.x *= m
      xywh.y *= m
      xywh.w *= m
      xywh.h *= m

    tmp_canvas.width = @settings.size.w or xywh.w
    tmp_canvas.height = @settings.size.h or xywh.h
    @log xywh
    ctx.drawImage(image, xywh.x, xywh.y, xywh.w, xywh.h, 0, 0, tmp_canvas.width, tmp_canvas.height)
    tmp_canvas.toDataURL()
    
  store: ->
    $.data(@element, 'evroneCrop', @done())
    
  log: (msg) ->
    if @settings.log
      console.log msg
    
      
class Rect
  constructor: (@x, @y, @w, @h, @padding) ->
    @summits = [{x: @x, y: @y},
              {x: @x + @w, y: @y},
              {x: @x + @w, y: @y + @h},
              {x: @x, y: @y + @h}]
    @newSummits = []
    
  hasPoint: (x, y) ->
    padding = @padding or 0
    point1 = @summits[0]
    point2 = @summits[2]
    if point1.x < point2.x
      min_x = point1.x
      max_x = point2.x
    else
      min_x = point2.x
      max_x = point1.x
    if point1.y < point2.y
      min_y = point1.y
      max_y = point2.y
    else
      min_y = point2.y
      max_y = point1.y
    if x > (min_x + padding) and x < (max_x - padding) and y > (min_y + padding) and y < (max_y - padding)
      true
    else
      false
      
  translate: (i, x, y) ->
    oldSummits = @summits
    #magic...
    switch i
      when 0
        @summits[0] = {x: x, y: y}
        @summits[1] = {x: oldSummits[1].x, y: y}
        @summits[3] = {x: x, y: oldSummits[3].y}
      when 1
        @summits[0] = {x: oldSummits[0].x, y: y}
        @summits[1] = {x: x, y: y}
        @summits[2] = {x: x, y: oldSummits[2].y}
      when 2
        @summits[1] = {x: x, y: oldSummits[1].y}
        @summits[2] = {x: x, y: y}
        @summits[3] = {x: oldSummits[3].x, y: y}
      when 3
        @summits[0] = {x: x, y: oldSummits[0].y}
        @summits[2] = {x: oldSummits[2].x, y: y}
        @summits[3] = {x: x, y: y}
    
    @x = @summits[0].x
    @y = @summits[0].y
    @w = @summits[2].x-@summits[0].x
    @h = @summits[2].y-@summits[0].y
    @summits
    
  xywh: ->
    {x:@x, y:@y, w:@w, h:@h}
    
  xywh2: ->
    {x:@newx, y:@newy, w:@w, h:@h}
    
  drag: (x,y, canvas) ->
    @newx = @x + x
    @newy = @y + y
    if @newx < 1
      @newx = 0 
    if @newy < 1
      @newy = 0 
    if @newx > canvas.width() - @w
      @newx = canvas.width() - @w 
    if @newy > canvas.height() - @h
      @newy = canvas.height() - @h 
  
  fix: ->
    @renewSummits()
    
  renewSummits: ->
    @x = @newx
    @y = @newy
    @summits = [{x: @x, y: @y},
              {x: @x + @w, y: @y},
              {x: @x + @w, y: @y + @h},
              {x: @x, y: @y + @h}]