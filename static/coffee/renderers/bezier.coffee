
properties = require('./properties')
glyph_properties = properties.glyph_properties
line_properties = properties.line_properties

glyph = require('./glyph')
Glyph = glyph.Glyph
GlyphView = glyph.GlyphView


class BezierView extends GlyphView

  initialize: (options) ->
    glyphspec = @mget('glyphspec')
    @glyph_props = new glyph_properties(
      @,
      glyphspec,
      ['x0', 'y0', 'x1', 'y1', 'cx0', 'cy0', 'cx1', 'cy1']
      [
        new line_properties(@, glyphspec)
      ]
    )

    @do_stroke = @glyph_props.line_properties.do_stroke
    super(options)

  _render: (data) ->
    ctx = @plot_view.ctx
    glyph_props = @glyph_props

    ctx.save()

    x0 = (glyph_props.select('x0', obj) for obj in data)
    y0 = (glyph_props.select('y0', obj) for obj in data)
    [@sx0, @sy0] = @map_to_screen(x0, glyph_props.x0.units, y0, glyph_props.y0.units)

    x1 = (glyph_props.select('x1', obj) for obj in data)
    y1 = (glyph_props.select('y1', obj) for obj in data)
    [@sx1, @sy1] = @map_to_screen(x1, glyph_props.x1.units, y1, glyph_props.y1.units)

    cx0 = (glyph_props.select('cx0', obj) for obj in data)
    cy0 = (glyph_props.select('cy0', obj) for obj in data)
    [@scx0, @scy0] = @map_to_screen(cx0, glyph_props.cx0.units, cy0, glyph_props.cy0.units)

    cx1 = (glyph_props.select('cx1', obj) for obj in data)
    cy1 = (glyph_props.select('cy1', obj) for obj in data)
    [@scx1, @scy1] = @map_to_screen(cx1, glyph_props.cx1.units, cy1, glyph_props.cy1.units)

    if @glyph_props.fast_path
      @_fast_path(ctx, glyph_props)
    else
      @_full_path(ctx, glyph_props, data)

    ctx.restore()

  _fast_path: (ctx, glyph_props) ->
    if @do_stroke
      glyph_props.line_properties.set(ctx, glyph)
      ctx.beginPath()
      for i in [0..@sx0.length-1]
        if isNaN(@sx0[i] + @sy0[i] + @sx1[i] + @sy1[i] + @scx0[i] + @scy0[i] + @scx1[i] + @scy1[i])
          continue
        ctx.moveTo(@sx0[i], @sy0[i])
        ctx.bezierCurveTo(@scx0[i], @scy0[i], @scx1[i], @scy1[i], @sx1[i], @sy1[i])
      ctx.stroke()

  _full_path: (ctx, glyph_props, data) ->
    if @do_stroke
      for i in [0..@sx0.length-1]
        if isNaN(@sx0[i] + @sy0[i] + @sx1[i] + @sy1[i] + @scx0[i] + @scy0[i] + @scx1[i] + @scy1[i])
          continue

        ctx.beginPath()
        ctx.moveTo(@sx0[i], @sy0[i])
        ctx.bezierCurveTo(@scx0[i], @scy0[i], @scx1[i], @scy1[i], @sx1[i], @sy1[i])

        glyph_props.line_properties.set(ctx, data[i])
        ctx.stroke()



class Bezier extends Glyph
  default_view: BezierView
  type: 'GlyphRenderer'


Bezier::display_defaults = _.clone(Bezier::display_defaults)
_.extend(Bezier::display_defaults, {

  line_color: 'red'
  line_width: 1
  line_alpha: 1.0
  line_join: 'miter'
  line_cap: 'butt'
  line_dash: []

})


class Beziers extends Backbone.Collection
  model: Bezier


exports.beziers = new Beziers
exports.Bezier = Bezier
exports.BezierView = BezierView
