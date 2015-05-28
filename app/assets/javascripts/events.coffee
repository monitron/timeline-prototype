# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

class TimelineRenderer
  importanceShiftPoints: [250, 15, 4.3, 1.5, 0.45, 0]
  dotRadius: 5

  constructor: ->
    @zoom = 100 # Pixels per year
    d3.json '/events.json', (error, json) =>
      if error then return console.warn(error)
      @data = json
      for event in @data
        event.start   = d3.time.format.iso.parse(event.start)
        event.end     = d3.time.format.iso.parse(event.end)
      @dateExtent = d3.extent(_.flatten(@data.map((e) -> [e.start, e.end])))
      @build()

  build: ->
    $el = $('#timeline-visualization')
    @dateScale = d3.time.scale.utc()
      .domain @dateExtent
      .range  [0, @zoom * ((@dateExtent[1] - @dateExtent[0]) / 365 / 86400000)]
    @width = $el.width()
    @height = $el.height()
    @dateAxis = d3.svg.axis()
      .scale @dateScale
      .orient 'left'
      .ticks 30
    @zoom = d3.behavior.zoom()
      .y @dateScale
      .on 'zoom', => @zoomed()
    @svg = d3.select($el[0])
      .append 'g'
      .attr 'transform', "translate(100, 0)"
    @window = @svg.append 'g'
      .call @zoom
    @window.append 'rect'
      .attr 'class', 'overlay'
      .attr 'width', @width
      .attr 'height', @height
    @window.append 'g'
      .attr 'class', 'date-axis'
      .call @dateAxis
    level = @detailLevel()
    eventG = @window.selectAll '.event'
      .data @data
      .enter()
      .append 'g'
      .attr 'class', 'event'
      .attr 'data-importance', (event) => event.importance
      .attr 'data-visible', (event) => event.importance >= level
      .attr 'data-is-range', (event) => event.start != event.end
    eventG.append 'text'
      .attr 'class', 'title'
      .attr 'x', 10
      .attr 'y', (event) => @dateScale(event.start)
      .text (event) -> event.title
    eventG.append 'circle'
      .attr 'class', 'start'
      .attr 'r', @dotRadius
      .attr 'cy', (event) => @dateScale(event.start)
    eventG.append 'circle'
      .attr 'class', 'end'
      .attr 'r', @dotRadius
      .attr 'cy', (event) => @dateScale(event.end)
    eventG.append 'rect'
      .attr 'class', 'bridge'
      .attr 'x', -@dotRadius
      .attr 'width', @dotRadius * 2
      .attr 'y', (event) => @dateScale(event.start)
      .attr 'height', (event) => @dateScale(event.end) - @dateScale(event.start)
  zoomed: ->
    level = @detailLevel()
    @svg.select('.date-axis').call @dateAxis
    eventContext = @window.selectAll '.event'
      .attr 'data-visible', (event) => event.importance >= level
    eventContext.selectAll 'text'
      .attr 'y', (event) => @dateScale(event.start)
    eventContext.selectAll '.start'
      .attr 'cy', (event) => @dateScale(event.start)
    eventContext.selectAll '.end'
      .attr 'cy', (event) => @dateScale(event.end)
    eventContext.selectAll '.bridge'
      .attr 'y', (event) => @dateScale(event.start)
      .attr 'height', (event) => @dateScale(event.end) - @dateScale(event.start)

  detailLevel: ->
    for level, i in @importanceShiftPoints
      if @zoom.scale() >= level then return i

window.timeline = new TimelineRenderer()