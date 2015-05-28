# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

class TimelineRenderer
  constructor: ->
    @zoom = 100 # Pixels per year
    d3.json '/events.json', (error, json) =>
      if error then return console.warn(error)
      @data = json
      for event in @data
        event.start = d3.time.format.iso.parse(event.start)
        event.end   = d3.time.format.iso.parse(event.start)
      @dateExtent = d3.extent(_.flatten(@data.map((e) -> [e.start, e.end])))
      @build()

  build: ->
    @dateScale = d3.time.scale.utc()
      .domain @dateExtent
      .range  [0, @zoom * ((@dateExtent[1] - @dateExtent[0]) / 365 / 86400000)]
    @width = $('#timeline-visualization').width()
    @height = $('#timeline-visualization').height()
    @dateAxis = d3.svg.axis()
      .scale @dateScale
      .orient 'left'
    @zoom = d3.behavior.zoom()
      .y @dateScale
      .on 'zoom', => @zoomed()
    @svg = d3.select('#timeline-visualization')
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
    eventG = @window.selectAll '.event'
      .data @data
      .enter()
      .append 'g'
      .attr 'class', 'event'
      .attr 'data-importance', (event) => event.importance
      .attr 'transform', (event) => "translate(0, #{@dateScale(event.start)})"
    eventG.append 'text'
      .attr 'x', 10
      .text (event) -> event.title
    eventG.append 'circle'
      .attr 'r', 5

  zoomed: ->
    @svg.select('.date-axis').call @dateAxis
    @window.selectAll '.event'
      .data @data
      .attr 'transform', (event) => "translate(0, #{@dateScale(event.start)})"


window.timeline = new TimelineRenderer()