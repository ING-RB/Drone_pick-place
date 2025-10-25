classdef polari < handle & matlab.mixin.CustomDisplay  & internal.polarbase & internal.polariutils.ThemePolari
    %POLARI Interactive plot of measurement data in polar format.
    %  POLARI plots measurement data in polar format.
    %
    %  POLARI(D) creates a polar plot based on real magnitude values in
    %  vector D, with angles uniformly spaced on the unit circle starting
    %  at 0 degrees.  Magnitudes may be negative when dB data units are
    %  used. The lowest (nearest -inf) magnitude is plotted at the origin
    %  and the highest (nearest +inf) is at maximum radius.
    %
    %  For a matrix D, columns of D are independent datasets. For N-D
    %  arrays, dimensions 2 and greater are independent datasets.  For
    %  complex values, magnitude and angle are derived from D.
    %
    %  POLARI(A1,M1,A2,M2, ...) specifies angle vectors A1, A2, ... in
    %  degrees along with real data matrices M1, M2, ...  More information
    %  about data formats is available using <a href="matlab:help internal.polari/formats">help internal.polari/formats</a>.
    %
    %  P = POLARI(___) returns an object that can customize the plot and
    %  add measurements using MATLAB commands. Properties are found by
    %  displaying variable P in the MATLAB command window. For example,
    %  P.Peaks = 3 identifies the 3 highest peaks in the data.
    %
    %  P = POLARPATTERN('gco') returns object P from the POLARPATTERN plot
    %  in the current figure, useful when P was not returned or retained.
    %
    %  Additional traces can be added to the plot using add(P,...) using
    %  any data input format shown above.  Existing traces can be replaced
    %  using replace(P,...).  To animate traces in the display, use
    %  animate(P,...) which forces a graphical update and preserves axes
    %  limits, labels, etc, to achieve a fast display rate.
    %
    %  POLARI(___,'P1',V1,'P2',V2, ...) sets the properties 'P1','P2', ...
    %  to values V1,V2, ... when the POLARI object is created.
    %
    %  POLARI(H,___) where H is an axes handle is supported.  POLARI also
    %  supports the syntax of POLAR.
    %
    %  Many properties of P can be changed interactively within the plot.
    %  Functions specific to POLARI may be discovered using methods(P), and
    %  are intended for automating setup of the display and measurements.
    %
    %  See also formats, multiaxes, TitleTop, LegendLabels,
    %  Peaks, add, replace, animate.

%   Copyright 2015-2023 The MathWorks, Inc.
    
    
    % BUGS
    % ----
    % BUG: Don't reuse .SpanReadout_CacheInfo,
    %      non-exclusive mouse handler overlap sets up conflicts
    %
    % BUG: Title - extra space added when interactive edits made
    %      setTitle.m -- PostSet listener fails to fire when h.String
    %      is a cell instead of a char matrix
    %
    % BUG: Legend - add multi-line text, then reduce back to one line.
    %      Sometimes legend box remains too tall, sometimes an extra
    %      linefeed is present
    %
    % BUG: .Interactive=false leaves context menus enabled
    %        See: enableContextMenus.m
    %
    % BUG: limit scroll-wheel action to occur only when mouse hovering over
    %      axes (similar to key strokes)
    %
    % BUG: Move Connect Endpoints, ColorOrder, etc from trace-specific
    %      Properties to Display menu
    %
    % BUG: dbl-click to add marker, release button.
    %      Marker doesn't hilite - that's a bug.
    %      Example of failure: without moving mouse, click and drag.
    %      We won't see the marker moving, we see angle ticks rotating
    %
    % BUG: quantized angle locations for mag-axis don't align with
    %      angle-tick locations (or refinement locations) - should they?
    %
    % BUG: p=polari.test2
    %      - angle tick every 45 degrees, even when rotating (good)
    %      - stretch mag axis a bit, pull max mag?
    %      - rotate angles, now we get angle tick every 22.5 degrees
    %      -> may have to do with angle refinement, coupled with
    %         suppression of center grid lines
    %      -> need to force an update of angle ticks when dropping mag
    %         drag, since refinement=on impacts angle tick density
    %
    %
    % ENHANCEMENTS
    % ------------
    % Add context menu to change FillLobes=t/f in antenna metrics
    %
    % Context menu to create title strings
    %   - in addition to dbl-click gesture
    %
    % Add tooltip for peak table
    %   See: autoChangeMouseBehavior.m to enable
    %
    % Add temp-click cursor for "don't show readout" cursors
    %
    % Antenna metrics for intensity (3D) datasets
    % (UNDERWAY) antenna measurements test points
    %
    % Colorbari for intensity (3D) datasets
    %  - sigutils.internal.colorbari('position',[20 20 30 450])
    %
    % Improve startup time
    %
    % Click on mag axis, press shift, notice two sets of quad-arrows.
    %      Do we want/need 2nd set?
    %
    % Develop and utilize polarData class
    %
    % Allow radial drag/repositioning of angle markers.
    %
    % disable Measurements > Remove Cursors if no cursors
    %
    % Add ability to drag data-dot directly, not just have it as an alias
    % for the cursor body
    %
    % Consider enabling RADIANS data units
    %
    % Un-set flags in cached motion struct according to clearly absent
    % graphical features, e.g., angle span, markers, traces.
    %
    % Decouple angle tick font size from mag tick font size
    %  - .pFontSize is master font size, used for angle ticks
    %
    % Add "annotation" methods to add arbitrary text
    %
    % computeAutoMagTickLabelAngle
    %   consider AngleLim in addition to View
    %
    % CW/CCW with AngleLim: undesirable effect on visualization
    %
    % add/replace/animate(p) after figure close regenerates MOST of plot;
    % no markers, no tooltips, no banners.
    %
    % Two markers on top of each other - something to see? show labels?
    %
    % efficiency: plot_axes always updates angle labels, but that's a rare
    % need
    %
    % Cursor-specific parent context menu: remove cursors
    %   - submenu, From This Trace and From All Traces
    %
    % Check properties to see which need to be deferred
    %
    % Add "C#" and "P#" tail to angle markers, with option to suppress
    % Consider coupling with override for AngleMarkerTipOverlap property
    %
    % When changing View, consider auto-placement/rotation when AngleLim is
    % not 0-360.
    %
    % Legend button in toolbar
    %  - we hear the "off" switch, but not the "on"
    %
    % Check Sector display
    %  - correct display
    %  - ClipData functionality
    %
    % Antenna metrics - Address removing user markers
    %    If removing from "del key" or generic "Antenna Metrics" context
    %       menu, use dialog to confirm
    %    If removing from dataset-specific removal menus, or from property,
    %    no confirmation
    %
    % Replace floating readouts with this:
    %     fp = matlab.graphics.shape.internal.FigurePanel('Parent', gcf);
    %     fp.Title = 'Test New title'
    %     fp.String = {'This is','a','multiline', 'string'};
    %
    % Add Cursor menu from Angle menu (not measurements, just add cursor)
    %
    % Improve dataset-hover detection (widen hit-zone)
    %
    % AngleResolution -> rename AngleDensity?
    %
    % Improve readout positioning -> quad changes to use theLoc string?
    %
    % Optional link to rectangular plot
    %
    % Consider decoupling top/bottom title offsets, or making smarter
    % offsets
    %
    % Consider decoupling mag tick label size from angle tick label size
    %
    % getExtent - finish method, maximize use of space in axes
    %
    % When non-interactive is set, and no angle markers are added, increase
    % the space used by polari within the axes to better fill the space
    %
    % multiaxes and formats help-method text
    %
    % Check properties displayed in command window (completeness, etc)
    %
    % findLobes() -- revisit "isCircle=true" assumption
    %
    % New magnitude edit dialog using DialogMgr
    %    - see: openPropertyEditor_MagTicks()
    %    - add explicit widgets for 'auto' vs 'manual'
    %
    % Scroll wheel: make it apply to hover axes
    %   - currently applies to ALL polari axes in figure
    %
    %
    % ====== Milestone ======
    %
    % Support az/el struct when antenna defines this
    %
    % Consider using complex value representation across codebase
    %
    % Reticle - minor grid
    %
    % Add colorization modes to context menu:
    %   - auto, contrast, manual, etc
    %
    % Drag zero-angle line to rotate angle
    %
    % Use more events, and fewer direct method calls, from polari app
    %   - for marker, span, etc
    %
    % Don't use listeners outside of gca (that is, on p.Parent) that cache
    % a copy of p itself --- use the "find" method to get a copy of p from
    % the axes.
    %       - search for: addlistener on p.Parent with "p" cached
    %       - quite a few!!! mouse listeners, etc
    %
    % Add autoconfig() method
    %   - public method
    %   - auto-invoke if NO properties specified?
    %   - use angle-domain to determines if >half or <=half circle
    %   - if midpt [-90, 90], sets View='top', AngleAtTop=midpt
    %   - if midpt [<-90, >90], sets View='bottom', AngleAtTop=180-midpt
    %
    % Open arrowheads: look like buttons (spinners) now
    %
    % Add marker mode where just a circle-dot appears on data or circle,
    % and info is a within-figure floating readout or in tag
    %
    % Consider merging:
    %   * TickLabelColorMode = AngleTickLabelColorMode
    %                        + MagnitudeTickLabelColorMode
    %   * TickLabelColor = AngleTickLabelColor
    %                    + MagnitudeTickLabelColor
    %
    % ? Properties representing angle and mag data, for specification in
    % P/V pairs.
    %
    % DataDot must have same Z as dataset
    %   getDataPlotZ(p) returns vector of z for each dataset
    %   setDataPlot() should send message to AngleMarkers
    %   Consider having Dataset "own" the marker
    %
    %   See: http://www.mathworks.com/help/matlab/creating_plots/defining-the-color-of-lines-for-plotting.html
    %
    %   Create testpoint where multiple axes in one figure will receive
    %   different Views of polari: Top, Right, Full, etc
    %
    %  - change from p*_Orig to p*
    %      - data access/pre-proc is still a mess in all plot_* methods
    %      - try to remove duplicate pre-proc steps
    %  - understand reason for all calls to parseData()
    %
    % - HG smoothing:
    %     SortMethod = 'childorder'
    %     GraphicsSmoothing = 'on'
    %     AlignVertexCenters = 'off' (AVC)
    %     ax.Camera.TransparencyMethodHint = 'objectsort';
    %
    % Formalize magnitude-based colorization option for Sectors style
    %
    % Performance:
    %  - Consider use of hgtransform
    %  - Consider use of hittest(h)
    %
    % - consider a new off-axes "hover" icon gadget, providing access to
    %   all context-menu options
    %
    %  - performance
    %      - profiling
    %      - dirty flag mgmt
    %      - when will axes update ?
    %      - impact of each prop change
    %
    %  - manage parent, as:
    %             polari(parent)
    %             polari('parent',parent)
    %             etc
    %      then make Parent read-only, or manage Parent change
    
    
    % ------------------------------------------------------
    % Data Access
    %    pdata = getDatasets(p)
    %    pdata = getDataset(p)
    %    pdata = getDataset(p,datasetIndex)
    %
    % ------------------------------------------------------
    % USE OF Z-DIMENSION
    %
    % Z-dimension is used to establish graphical sort order.
    %
    %    Z      Usage              Comments
    %  -----    ---------------    -------------
    %   0       Grid               when under data
    %   0.05    Angle span         under points for that style
    %   0.06    Antenna lobes      under data (for points)
    %   0.09    Mag zoom guide     under data (for points)
    %   0.1-0.2 Data plot          range enables stacking order
    %   0.205   Antenna lobes      over data (for polygons/sectors)
    %   0.21    Grid               when over data (polygons/sectors)
    %   0.21    Angle span         (when polygon style)
    %   0.24    Mag zoom guide     over data (for polygons/sectors)
    %   0.25    Mag tick text      .hMagText, hMagScale, hMagUnits,
    %   0.25    Mag "hover rect"
    %   0.25    Mag axis locator
    %   0.292   Clip circle        over data/datadot, under angle ticks
    %   0.294   Marker originline, datadot (-0.06+transformZ)
    %   0.294   4-arrow hilites    both mag and angle tick hilites
    %   0.294   Angle tick text    hAngleText, titles
    %   0.3-0.4 Marker patch/text  Range enables stacking order
    %   0.41    AngleLim Min       Keep this cursor over others
    %   0.415   AngleLim Max       Keep this cursor over others
    %   0.42    Span readout
    % ------------------------------------------------------
    
    events
        ViewChanged
        FontChanged
        MagnitudeLimChanged
        DataUnitsChanged
    end
    
    properties % Do NOT add SetObservable to this property group!
        % False disables mouse interaction with the plot.
        Interactive = true
    end
    
    %{
    properties (AbortSet, SetObservable)
        % Add a cursor that measures the angle subtended by a dataset peak.
        % Angle is measured between points of equal magnitude to either
        % side of the peak identified by the cursor location.
        %   - 'off' removes the peak width cursor
        %   - 'absolute' calculates peak width at the level specified by
        %      PeakWidthLevel
        %   - 'relative' calculates peak width at a level that is
        %      PeakWidthLevel lower than the peak magnitude
        % Measurement is suppressed if the cursor falls outside the angle
        % span determined by PeakwidthLevel.
        PeakWidth = 'off'

        % Reference level for peak width calculation.
        PeakWidthLevel = -10
    end
    %}
    
    properties (Dependent)
        % No Abort-set, so changes in spaces are seen
        
        %LEGENDLABELS Data labels for legend annotation.
        %  A string specifies a single legend label for all datasets, while
        %  a cell-string specifies a unique label for each dataset. The
        %  default labels are 'Trace 1', 'Trace 2', etc.
        %
        %  Setting this property automatically sets the Legend property to
        %  true.
        %
        %  Strings may contain keywords that are replaced by extended ASCII
        %  characters for display.
        %
        %  Symbol keywords:
        %     '#deg'    '#micro' '#infin'
        %     '#plusmn' '#ohm'   '#nabla'
        %     '#sup1'   '#sup2'  '#sup3'
        %     '#dagger' '#copy'  '#reg'
        %
        %  Greek keywords:
        %     '#alpha'      '#Alpha'
        %     '#beta'       '#Beta'
        %     '#gamma'      '#Gamma'
        %     '#delta'      '#Delta'
        %     '#epsilon'    '#Epsilon'
        %     '#zeta'       '#Zeta'
        %     '#eta'        '#Eta'
        %     '#theta'      '#Theta'
        %     '#kappa'      '#Kappa'
        %     '#lambda'     '#Lambda'
        %     '#mu'         '#Mu'
        %     '#xi'         '#Xi'
        %     '#pi'         '#Pi'
        %     '#rho'        '#Rho'
        %     '#sigma'      '#Sigma'
        %     '#phi'        '#Phi'
        %     '#psi'        '#Psi'
        %     '#omega'      '#Omega'
        %
        %  A multi-line label for a single trace is supported by passing a
        %  cell-vector of strings as an element of the Label cell vector.
        %
        %  To automatically create labels for multiple datasets using a
        %  common pattern, such as text with a different numeric value for
        %  each dataset, see the <a href="matlab:help internal.polari.createLabels">createLabels</a> function.
        %
        %  Example: pass labels in initial call
        %      polarpattern(rand(50,2), ...
        %        'LegendLabels',{'az=30#deg','az=45#deg'})
        %
        %  Example: set labels after initial call
        %      p = polarpattern(rand(50,2));
        %      p.LegendLabels = {'az=30#deg','az=45#deg'};
        %
        %  See also polarpattern, createLabels, formats, TitleTop
        LegendLabels
        
        AntennaMetrics
        
        CleanData
    end
    
    properties (Dependent)
        % These are actually SetAccess=private, but we want custom error
        % messages to guide to the use of add(), replace() and animate().
        
        % Angle of polar data, in degrees, for 2D and 3D data.
        AngleData
        
        % Magnitude of polar data for 2D and 3D data.
        MagnitudeData
    end
    
    properties (Dependent, SetAccess=private)
        
        % Intensity matrix for 3D data.
        IntensityData
        
        % Read-only info
        
        %AngleMarkers
        %   Read-only vector of structs describing details of each angle
        %   marker in plot.  Each element is a struct for one angle marker,
        %   returned in alphabetical order based on ID, with the fields:
        %   .ID
        %      Name of cursor or peak, i.e., 'C2' or 'P1.3'
        %   .number
        %      Cursors: Integer marker number, minimum value is 1.  Every
        %      cursor has a unique marker number.
        %      Peaks: Integer indicating relative magnitude of this peak,
        %      where 1 represents the peak with highest magnitude.
        %   .dataset
        %      Data set referenced by marker; the first or only data
        %      set in a plot is dataset index 1.
        %   .index
        %      Element index within dataset referenced by marker; the
        %      first element in the dataset is index 1.
        %   .angle
        %      Scalar value of angle referenced by marker, in degrees.
        %   .magnitude
        %      Scalar value of magnitude referenced by marker.
        AngleMarkers
        
        %CursorMarkers
        %   Read-only vector of structs describing details of each cursor
        %   in plot.  Each element is a struct for one angle marker,
        %   returned in alphabetical order based on ID, with the fields:
        %   .ID
        %      Name of cursor, i.e., 'C2'
        %   .number
        %      Integer marker number, minimum value is 1.  Every cursor has
        %      a unique marker number.
        %   .dataset
        %      Data set referenced by marker; the first or only data
        %      set in a plot is dataset index 1.
        %   .index
        %      Element index within dataset referenced by marker; the
        %      first element in the dataset is index 1.
        %   .angle
        %      Scalar value of angle referenced by marker, in degrees.
        %   .magnitude
        %      Scalar value of magnitude referenced by marker.
        CursorMarkers
        
        %PeakMarkers
        %   Read-only vector of structs describing details of each peak
        %   in plot.  Each element is a struct for one angle marker,
        %   returned in alphabetical order based on ID, with the fields:
        %   .ID
        %      Name of peak, i.e., 'P3'
        %   .number
        %      Integer indicating relative magnitude of this peak,
        %      where 1 represents the peak with highest magnitude.
        %   .dataset
        %      Data set referenced by marker; the first or only data
        %      set in a plot is dataset index 1.
        %   .index
        %      Element index within dataset referenced by marker; the
        %      first element in the dataset is index 1.
        %   .angle
        %      Scalar value of angle referenced by marker, in degrees.
        %   .magnitude
        %      Scalar value of magnitude referenced by marker.
        PeakMarkers
        
        % Read-only structure containing span measurement details, with the
        % fields:
        %  .angleDiff
        %      Clockwise difference in angle between start and end
        %      markers of the span, in the range 0 to 360 degrees.
        %  .magnitudeDiff
        %      Magnitude difference between start and end markers of
        %      the span.
        %  .markers
        %      2-element vector of structures describing angle markers
        %      at the counterclockwise and clockwise ends of the span.
        %      The structure is the same as returned by the
        %      AngleMarkers property.
        SpanDetails
    end
    
    properties (Dependent, GetAccess=private)
        % Set line color from a color name string by changing the value of
        % the ColorOrder property.
        Color
    end
    
    properties (Dependent, AbortSet, Access=private)
        % Purposefully not SetObservable
        
        %AngleTickCompassPoints Label angles using compass points (NESW).
        %  True labels angles using the compass points (N, E, S and W).
        %  Intermediate points (NE, SE, SW and NW) and further subdivisions
        %  are added when appropriate.
        AngleTickCompassPoints
    end
    
    properties (Dependent, AbortSet)
        % Index of active dataset
        ActiveDataset
        
        % Not observable - implements own actions
        
        % True to show interactive AngleLim cursors.
        AngleLimVisible
        
        % Purposefully not SetObservable
        
        % True to show dataset legends
        LegendVisible
        
        % True to show angle span measurement
        Span
        
        %TitleTop Title string to display above polar plot.
        %   Set TitleTop to a string to display a title above the polar
        %   axes.  Use TitleTopFontSizeMultiplier and TitleTopOffset
        %   properties to adjust title font size and vertical offset.
        %
        %   Symbols may be incorporated into title strings using keywords.
        %   See <a href="matlab:help internal.polari/LegendLabels">LegendLabels</a> for a complete list of keywords.
        %
        %   Font size for the title may be adjusted using the FontSize
        %   property, the TitleTopFontSizeMultiplier, or by using the '+'
        %   and '-' keyboard shortcuts with the mouse hovering over the
        %   title.
        %
        %   Example:
        %      polarpattern(rand(360,1)*30+50, ...
        %          'MagnitudeLim',[0 80], ...
        %          'TitleTop','Daily Results', ...
        %          'TitleBottom','#copy 2015 Your Company');
        %
        %   See also polarpattern, <a href="matlab:help internal.polari.multiaxes">multiaxes</a>, <a href="matlab:help internal.polari.TitleBottom">TitleBottom</a>, <a href="matlab:help internal.polari.LegendLabels">LegendLabels</a>.
        TitleTop
        
        %TitleBottom Title string to display below polar plot.
        %   Set TitleBottom to a string to display a title below the polar
        %   axes.  Use TitleBottomFontSizeMultiplier and TitleBottomOffset
        %   properties to adjust title font size and vertical offset.
        %
        %   Symbols may be incorporated into title strings using keywords.
        %   See <a href="matlab:help internal.polari/LegendLabels">LegendLabels</a> for a complete list of keywords.
        %
        %   Font size for the title may be adjusted using the TitleFontSize
        %   property, or by using the '+' and '-' keyboard shortcuts with
        %   the mouse hovering over the title.
        %
        %   Example:
        %      p = polarpattern(rand(360,1)*30+50);
        %      p.MagnitudeLim = [0 80];
        %      p.TitleTop = 'Daily Results';
        %      p.TitleBottom  = '#copy 2015 Your Company';
        %
        %   See also polarpattern, <a href="matlab:help internal.polari.TitleTop">TitleTop</a>, <a href="matlab:help internal.polari.LegendLabels">LegendLabels</a>.
        TitleBottom
    end
    
    properties (Dependent, SetObservable)
        %Peaks
        %  Maximum number of peaks to compute.  An integer specifies the
        %  same number of peaks for all datasets, while a vector specifies
        %  a unique number for each dataset.  Zero disables display of
        %  peaks for a dataset, while inf displays all peaks.
        %
        %  See also polarpattern, PeaksOptions, addCursor
        Peaks
        
        % Font size of text in the plot may be adjusted using FontSize, or
        % by using the '+' and '-' keyboard shortcuts when the mouse
        % pointer is within the plot axes.
        FontSize
        
        % Cannot AbortSet properties that perform side-effects when set.
        %   (forces 'manual' mode)
        
        % Magnitude limits specified with a 2-element vector, [magMin
        % magMax]. Only used when MagnitudeLimMode is 'manual'. Setting the
        % value of MagnitudeLim will automatically set MagnitudeLimMode to
        % 'manual'.
        MagnitudeLim
        
        % Cannot AbortSet properties that perform side-effects when set.
        %   (forces 'manual' mode)
        %
        % Angle of radial line along which magnitude tick labels will
        % appear.
        MagnitudeAxisAngle
        
        % Cannot AbortSet properties that perform side-effects when set.
        %   (forces 'manual' mode)
        
        % Magnitude ticks, specified with a vector.  Only values that fall
        % within limits specified by MagnitudeLim will be visible in plot.
        %
        % Only used when MagnitudeTickMode is 'manual'. Setting the value
        % of MagnitudeTick will automatically set MagnitudeTickMode to
        % 'manual'.
        MagnitudeTick
        
        MagnitudeTickLabelColor
    end
    
    properties (Dependent, AbortSet, SetObservable)
        % Visible polar angle span, specified as two angles in degrees in
        % CW (clockwise) order.  The full circle is visible when the angle
        % difference is 360 degrees, e.g., [0 360] or [-180 180].
        AngleLim
        
        % Angle tick label strings, one per displayed tick.  Labels are
        % reused in order until all ticks have a label.
        AngleTickLabel
        
        AngleTickLabelColor
    end
    
    properties (AbortSet)
        % Don't react to property changes automatically here; we handle
        % them specifically.   So no (SetObservable) here.
        
        % Font size used to display TitleTop
        TitleTopFontSizeMultiplier = 1.1
        
        % Font size used to display TitleBottom
        TitleBottomFontSizeMultiplier = 0.9
        
        % Font weight used to display both TitleTop
        TitleTopFontWeight = 'bold'
        
        % Font weight used to display TitleBottom
        TitleBottomFontWeight = 'normal'
        
        % Interpreter for top title text may be 'none', 'tex' or 'latex'.
        TitleTopTextInterpreter = 'none'
        
        % Interpreter for bottom title text may be 'none', 'tex' or
        % 'latex'.
        TitleBottomTextInterpreter = 'none'
        
        % Offset between top title string and the angle ticks, where 1.0 is
        % an offset equal to the circle radius.  Offset can be negative.
        TitleTopOffset = 0.15
        
        % Offset between bottom title string and the angle ticks, where 1.0
        % is an offset equal to the circle radius.  Offset can be negative.
        TitleBottomOffset = 0.15
        
        % Doesn't need to auto-update the display, so not SetObservable
        
        % True to show tips after a time delay while mouse remains over
        % elements of plot.
        ToolTips = true
        
        % Vector specifying the minimum and maximum magnitude limits that
        % can be specified in MagnitudeLim.
        %
        % When the constraint vector is modified, the current MagnitudeLim
        % values may be automatically changed to adhere to the minimum and
        % maximum value as specified in the constraint vector.
        %
        % After initial changes are made, no values of MagnitudeLim that
        % fall outside the constraint range are accepted.  An error will be
        % thrown if an attempt is made to set an out-of-range magnitude
        % limit via the property value.  Graphical interaction with the
        % magnitude axis in the plot will be limited to the maximum and
        % minimum constraint values.
        MagnitudeLimBounds = [-inf inf]
    end
    
    properties (AbortSet)
        % Font size used to display magnitude axis labels.
        %
        % Font size for axis tick labels may also be adjusted using the '+'
        % and '-' keyboard shortcuts when the mouse pointer is hovering
        % over the axis tick labels.
        MagnitudeFontSizeMultiplier = 0.9
        
        % Font size used to display angle axis labels.
        %
        % Font size for axis tick labels may also be adjusted using the '+'
        % and '-' keyboard shortcuts when the mouse pointer is hovering
        % over the axis tick labels.
        AngleFontSizeMultiplier = 1.0
    end
    
    properties (AbortSet, SetObservable)
        % Angle in degrees that will appear at top of plot.
        AngleAtTop = 90.0
        
        % Direction of increasing angle, either 'cw' (clockwise) or 'ccw'
        % (counter-clockwise).
        AngleDirection = 'ccw'
        
        % Number of degrees between radial lines depicting angle in plot.
        % Value must evenly divide into 90 degrees.
        AngleResolution = 15
        
        % Rotate tick labels if true, keep horizontal if false
        AngleTickLabelRotation = false
        
        % Format for angle tick labels
        %   '180' displays angles from -180 to +180
        %   '360' displays angles from 0 to 360
        %   'compass' displays compass points N, S, E, W and further
        %      subdivisions when appropriate
        %   'property' uses current value for AngleTickLabel
        AngleTickLabelFormat = '360'
        
        % Color of angle axes labels
        % 'auto','contrast','grid','manual'
        AngleTickLabelColorMode = 'contrast'
        
        %PeaksOptions Cell-vector of name/value pairs to customize results
        %  obtained from the 'findpeaks' function, which is used to
        %  identify peaks in the data.
        %
        %  Parameter values defined by the findpeaks function can be
        %  specified as the value of PeaksOptions.  A few constraints are:
        %    - 'NPeaks' and 'SortStr' are set automatically and cannot be
        %      overridden by PeaksOptions.
        %    - 'MinPeakHeight' are set automatically but can be overridden
        %      by PeaksOptions.
        %    - All other parameters take defaults as defined by findpeaks
        %      unless overridden by PeaksOptions.
        %
        %  Example: obj.PeaksOptions = {'MinPeakHeight',0.1}
        %
        %  See also polarpattern, Peaks, addCursor
        PeaksOptions = {}
        
        % Show angle tick labels
        AngleTickLabelVisible = true
        
        % Style of polar display.
        % - 'line' draws markers at each polar data point.  The same
        %   number of magnitude and angle values must be provided.
        %
        % - 'filled' draws a single filled or unfilled polygon with polar
        %   data used as polygon vertices.  The same number of magnitude
        %   and angle values must be provided.
        %
        % - 'sectors' draws multiple pie-shaped polygons from the vector of
        %   polar data, where each magnitude value is interpreted as a
        %   constant-magnitude arc between successive polar angles.
        %
        %   For data with the same number of magnitude and angle values,
        %   each magnitude value extends from its corresponding angle
        %   value to the next angle value.  For data with one more angle
        %   value than magnitude values, each magnitude value is located
        %   at the midpoint of specified angle values.
        Style = getString(message('siglib:polari:MenuLine'));
        
        % Units of data passed to polarpattern
        % - 'dB Gain' interprets input data as dB gain (default), which may
        %       be positive or negative valued.
        % - 'dB Loss' interprets input data as dB loss, which may be
        %       positive or negative valued.
        % - 'Linear Gain' interprets input data in linear units, and must have
        %       non-negative values.
        DataUnits = 'dB'
        
        % Units for display of polar data
        % - 'Linear Gain' converts input data to linear units
        % - 'dB Gain' converts input to dB units
        DisplayUnits = 'dB'
        
        % Normalize each data trace to its maximum value.
        NormalizeData = false
        
        % True if first and last angles should be connected
        ConnectEndpoints = false % Shashank
        
        % True shows gaps in line plots for nonuniform angle spacing.
        % Intended for use with uniformly-spaced data.
        DisconnectAngleGaps = false
        
        % Color and width of data lines
        EdgeColor = 'k'
        LineStyle = '-'
        LineWidth = 1.0
        
        FontName = 'Helvetica' % 'Rockwell Condensed'
        
        FontSizeMode = 'auto'
        
        % Color of grid lines, including lines and circles
        GridForegroundColor = [1 1 1]*0.8
        
        % Color of grid background
        GridBackgroundColor = 'w'
        
        % Suppress radial lines drawn within innermost circle
        DrawGridToOrigin = false
        
        % Draw grid over data plots
        GridOverData = false
        
        % Automatic grid refinement increases angle resolution by doubling
        % the number of angle tick lines after each magnitude tick circle.
        GridAutoRefinement = false
        
        % Width of grid lines
        GridWidth = 0.5
        
        % Show grid lines, including magnitude circles and angle radii
        GridVisible = true
        
        % True to clip data to the outer circle.
        ClipData = true
        
        % True creates a temporary cursor when clicking on a dataset, in
        % addition to making it the active dataset.  False makes it the
        % active dataset without a temporary cursor.
        TemporaryCursor = true
        
        % Automatic determination of magnitude dynamic range is enabled
        % when mode is set to 'auto'.  Set to 'manual' to specify the
        % magnitude limits using MagnitudeLimits property.
        MagnitudeLimMode = 'auto'
        
        % Automatic determination of angle for magnitude tick labels is
        % enabled when mode is set to 'auto'.  Set to 'manual' to specify
        % the angle for magnitude tick labels using the
        % MagnitudeAxisAngle property.
        MagnitudeAxisAngleMode = 'auto'
        
        % Automatic determination of magnitude tick locations is enabled
        % when mode is set to 'auto'.  Set to 'manual' to specify a vector
        % of magnitude tick locations using the MagnitudeTick property.
        MagnitudeTickMode = 'auto';
        
        % Color of magnitude axes labels
        % 'auto','contrast','grid','manual'
        MagnitudeTickLabelColorMode = 'contrast'
        
        % Show magnitude tick labels
        MagnitudeTickLabelVisible = true
        
        % Magnitude units string, such as 'dB'.
        %
        % If string includes '%s', MKS units are included in the string
        % when appropriate.
        MagnitudeUnits = ''
        
        % Intensity units string, such as 'dB'.
        %
        % If string includes '%s', MKS units are included in the string
        % when appropriate.
        IntensityUnits = ''
        
        % Marker displays at:
        %  - vertices of Polygon and Points style displays
        %  - midpoints of sectors in sectors style display
        Marker = 'none'
        
        % Marker size
        MarkerSize = 6
        
        % Handle to parent figure
        Parent
        
        %NEXTPLOT Determines how subsequent plot commands draw into axes.
        %  Set the value of the NextPlot property to get the following
        %  behaviors:
        %  - 'replace' (default) clears the axes when the function
        %    plot(P,...) is called to the new plot, and resets the magnitude
        %    axes limit mode to 'auto'.
        %  - 'add' preserves current plots and axes settings when plot(P,...)
        %    is called, and adds a new plot to the axes.
        %  - 'replacechildren' deletes the prior plot but preserves all
        %    axes settings when plot(P,...).  Provides high-performance
        %    graphical updates and is intended for plot animation.
        %
        %   A simple way to work with NextPlot is to call the <a href="matlab:help internal.polari.add">add</a>, <a href="matlab:help internal.polari.replace">replace</a>
        %   and <a href="matlab:help internal.polari.animate">animate</a> functions, which automatically set NextPlot as
        %   needed.
        %
        %   See also polarpattern, <a href="matlab:help internal.polari.formats">formats</a>, <a href="matlab:help internal.polari.multiaxes">multiaxes</a>.
        NextPlot = 'replace'
        
        % Color order to use for 'line' and 'filled' Style displays
        % Colors are utilized in order when NextPlot='add'
        ColorOrder = get(0,'DefaultAxesColorOrder')
        ColorOrderIndex = 1
        
        SectorsColor = hot(16)
        SectorsAlpha = 0.5
        
        % Portion of polar circle to view.
        % Options are: 'full', 'top', 'bottom', 'left', 'right',
        %              'top-left', 'top-right', 'bottom-left',
        %              'bottom-right'
        View = 'full'
        
        % Highlight the radial line at zero degrees.
        ZeroAngleLine = false
    end
    
    properties (AbortSet, SetObservable, Hidden)
        % Set to 'auto' to enable automatic label ticks.
        % Set to 'manual' to use label strings in AngleTickLabel.
        AngleTickLabelMode = 'auto'
    end
    
    properties (Hidden, Constant)
        % List of properties that cannot be set prior to "plot" execution.
        %
        % If the property demands a data trace, it must have a set-function
        % to perform the test:
        %
        %   if mustDeferPropertyChange(p,propName)
        %      return
        %   end
        %
        DeferredProperties = { ...
            'Peaks','Span','Interactive','AntennaMetrics', ...
            'TitleTop','TitleBottom', ...
            'MagnitudeLim', 'MagnitudeLimBounds', ...
            'AngleLimVisible', 'AngleTickLabelFormat'}
        
        
        % True enables the "Show Spans" measurement option always
        %   - in which case we add up to two cursors to support this
        % False enables it only if at least two markers are present
        AddMarkersToEnableSpanMode = true
        
        % True enables angle highlight (4-arrows) on mouse-hover;
        % false shows highlight only on mouse-down
        AngleHiliteOnHover = false
        MagHiliteOnHover = false
        
        % Enable drag of angle-tick in radial direction
        EnableAngleDragRadialDir = true
        
        % When true, highlight all cursors that are on the same dataset
        % when hovering over any cursor. When false, highlights only a
        % single cursor.
        HiliteAllRelatedCursorsWhenHovering = false;
        
        % When true, highlights all peaks (not cursors) that are on the
        % same dataset when hovering over any peak in the set. When false,
        % highlights only one peak in the set.
        HiliteAllRelatedPeaksWhenHovering = false
        
        % Default labels to use with legend, etc, when none specified by
        % public Labels property.
        DefaultDataLabel = 'Dataset %d'
        
        UseDegreeSymbol = false
        
        % Minimum and maximum font size, in points, when resizing
        FontSizeLimits = [4 20]
        
        TitleFontSizeLimits = [4 96]
        
        % Setting to use when enabling Peaks on a trace
        DefaultNewPeaks = 3
        
        % Enable: plot(p) can regenerate plot after its axis was deleted or
        % the figure was closed.
        %
        % However, an instance of polar is retained using
        % uiservices.manager, effectively "leaking" memory for the duration
        % of the session.
        %
        % Disable: plot(p) cannot regenerate a deleted polar axis. However,
        % no memory is leaked for the MATLAB session.
        EnablePlotAfterClose = false
        
        % Normalized height of rect used to detect mouse hover over the
        % magnitude axis tick labels.  Rect has this height, and length
        % spanning from just "below" the polar plot origin to just "past"
        % the polar plot maximum magnitude circle.
        MagnitudeHitBoxNormHeight = 0.12
        
        % Degree offset used for automatic angle for display of magnitude
        % axis ticks.
        MagTickLabelAngleAutoOffset = 15
        
        % Choose mag tick hilite colorization mode:
        %  0: color both uniformly with grid background/foreground
        %  1: color each differently based on upper vs lower selection
        %  2: color both uniformly but with a hilite color
        MagTickUpDnArrowColor = 2
        
        % Half-angle in degrees (+/- this angle) over which we declare the
        % magnitude tick axis to be in the "east" or "west" direction, and
        % override the magnitude tick label angle to be 0-degrees.  This
        % leads to easier viewing.
        MagnitudeTickAngleOrientationThreshold = 15
        
        MaxNumAngleLabels = 36 % one angle label every 10 degrees
        
        % Maximum number of radial grid lines when angle refinement is
        % enabled.
        MaxNumRefinementLines = 180
        
        % True if ZeroAngleLine should extend to the circle origin, even
        % when DrawGridToOrigin=false.
        FullZeroAngleLine = true
        
        % Number of seconds delay before splash screen comes up.
        % Splash screen closes when plot is fully initialized.
        %  - Set to a short delay to have splash quickly display
        %  - Set to a long delay to prevent splash from displaying
        SplashDelay = 0.6
        
        % True to display arrowhead denoting CW direction
        ZeroAngleLineCWMarker = true
        
        % Behavior of "Show details" context menu for peaks and cursors
        % angle markers:
        %     True: toggle state for all peaks/cursors markers
        %    False: toggle state for just the selected peak/cursor marker
        %ShowDetailsForAllMarkerType = true
        
        % Behavior of change in cursor and peak marker detail display,
        % triggered via double-click on marker.
        %
        % True synchronizes detail display across all markers.
        % False enables individual markers to change its detail level.
        SyncCursorMarkerDetailChange = true
        SyncPeakMarkerDetailChange = true
        
        % True shows magnitude units in marker detail view.
        %
        % Units will be exponent scale-factor, such as "e3", if
        % MagnitudeUnits is empty, or a user-specified string unit with MKS
        % prefix, such as "kV", if MagnitudeUnits is not empty.
        IncludeMagUnitsInMarkerDisplay = false
        
        % Radial positioning of angle markers
        %    True: marker tip overlaps unit circle
        %   False: marker tip touches unit circle
        AngleMarkerTipOverlap = false
        
        % Keep data-dot (circle around datapoint in a trace) visible for
        % each cursor.  True keeps it always visible.  False makes it
        % visible only while button is held while hovering over cursor.
        KeepCursorDataDotVisible = true
        
        % Minimum radial distance of mouse-drag before we detect a
        % "magnitude limit change" request.  Normalized radial distance is
        % 0 to 1.
        % normalized radial distance, [near_origin near_outer_edge]
        MagLimChangeDetect_MinNormDist = [0.005 0.05]
        
        MagAngleChangeDetect_MinTheta = [5.0 1.0] % degrees
        
        
        % String to use when creating a new title
        %  - specifically, a double-click in region above or below
        %    the polar circle, when NO the relevant title string is
        %    currently empty
        NewTitleString = '<new title>'
        
        % Enumeration lists
        % Shashank
        DataUnitsValues =  {'linear','dB','dB loss'};
        DisplayUnitsValues = {'linear','dB'};
        
         ViewValues = {...
            getString(message('siglib:polari:Menufull')),...
            getString(message('siglib:polari:Menutop')),...
            getString(message('siglib:polari:Menubottom')),...
            getString(message('siglib:polari:Menuleft')), ...
            getString(message('siglib:polari:Menuright')),...
            getString(message('siglib:polari:Menutopleft')),...
            getString(message('siglib:polari:Menutopright')),...
            getString(message('siglib:polari:Menubottomleft')),...
            getString(message('siglib:polari:Menubottomright'))}
        MarkerValues = { ...
            'none','+','o','*','.','x','square','diamond', ...
            'v','^','>','<','pentagram','hexagram' }
        AngleTickLabelFormatStrs = {'180','360','compass','property'}
        AngleResValueStrs = {'90','45','30','22.5','15','10'}
        AngleResValues = [90 45 30 22.5 15 10]
        LineStyleValues = {'none','-','--',':','-.'}
        
        % NOTE: 'sectors' is removed from createDisplayContextMenu(), but
        % remains available from the command line interface.
        StyleValues = {getString(message('siglib:polari:MenuLine')),getString(message('siglib:polari:MenuFilled')),'sectors'}
        
        % Discrete set of peak-count values, for use in context menus
        %PeaksValues = {'all','none','1','2','3','4','5','10'}
        %PeaksValuesInt = [inf 0 1 2 3 4 5 10]
        PeaksValues = {'all','1','2','3','4','5','10'}
        PeaksValuesInt = [inf 1 2 3 4 5 10]
        
        TickLabelColorModeValues = {'auto','contrast','grid','manual'}
        
        TitleInterpreterStrings = {'none','tex','latex'}
        
        %BringToFrontValues = {'Bring to Front','Bring Forward'}
        %SendToBackValues = {'Send to Back','Send Backward'}
    end
    
    properties (Hidden)
        % Index identifying this polarpattern axes
        %
        % This is a copy of the 'PolariAxesIndex' appdata value set on the
        % axes itself:
        %    p.pAxesIndex = axesIndex;
        %    setappdata(ax,'PolariAxesIndex',axesIndex);
        pAxesIndex
        
        % Post-processed data vectors
        % - interpolated theta for sector data
        pData
        pData_Raw
        
        % True when:
        %  - new data is passed (add/replace)
        %  - input or display units are changed
        DataCacheDirty = true
        
        pMagnitudeUnits       % string mks units for mag scaling
        pMagnitudeScale
        
        % Contains uniform RGB matrix, possibly multiple rows.
        % Gets conversion from .ColorOrder, which could be string names of
        % colors
        pColorOrder
        
        hToolTip
        hBannerMessage
        hAngleSpan
        
        pDataStyleChanged = false
        pPlotExecutedAtLeastOnce = false
        pPublicPropertiesDirty = true
        
        % polariMouseBehavior object
        pMouseBehavior = []
        pMouseBehaviorCache = containers.Map
        
        % Affects command-line display of this object
        pShowAllProperties = false
        
        % Cell-vector used to defer property changes until next mouse
        % motion.
        %
        % Typically used when an HG callback invokes a change, but we
        % cannot immediately update the widget when it is in its own
        % callback.  So we defer until the next mouse motion.
        pDelayedParamChanges = {}
        
        % Flag indicating we are in a sequence of update calls, true when
        % update first called (really, suspendDataMarkers), reset when
        % resumeDataMarkers gets called.
        pUpdateCalled = false
        
        % Signals temporary marker was created during single-click mouse
        % drag on a dataset, and that it is to be deleted on button-up.
        pDeleteCurrentMarkerOnButtonRelease = false
        
        % Used to retain angles of all Cursor markers during a "suspend"
        % operation, such as the first animate() call.
        %
        % Only Cursors (Data markers), but not peaks (they restore
        % differently).  And no AngleLim cursors since they aren't data
        % cursors.
        pSuspendDataMarkerAngles = []
        
        % One-time display of initial banner message that reminds the user
        % that mouse interactions are possible
        pShownInteractiveBehaviorBanner = false;
        BannerMessageUpTime = 8   % Initialized to 8 sec
        
        % Store vector corresponding to AngleRange
        %  AngleRange='180': pAngleRange = [-180 180]
        %  AngleRange='360': pAngleRange = [0 360]
        pAngleRange = [-180 180]
        
        pAngleLim = [0 360]        % default AngleLim range
        pAngleLimCursorVis = false % true when AngleLim cursors shown
        
        pAngleTickCompassPoints = false % show compass points
        pCompassPointsMap   % map: key=angles, val=compass point strings
        
        pMagnitudeLim = [-50 0]    % mag limits (orig/unscaled values)
        pMagnitudeLim_Scaled       % scaled values
        pMagnitudeTick = -50:10:0  % vector of ticks, auto-computed or manual
        pMagnitudeTick_Scaled      % scaled values, also pruned for non-visible ticks
        
        pMagnitudeCircleRadii      % vector of normalized radii at which circles are drawn
        pMagnitudeAxisAngle        % mag tick line angle (auto and manual)
        pMagAxisHilite = 'none'    % Mag tick label hilight: none|upper|lower|upperlower
        hMagAxisHilite        % struct with .up, .dn, .lt, .rt handles
        hMagRegionRect        % "invisible" patch under mag-tick region
        
        pAngleLabelCoords     % struct of .x, .y, .thetaStrs
        pMagnitudeLabelCoords % struct of .ang, .costh, .sinth, .textAngle
        
        pAngleTickLabel
        pAngleTickLabelColor
        pMagnitudeTickLabelColor
        pFontSize
        
        hDataPatch      % Patch representing polar data
        hDataLineGlow
        hIntensitySurf      % surf for intensity (3D) display
        
        pHoverDataSetIndex % versus pCurrentDataSetIndex
        
        % Vector of non-negative integers representing Peaks setting for
        % each dataset. May be 0, 1, 2, ... inf.  Always contains one
        % integer per dataset, while Peaks may have fewer values.
        %
        pPeaks = []
        pPeaksLast = [] % for difference testing
        % Cell-vector, one entry per dataset.  Each entry is a vector (2D)
        % or matrix (3D) of indices corresponding to peak locations as
        % computed by findpeaks.
        pPeakLocationList = {}
        
        % internal.polariAntenna object
        hAntenna
        hPeakTabularReadout
        
        % ID of currently highlighted angle marker, ex: 'P2' or 'C1'
        pAngleMarkerHoverID = ''
        % Are we responding to a double-click on angle marker?
        pAngleMarker_MouseOpenEvent = false
        
        hLegend         % handle to legend widget
        pLegend = false % state of Legend visibility
        pLabels = ''    % char or cell-string
        pLabelsPendingUpdate = false
        
        % cell-string of data labels, derived from public Labels.
        % This is always a cell-string, scalar-expanded for each data set,
        % translated extended-ASCII chars, etc.
        pDataLabels = {}
        
        hZeroLine
        hCircles = cell(1,3) % vector of patch handles
        hRadialLines         % vector of line handles
        hRefinementLines
        hAngleText
        hMagText
        hMagScale
        hMagAxisLocator
        hListeners
        hCurrentObject
        ChangedState = true
        LastMouseBehavior = 'none'
        
        % Top and bottom title text
        hTitleTop
        hTitleBottom
        pTitleOffset_Temp = 0 % temp offset during interactive title drag
        
        % holds last-defined mouse motion event
        pLatestMotionEv
        
        hAngleTickLabelHilite  % struct with .ud and .lr, holds handles
        pAngleTickLabelHilite = false
        pClosestAngleTickLabel = 0
        pClosestAngleTickLabel_origpt = []
        
        pShiftKeyPressed = false
        pLastShiftKeyPressed = false
        
        AngleDrag_StartAngleClicked
        AngleDrag_StartMagClicked
        AngleDrag_StartShiftPressed
        AngleDrag_ChangedAngle = false
        AngleDrag_ChangedMag   = false
        
        % Gets set > 0 when quantized angle rotation is enforced during
        % interactive rotation of angle ticks.  Typical is half the angle
        % tick difference.
        pAngleRotationStepSize
        
        pGridMotion_ChangingLowerLim = -1
        MagDrag_ChangedAngle        = false
        MagDrag_ChangedMagnitudeLim = false
        MagDrag_OrigMagnitudeLim
        MagDrag_OrigRadius
        MagDrag_MouseDown
        MagDrag_AngleDelta = 0
        
        hSpanHilite          % Span hilite patch handle
        SpanDrag_PrevCplx    % complex value representing mouse point
        SpanDrag_CacheInfo   % struct of info at buttondown time
        
        SpanReadout_CacheInfo  % struct of info at buttondown time
        AntennaReadout_CacheInfo
        
        MarkerDrag_Info
        
        UIContextMenu_Master      % master context menu
        UIContextMenu_AngleTicks
        UIContextMenu_MagTicks
        UIContextMenu_Grid
        UIContextMenu_Data
        
    end
    
    properties (Hidden, SetObservable)
        % Peak-related properties:
        %  .Peaks
        %  .PeaksOptions
        %
        % vector of angleMarker handles from a prior call to updatePeaks.
        % This is retained so we can remove/update markers.
        hPeakAngleMarkers
        
        % Vector of polariAngleMarker objects: general cursors
        hCursorAngleMarkers
        
        pCurrentDataSetIndex = 1
        
        % Data markers in 'sectors' style (line/polygon markers)
        hDataLine
        hAxes
        hFigure
        AngleDrag_Delta = 0
    end
    
    properties (Hidden, Dependent, AbortSet, SetObservable)
        %(Access={?internal.polariAngleMarker}, Dependent, AbortSet, SetObservable)
        
        % Range of angle tick labels.
        %   Set to '180' to display angles from -180 to +180.
        %   Set to '360' to display angles from 0 to 360.
        AngleRange
    end
    
    properties (SetObservable, Access=private)
        % Vector of polarAngleMarker objects: angle limit cursors
        hAngleLimCursors
    end

    properties
   
        
    end
    
    
    % Functions that get invoked without an object instance
    methods (Static)
        %         shortcuts(p)
        keywords(p)
        multiaxes
        formats
    end
    
    methods (Static,Hidden)
        [p,idx] = getAllPolari()
        [p,idx] = getAllPlots(fig)
        [p,idx] = getCurrentPlot(ax)
    end
    
    methods (Static,Hidden)
        multiValueContextMenuCB(targetObj,hm,str,strs,datasetIdx,propName)
    end
    
    methods
        function p = polari(varargin)
            %POLARI Return an object without rendering a plot.
            %
            %  polari(P1,V1,...) sets property P1 to value V1.  Multiple
            %  parameter/value pairs may be passed.
            %
            %  polari(D) plots data D in polar format, where the data
            %  type of D is used to interpret the data as follows:
            %     Real vector: data represents magnitude values, with
            %        corresponding angles assumed to be uniformly
            %        distributed around the unit cirle, from 0 to
            %        (N-1)/N*360 degrees.
            %     Real Nx2 matrix: data represents magnitude values in
            %        column 1 and corresponding angles in column 2.  Angles
            %        are assumed to be in degrees.
            %     Complex vector: data represents cartesian coordinates,
            %        where x is real(D) and y is imag(D).  These complex
            %        values are converted to polar form.
            %
            %  polari(D,P1,V1,...) enables one or more properties to be
            %     set to their corresponding values.
            %
            % polari(R,TH) plots data in polar format, where vector R
            %    represents magnitudes and vector TH angles of the data.
            %    TH is assumed to be in degrees.
            %
            % polari(R,TH,P1,V1,...) enables one or more properties to
            %    be set to their corresponding values.

            p = p@internal.polarbase;
            p = p@internal.polariutils.ThemePolari;
            
            % Parse and react to optional handle argument passed to polari.
            %
            % This will set .Parent and .hFigure, and possibly .hAxes, if
            % an appropriate handle is passed to the constructor as the
            % first input arg:
            args = parseLeadingHandle(p,varargin);
            
            % getParentFig will respect whatever parseLeadingHandle has
            % optionally done, and it will fully resolve .Parent and
            % .hFigure while .hAxes may still remain empty:
            getParentFig(p);

            %matlab.graphics.internal.themes.figureUseDesktopTheme(p.hFigure);
            %updatePolarPlotTheme(p)
            % p.hFigure.ThemeChangedFcn = @(h,ev)updatePolarPlotTheme(p);
            
            % Is there an existing axes, and if so, is it a polari?
            is_existing_polari_axes = isPolariAxes(p);
            if is_existing_polari_axes
                % Want to know the NextPlot state of the EXISTING polari
                % instance, not the NEW polari instance.
                exist_ax = p.hAxes;
                pExist = internal.polari.getCurrentPlot(exist_ax);
                if strcmpi(pExist.NextPlot,'replace')
                    % Take over (replace) existing polari axes by deleting
                    % old polari instance:
                    delete(pExist);
                    is_existing_polari_axes = false;
                end
            end
            
            if is_existing_polari_axes
                % Adding new polari data to existing polari axes, even
                % though it was a call to a new instance.
                %
                % We only get here is axes "hold" is "on"
                %
                % - Abandon (ultimately, delete) the NEW polari object
                % - Return handle to the EXISTING polari object
                % - Call add() automatically, as required by p.NextPlot
                % - Keeps all polari axes settings, which could be
                %   surprising if user doesn't recall they have "hold on"
                
                % We need to clear out property values from the "old"
                % instance handle, as the old instance will be passed to
                % the delete method, and that will try to destroy the HG
                % axes, etc, if these properties are left non-empty:
                p.hAxes   = [];
                p.hFigure = [];
                p.Parent  = [];
                
                % Now overwrite p with the existing polari object:
                p = pExist;
                
                % Want to do this, but it's too much here:
                %  post_pv = parseArgs(p,varargin);
                %
                % Need only part of parseArgs:
                %
                % Identify trailing pv-pair input args
                %   polari(P1,V1,...)
                %   polari(H, P1,V1,...)
                %   polari(D1,D2,..., P1,V1,...)
                %   polari(H, D1,D2,..., P1,V1,...)
                %   etc
                [args,pre_pv,post_pv] = parsePVPairArgs(p,args);
                parseData(p,args);
                
                % Set "pre-plot" (non-deferred) properties.
                %
                % Defer "post-plot" properties, returning those to caller.
                for i = 1:2:numel(pre_pv)
                    p.(pre_pv{i}) = pre_pv{i+1};
                end
            else
                post_pv = parseArgs(p,args); %varargin Shashank
            end
            
            % Always do this:
            plot(p);
            
            if ~is_existing_polari_axes
                % Only needed for first-time polari object construction:
                try
                    s = settings;
                    if ~s.matlab.ui.internal.uicontrol.UseRedirect.TemporaryValue && ...
                            ~s.matlab.ui.internal.uicontrol.UseRedirectInUifigure.TemporaryValue
                        initToolTip(p);
                    end
                catch
                    initToolTip(p);
                end
                initBannerMessage(p);
            end
            
            % Set "post-plot" constructor property values
            % (deferred properties set here)
            for i = 1:2:numel(post_pv)
                p.(post_pv{i}) = post_pv{i+1};
            end
                % if matlab.graphics.interaction.interactionoptions.useInteractionOptions(p.hAxes)
                %     p.hAxes.InteractionOptions.PanLimitsBounded = 'on';
                % end
            p.updateThemeColors();
            disableDefaultInteractivity(p.hAxes)

            
        end
    end
    
    methods
        delete(p)
        add(p,varargin)
        replace(p,varargin)
        animate(p,varargin)
        ret = addCursor(p,ang,datasetIdx)
        ret = showSpan(p,id1,id2,reorder)
        createLabels(p,varargin)
        
        L = findLobes(p,datasetIndex,forceRecompute)
        showBeamSpan(p,id1,id2,datasetIndex)
    end
    
    methods (Hidden)
        proceed = hideLobesAndMarkers(p)
        showLobes(p,datasetIndex)
        hideLobes(p)
        updatePolarPlotTheme(p)
    end
    
    methods
        function set.AntennaMetrics(p,val)
            % Change state of Antenna metrics/lobe visibility
            
            if mustDeferPropertyChange(p,'AntennaMetrics')
                return
            end
            hc = p.UIContextMenu_Master;
            hm = hc.findobj('Label',getString(message('siglib:polari:MenuMeasurements')),'-depth',1);
            
            if isappdata(hm,'RFMetrics')
                error(message('siglib:polarpattern:RFMetrics'));
            end
            if val
                showLobes(p);
            else
                hideLobes(p);
            end
        end
        
        function val = get.AntennaMetrics(p)
            % True if Antenna metrics/lobes are visible
            a = p.hAntenna;
            val = ~isempty(a) && areLobesVisible(a);
        end
        
        function set.CleanData(p,val)
            % Change state of Antenna metrics/lobe visibility
            if val
                cleanData(p);
            end
        end
        
        function val = get.CleanData(p)
            % False if data contains (has no -Inf and NaNs)
            val = ~isDataClean(p);
        end
        
        function y = get.PeakMarkers(p)
            m = p.hPeakAngleMarkers;
            if isempty(m)
                y = markerInfo(internal.polariAngleMarker.empty);
            else
                [~,idx] = sort({m.ID});
                y = markerInfo(m(idx));
            end
        end
        
        function y = get.CursorMarkers(p)
            m = p.hCursorAngleMarkers;
            if isempty(m)
                y = markerInfo(internal.polariAngleMarker.empty);
            else
                [~,idx] = sort({m.ID});
                y = markerInfo(m(idx));
            end
        end
        
        function y = get.AngleMarkers(p)
            % Return struct with angle marker details.
            
            m = [p.hCursorAngleMarkers;p.hPeakAngleMarkers];
            if isempty(m)
                y = markerInfo(internal.polariAngleMarker.empty);
            else
                [~,idx] = sort({m.ID});
                y = markerInfo(m(idx));
            end
        end
        
        function y = get.SpanDetails(p)
            % Return struct with span details.
            
            s = p.hAngleSpan;
            if isempty(s)
                s = internal.polariAngleSpan.empty;
            end
            y = spanDetails(s);
        end
        
        function set.AngleData(p,val) %#ok<INUSD>
            errorUseMethodsToModifyData;
        end
        
        function set.MagnitudeData(p,val) %#ok<INUSD>
            errorUseMethodsToModifyData;
        end
        
        function val = get.AngleData(p)
            % Return magnitude data from array of structs.
            %
            % If multiple datasets, return cell vector of magnitude
            % vectors.
            %
            % If only one dataset, return non-cell.
            
            d = p.pData_Raw;
            
            if isempty(d)
                val = [];
            elseif isscalar(d)
                val = d.ang_orig;
            else
                val = {d.ang_orig};
            end
        end
        
        function val = get.MagnitudeData(p)
            % Return magnitude data from array of structs.
            %
            % If multiple datasets, return cell vector of magnitude
            % vectors.
            %
            % If only one dataset, return non-cell.
            
            d = p.pData_Raw;
            if isempty(d)
                val = [];
            elseif isscalar(d)
                val = d.mag;
            else
                val = {d.mag};
            end
        end
        
        function val = get.IntensityData(p)
            d = p.pData_Raw;
            if isempty(d) || ~isIntensityData(p)
                val = [];
            else
                val = d.intensity;
            end
        end
        
        function val = get.ActiveDataset(p)
            % Index of active dataset
            val = p.pCurrentDataSetIndex;
        end
        
        function set.ActiveDataset(p,val)
            % Index of active dataset.
            %
            % This property is excluded from getSetObservableProps.
            % We do the update explicitly here.
            
            validateattributes(val,{'numeric'}, ...
                {'scalar','positive','real','finite'}, ...
                'polari','ActiveDataset');
            % It's not just active flag and legend: we need to reorder
            % datasets to bring this one on top
            reorderDataPlot(p,+1,val);
        end
        
        function set.AngleLimVisible(p,val)
            % Accept numeric of any type convertible to a logical.
            validateattributes(val,{'numeric','logical'}, ...
                {'scalar','real'},'polari','AngleLimVisible');
            
            % Deferred-set property:
            if mustDeferPropertyChange(p,'AngleLimVisible')
                return
            end
            
            % AngleLimVisible is not setObservable.
            %
            % We perform side-effects here:
            showAngleLimCursors(p,logical(val));
            p.updateThemeColors();
        end
        
        function val = get.AngleLimVisible(p)
            val = p.pAngleLimCursorVis;
        end
        
        function val = get.AngleLim(p)
            val = p.pAngleLim;
        end
        
        function set.AngleLim(p,val)
            validateattributes(val,{'numeric'}, ...
                {'real','size',[1 2],'finite'}, ...
                'polari','AngleLim');
            
            % Store in pAngleLim while preventing zero-span:
            newval = adjustAngleLimForFullCircle(p,val);
            if ~isequal(newval,val)
                warning(message('siglib:polari:AngleLimMustBeDistinct'));
            end
            
            % Side-effect:
            showAngleLimCursors(p);
        end
        
        function set.AngleAtTop(p,val)
            validateattributes(val,{'numeric'}, ...
                {'scalar','finite','real'}, ...
                'polari','AngleAtTop');
            p.AngleAtTop = val;
        end
        
        function set.AngleDirection(p,val)
            val = validatestring(val,{getString(message('siglib:polari:MenuCW')),getString(message('siglib:polari:MenuCCW'))}, ...
                'polari','AngleDirection');
            
            % Although AbortSet is used, 'ccw' and 'CCW' are different, and
            % we check that here
            if ~strcmpi(val,p.AngleDirection)
                p.AngleDirection = val;
                
                % Side-effect:
                %
                % If angle span measurement is enabled, swap span endpoints
                % so span region doesn't go "inside-out" due to cw/ccw
                % change.
                if ~isempty(p.hAngleSpan) %#ok<MCSUP>
                    m_SwapEndpoints(p.hAngleSpan); %#ok<MCSUP>
                end
            end
        end
        
        function val = get.AngleRange(p)
            
            if p.pAngleRange(2) == 180
                val = '180';
            else
                val = '360';
            end
        end
        
        function set.AngleRange(p,val)
            % AngleRange is an enumeration string
            val = validatestring(val,{'180','360'}, ...
                'polari','AngleRange');
            
            % Map from the string to a 2-element range vector
            if strcmp(val,'180')
                a = [-180 180];
            else
                a = [0 360];
            end
            p.pAngleRange = a;
        end
        
        function set.AngleTickLabelFormat(p,val)
            % AngleTickLabelFormat is an enumeration string
            val = validatestring(val, p.AngleTickLabelFormatStrs, ...
                'polari','AngleTickLabelFormat');
            p.AngleTickLabelFormat = val;
            
            updateAngleTickLabelFormat(p);
        end
        
        %{
        function set.AngleMarkerTipOverlap(p,val)
            % Apply to all existing markers

            % Accept numeric of any type convertible to a logical.
            validateattributes(val,{'numeric','logical'}, ...
                {'scalar','real'},'polari','AngleMarkerTipOverlap');

            p.AngleMarkerTipOverlap = val;
            
            updateMarkerTipOverlap(p); % Side-effect
        end
        %}
        
        function set.LegendLabels(p,val)
            if iscell(val)
                [val{:}] = convertStringsToChars(val{:});
            end
            if ~(ischar(val) || iscellstr(val) || isstring(val) || iscell(val) && isempty(val))
                error(message('siglib:polarpattern:IncorrectDataType','LegendLabels'));
                %error('LegendLabels must be a string or a cell-vector of strings.');
            end
            p.pLabels = val;
            
            % LegendLabels is not setObservable.
            %
            % Side-effect: update labels for use in legend
            updateDataLabels(p,'force');
            
            % Side-effect: enable Legend display
            p.LegendVisible = true;
        end
        
        function val = get.LegendLabels(p)
            val = p.pLabels;
        end
        
        function set.Span(p,val)
            % Accept numeric of any type convertible to a logical.
            validateattributes(val,{'numeric','logical'}, ...
                {'scalar','real'},'polari','Span');
            
            % Deferred-set property:
            if mustDeferPropertyChange(p,'Span')
                return
            end
            
            % Spans is not setObservable.
            %
            % We perform side-effects here:
            showAngleSpan(p,logical(val));
        end
        
        function val = get.Span(p)
            % True if angle span object is present and visible
            val = ~isempty(p.hAngleSpan) && p.hAngleSpan.Visible;
        end
        
        function set.LegendVisible(p,val)
            validateattributes(val,{'numeric','logical'}, ...
                {'scalar','real'},'polari','LegendVisible');
            
            % Legend is not setObservable.
            %
            % We perform side-effects here:
            p.pPublicPropertiesDirty = true;
            legend(p,logical(val));
        end
        
        function val = get.LegendVisible(p)
            val = p.pLegend;
        end
        
        function set.GridAutoRefinement(p,val)
            validateattributes(val,{'logical','numeric'}, ...
                {'scalar','real'}, 'polari','GridAutoRefinement');
            p.GridAutoRefinement = logical(val);
            
            labelCompassPoints(p); % Side-effect
        end
        
        function set.AngleTickLabelVisible(p,val)
            validateattributes(val,{'logical','numeric'}, ...
                {'scalar','real'}, ...
                'polari','AngleTickLabelVisible');
            p.AngleTickLabelVisible = val~=0;
        end
        
        function val = get.AngleTickLabelColor(p)
            % Depending on Mode return the respective value
            if strcmp(p.AngleTickLabelColorMode,'auto') || strcmp(p.AngleTickLabelColorMode,'contrast') || strcmp(p.AngleTickLabelColorMode,'grid') 
                val = getRGB(p,p.AngleTickLabelColor_I);
            else
                val = p.pAngleTickLabelColor;
            end
        end
        
        function set.AngleTickLabelColor(p,val)
            internal.ColorConversion.validatecolorspec(val, ...
                'polari','AngleTickLabelColor');
            
            % Primary storage
            p.pAngleTickLabelColor = val;
            
            % Side-effect of setting this is to switch to 'manual' mode
            enableListeners(p,false);
            p.AngleTickLabelColorMode = 'manual';
            enableListeners(p,true);
        end
        
        function set.GridBackgroundColor(obj,val)
            internal.ColorConversion.validatecolorspec(val, ...
                'polari','GridBackgroundColor');
            obj.GridBackgroundColor = val;
            obj.GridBackgroundColorMode = 'manual';
        end

        function rtn = get.GridBackgroundColor(obj)
            if strcmp(obj.GridBackgroundColorMode,'auto')
            
                RGB = obj.getRGB(obj.GridBackgroundColor_I);
                rtn = RGB;
            else

                rtn = obj.GridBackgroundColor;
            end
        end
        
        function set.GridForegroundColor(obj,val)
            internal.ColorConversion.validatecolorspec(val, ...
                'polari','GridForegroundColor');
            obj.GridForegroundColor = val;

            obj.GridForegroundColorMode = 'manual';
        end

        function rtn = get.GridForegroundColor(obj)
            if strcmp(obj.GridForegroundColorMode,'auto')
                RGB = obj.getRGB(obj.GridForegroundColor_I);
                rtn = RGB;
            else
     
                rtn = obj.GridForegroundColor;
            end
        end
        
        function set.AngleTickLabelColorMode(p,val)
            val = validatestring(val,p.TickLabelColorModeValues, ...
                'polari','AngleTickLabelColorMode');
            p.AngleTickLabelColorMode = val;
        end
        
        function set.AngleTickLabelMode(p,val)
            validstr = validatestring(val,{'auto','manual'}, ...
                'polari','AngleTickLabelMode');
            p.AngleTickLabelMode = validstr;
        end
        
        function set.AngleTickLabel(p,val)
            if ~ischar(val) && ~iscellstr(val) && ~isstring(val)
                error(message('siglib:polarpattern:IncorrectDataType','AngleTickLabel'));
                %error('AngleTickLabel must be a string or a cell-vector of strings.');
            end
            
            % Primary storage
            p.pAngleTickLabel = val;
            
            % Side-effect of setting this is to switch to 'manual' mode,
            % and to turn off compass points
            p.pAngleTickCompassPoints = false;
            
            enableListeners(p,false);
            p.AngleTickLabelMode = 'manual';
            p.AngleTickLabelFormat = 'property';
            enableListeners(p,true);
        end
        
        function val = get.AngleTickLabel(p)
            val = p.pAngleTickLabel;
        end
        
        function val = get.AngleTickCompassPoints(p)
            val = p.pAngleTickCompassPoints;
        end
        
        function set.AngleTickCompassPoints(p,val)
            validateattributes(val,{'numeric','logical'}, ...
                {'scalar','real'},'polari','AngleTickCompassPoints');
            
            p.pAngleTickCompassPoints = val;
            
            % side-effect
            if val
                labelCompassPoints(p);
            else
                p.AngleTickLabelMode = 'auto';
            end
        end
        
        function set.AngleResolution(p,val)
            validateattributes(val,{'numeric'}, ...
                {'real','finite','scalar','positive'}, ...
                'polari','AngleResolution');
            t = 90/double(val);
            if t~=fix(t)
                error(message('siglib:polarpattern:AngleSeperation'));
                %error('AngleResolution must evenly divide into 90 degrees.');
            end
            p.AngleResolution = val;
            
            labelCompassPoints(p); % Side-effect
        end
        
        function set.GridWidth(p,val)
            validateattributes(val,{'numeric'}, ...
                {'real','finite','scalar','positive'}, ...
                'polari','GridWidth');
            p.GridWidth = val;
        end
        
        function set.NextPlot(p,val)
            p.NextPlot = validatestring(val,{'replace','add','replacechildren'});
        end
        
        function set.Interactive(p,val)
            % Enable mouse-based interaction
            
            if mustDeferPropertyChange(p,'Interactive')
                return
            end
            
            p.Interactive = val;
            if val
                % Enable interactivity after it was disabled.
                %
                % To do this, we toggle away from then back to 'general',
                % as 'general' may be the current state and
                % changeMouseBehavior suppresses changes if the same new
                % mode is repeatedly set.
                changeMouseBehavior(p,'none');
                changeMouseBehavior(p,'general');
                enableContextMenus(p,true);
            else
                changeMouseBehavior(p,'none');
                enableContextMenus(p,false);
            end
        end
        
        function set.LineWidth(p,val)
            validateattributes(val,{'numeric'}, ...
                {'real','finite','positive','nonempty'}, ...
                'polari','LineWidth');
            p.LineWidth = val;
        end
        
        function set.LineStyle(p,val)
            % Allow string or cell-string.
            %
            % Allow empty strings to map to 'none'
            if ischar(val) || (isstring(val) && isscalar(val))
                if isempty(val)
                    val = 'none';
                end
                p.LineStyle = validatestring(val,p.LineStyleValues);
            else
                if ~iscellstr(val) && ~isstring(val)
                    error(message('siglib:polarpattern:IncorrectDataType','LineStyle'));
                    %error('LineStyle must be a string or a cellstring.');
                end
                for i = 1:numel(val)
                    v_i = val{i};
                    if isempty(v_i)
                        v_i = 'none';
                    end
                    val{i} = validatestring(v_i,p.LineStyleValues, ...
                        'polari','LineStyle');
                end
                p.LineStyle = val;
            end
        end
        
        function set.Marker(p,val)
            % Allow string or cell-string.
            if ischar(val) || (isstring(val) && isscalar(val))
                p.Marker = validatestring(val,p.MarkerValues);
            else
                if ~iscellstr(val) && ~isstring(val)
                    error(message('siglib:polarpattern:IncorrectDataType','Marker'));
                    %error('Marker must be a string or a cellstring.');
                end
                for i = 1:numel(val)
                    validatestring(val{i},p.MarkerValues, ...
                        'polari','Marker');
                end
                p.Marker = val;
            end
        end
        
        function set.MarkerSize(p,val)
            validateattributes(val,{'numeric'}, ...
                {'real','finite','scalar','positive'}, ...
                'polari','MarkerSize');
            p.MarkerSize = val;
        end
        
        function set.MagnitudeLim(p,val)
            validateattributes(val,{'numeric'}, ...
                {'real','size',[1 2],'finite'}, ...
                'polari','MagnitudeLim');
            
            % Could add 'increasing' to the attributes list above, but it's
            % more usable if we just sort the two values ourselves and
            % remove this opportunity for an error.
            %
            % Sort into ascending values:
            val = sort(val,'ascend');
            
            % Primary storage
            p.pMagnitudeLim = constrainMagnitudeLim(p,val);
            
            % Side-effect of setting this is to switch to 'manual' mode
            enableListeners(p,false);
            p.MagnitudeLimMode = 'manual';
            enableListeners(p,true);
        end
        
        function val = get.MagnitudeLim(p)
            val = p.pMagnitudeLim;
        end
        
        function set.MagnitudeLimBounds(p,val)
            % Allow infinite limits
            validateattributes(val,{'numeric'}, ...
                {'size',[1 2],'real'}, ...
                'polarpattern','MagnitudeLimBounds');
            
            if mustDeferPropertyChange(p,'MagnitudeLimBounds')
                return
            end
            
            % Could add 'increasing' to the attributes list above, but it's
            % more usable if we just sort the two values ourselves and
            % remove this opportunity for an error.
            %
            % Sort into ascending values:
            val = sort(val,'ascend');
            p.MagnitudeLimBounds = val;
            
            updateMagnitudeLim(p); % Side-effect
        end
        
        function set.MagnitudeLimMode(p,val)
            validstr = validatestring(val,{'auto','manual'}, ...
                'polari','MagnitudeLimMode');
            p.MagnitudeLimMode = validstr;
        end
        
        function set.AngleFontSizeMultiplier(p,val)
            validateattributes(val,{'numeric'}, ...
                {'scalar','finite','real','positive'}, ...
                'polari','AngleFontSizeMultiplier');
            
            p.AngleFontSizeMultiplier = val;
            
            % Side-effect:
            %adjustFontSize(p);
            resizeAxes(p);
        end
        
        function set.MagnitudeFontSizeMultiplier(p,val)
            validateattributes(val,{'numeric'}, ...
                {'scalar','finite','real','positive'}, ...
                'polari','MagnitudeFontSizeMultiplier');
            
            p.MagnitudeFontSizeMultiplier = val;
            
            % Side-effect:
            %adjustFontSize(p);
            resizeAxes(p);
        end
        
        function set.FontSize(p,val)
            validateattributes(val,{'numeric'}, ...
                {'scalar','finite','real','positive','integer'}, ...
                'polari','FontSize');
            
            % Primary storage
            if ~isequal(val,p.pFontSize) % allow for empty
                p.pFontSize = val;
                
                % Side-effect of setting this is to switch to 'manual' mode
                enableListeners(p,false);
                p.FontSizeMode = 'manual';
                enableListeners(p,true);
                
                % Side-effect:
                %adjustFontSize(p);
                resizeAxes(p);
            end
        end
        
        function set.ToolTips(p,val)
            validateattributes(val,{'logical','numeric'}, ...
                {'scalar','real'}, 'polari','ToolTips');
            p.ToolTips = val;
            
            % Manually update static Master context menu
            addMeasurementAndLegendMenus(p,p.UIContextMenu_Master,false,false); %#ok<MCSUP>
        end
        
        function set.TitleTopFontSizeMultiplier(p,val)
            validateattributes(val,{'numeric'}, ...
                {'scalar','finite','real','positive'}, ...
                'polari','TitleTopFontSizeMultiplier');
            
            p.TitleTopFontSizeMultiplier = val;
            updateTitleFont(p); % Side-effect
        end
        
        function set.TitleBottomFontSizeMultiplier(p,val)
            validateattributes(val,{'numeric'}, ...
                {'scalar','finite','real','positive'}, ...
                'polari','TitleBottomFontSizeMultiplier');
            
            p.TitleBottomFontSizeMultiplier = val;
            updateTitleFont(p); % Side-effect
        end
        
        function set.TitleTopFontWeight(p,val)
            validatestring(val,{'normal','bold'},'polari','TitleTopFontWeight');
            
            p.TitleTopFontWeight = val;
            updateTitleFont(p); % Side-effect
        end
        
        function set.TitleBottomFontWeight(p,val)
            validatestring(val,{'normal','bold'},'polari','TitleBottomFontWeight');
            
            p.TitleBottomFontWeight = val;
            updateTitleFont(p); % Side-effect
        end
        
        function set.TitleTopTextInterpreter(p,val)
            p.TitleTopTextInterpreter = ...
                validatestring(val,p.TitleInterpreterStrings, ...
                'polari','TitleTopTextInterpreter');
            updateTitleFont(p); % Side-effect
        end
        
        function set.TitleBottomTextInterpreter(p,val)
            p.TitleBottomTextInterpreter = ...
                validatestring(val,p.TitleInterpreterStrings, ...
                'polari','TitleBottomTextInterpreter');
            updateTitleFont(p); % Side-effect
        end
        
        function set.TitleTopOffset(p,val)
            % Set distance between top title string and angle
            % ticks.
            
            validateattributes(val,{'numeric'}, ...
                {'scalar','finite','real',...
                '>=',-0.5,'<=',+0.5}, ...
                'polari','TitleTopOffset');
            p.TitleTopOffset = val;
            updateTitlePos(p,'top');
        end
        
        function set.TitleBottomOffset(p,val)
            % Set distance between bottom title string and angle ticks.
            
            validateattributes(val,{'numeric'}, ...
                {'scalar','finite','real',...
                '>=',-0.5,'<=',+0.5}, ...
                'polari','TitleBottomOffset');
            
            p.TitleBottomOffset = val;
            updateTitlePos(p,'bottom');
        end
        
        function set.TitleTop(p,val)
            % We don't need to defer property change until data is plotted;
            % we just defer until post-plot call so axes and pixels are all
            % drawn once.
            %
            % This means we do NOT call mustDeferPropertyChange here -> we
            % do NOT want an error if titletop is modified with no data
            % drawn.  That's fine.
            setTitle(p,val,'top');
        end
        
        function val = get.TitleTop(p)
            val = getTitle(p,'top');
        end
        
        function set.TitleBottom(p,val)
            % We don't need to defer property change until data is plotted;
            % we just defer until post-plot call so axes and pixels are all
            % drawn once.
            %
            % This means we do NOT call mustDeferPropertyChange here -> we
            % do NOT want an error if titletop is modified with no data
            % drawn.  That's fine.
            setTitle(p,val,getString(message('siglib:polari:Menubottom')));
        end
        
        function val = get.TitleBottom(p)
            val = getTitle(p,'bottom');
        end
        
        function val = get.FontSize(p)
            val = p.pFontSize;
        end
        
        function set.FontSizeMode(p,val)
            validstr = validatestring(val,{'auto','manual'}, ...
                'polari','FontSizeMode');
            p.FontSizeMode = validstr;
            
            % side-effect:
            resizeAxes(p);
        end
        
        function set.MagnitudeAxisAngle(p,val)
            validateattributes(val,{'numeric'}, ...
                {'scalar','finite','real'}, ...
                'polari','MagnitudeAxisAngle');
            
            % Primary storage
            p.pMagnitudeAxisAngle = val;
            
            % Side-effect of setting this is to switch to 'manual' mode
            enableListeners(p,false);
            p.MagnitudeAxisAngleMode = 'manual';
            enableListeners(p,true);
        end
        
        function val = get.MagnitudeAxisAngle(p)
            val = p.pMagnitudeAxisAngle;
        end
        
        function set.MagnitudeAxisAngleMode(p,val)
            validstr = validatestring(val,{'auto','manual'}, ...
                'polari','MagnitudeAxisAngleMode');
            p.MagnitudeAxisAngleMode = validstr;
        end
        
        function set.MagnitudeTick(p,val)
            validateattributes(val,{'numeric'}, ...
                {'vector','finite'}, ...
                'polari','MagnitudeTick');
            
            % Could add 'increasing' to the attributes list above, but it's
            % more usable if we just sort the list ourselves and remove
            % this opportunity for an error.
            %
            % Sort into ascending values:
            val = sort(val,'ascend');
            
            % Primary storage
            p.pMagnitudeTick = val;
            
            % Side-effect of setting this is to switch to 'manual' mode
            enableListeners(p,false);
            p.MagnitudeTickMode = 'manual';
            enableListeners(p,true);
        end
        
        function val = get.MagnitudeTick(p)
            val = p.pMagnitudeTick;
        end
        
        function set.MagnitudeTickMode(p,val)
            validstr = validatestring(val,{'auto','manual'}, ...
                'polari','MagnitudeTickMode');
            p.MagnitudeTickMode = validstr;
        end
        
        function set.MagnitudeTickLabelVisible(p,val)
            validateattributes(val,{'logical','numeric'}, ...
                {'scalar','real'}, ...
                'polari','MagnitudeTickLabelVisible');
            
            % This is a fix for changes in visibility leaving the mag-tick
            % hilite visible.  We need to turn it off every time vis
            % changes.  If the mouse is still over the mag axis, then a
            % small bit of motion will cause it to return as expected.  The
            % case where the context-menu click is off-figure leaves the
            % hilite visible and it looks bad.
            hiliteMagAxisDrag_Init(p,'off');
            
            p.MagnitudeTickLabelVisible = logical(val);
        end
        
        function set.EdgeColor(p,val)
            internal.ColorConversion.validatecolorspec(val, ...
                'polari','EdgeColor');
            p.EdgeColor = val;
        end
        
        function set.MagnitudeTickLabelColor(p,val)
            internal.ColorConversion.validatecolorspec(val, ...
                'polari','MagnitudeTickLabelColor');
            
            % Primary storage
            p.pMagnitudeTickLabelColor = val;
            
            % Side-effect of setting this is to switch to 'manual' mode
            enableListeners(p,false);
            p.MagnitudeTickLabelColorMode = 'manual';
            enableListeners(p,true);
        end
        
        function val = get.MagnitudeTickLabelColor(p)
            if strcmp(p.MagnitudeTickLabelColorMode,'manual')
                val = p.pMagnitudeTickLabelColor;
            else
                val = p.getRGB(p.MagnitudeTickLabelColor_I);
            end
        end
        
        function set.MagnitudeTickLabelColorMode(p,val)
            val = validatestring(val,p.TickLabelColorModeValues, ...
                'polari','MagnitudeTickLabelColorMode');
            p.MagnitudeTickLabelColorMode = val;
        end
        
        function set.ColorOrder(p,val)
            % Could be an Nx3 matrix, a string or a cell-string
            %
            % Gets cached into .pColorOrder
            
            p.ColorOrder = ...
                internal.ColorConversion.validatecolorspecs(val,'polari','ColorOrder');
            obj.ColorOrderMode = 'manual';
        end
        
        function set.ColorOrderIndex(p,val)
            validateattributes(val,{'double','single'}, ...
                {'scalar','positive','real'}, ...
                'polari','ColorOrderIndex');
            p.ColorOrderIndex = val;
        end
        
        function set.Color(p,val)
            % Sets ColorOrder and ColorOrderIndex to set a line color.
            
            p.ColorOrder(1,:) = internal.ColorConversion.getRGBFromColor(val);
            p.ColorOrderIndex = 1;
        end
        
        function set.Style(p,val)
            %             validstr = validatestring(val,p.StyleValues, ...
            %                 'polari','Style');
            if ~strcmpi(val,p.StyleValues)
                error('Expected Style to match on of these strings: ''line'',''filled''. The input did not match any of the valid strings');
            end
            p.Style = val; %validstr
            
            p.pDataStyleChanged = true; %#ok<MCSUP>
        end
        
        function set.DataUnits(p,val)
            validstr = validatestring(val,p.DataUnitsValues, ...
                'polari','DataUnits');
            
            p.DataCacheDirty = true; %#ok<MCSUP>
            p.DataUnits = validstr;
        end
        
        function set.DisplayUnits(p,val)
            validstr = validatestring(val,p.DisplayUnitsValues, ...
                'polari','DisplayUnits');
            
            p.DataCacheDirty = true; %#ok<MCSUP>
            p.DisplayUnits = validstr;
        end
        
        function set.NormalizeData(p,val)
            validateattributes(val,{'numeric','logical'}, ...
                {'scalar','real'},'polari','NormalizeData');
            
            p.DataCacheDirty = true; %#ok<MCSUP>
            p.NormalizeData = logical(val);
        end
        
        function set.Peaks(p,val)
            % Scalar of vector of peak counts.
            % Must be non-negative integers, including inf.
            
            if mustDeferPropertyChange(p,'Peaks')
                return
            end
            
            % the 'integer' setting disallows inf, so we test integer-ness
            % manually after this:
            validateattributes(val,{'numeric'}, ...
                {'nonnegative','vector'},'polari','Peaks');
            
            if any(val~=fix(val))
                error(message('siglib:polarpattern:PeaksValue'));
            end
            
            % Check type, convert to cellstr, perform expansion
            N = getNumDatasets(p);
            Nv = numel(val);
            if Nv == 1
                % Repeat same integer for all current datasets
                val = val*ones(1,N);
            elseif Nv < N
                % Append zeros
                val = [val(:);zeros(N-Nv,1)]'; % row vec
            elseif Nv > N
                % Truncate
                val = val(1:N);
            end
            p.pPeaks = val;
            
            updatePeaks(p);
        end
        
        function val = get.Peaks(p)
            val = p.pPeaks;
        end
        
        function set.MagnitudeUnits(p,val)
            if ~isempty(val) && ~ischar(val) && ~(isstring(val) && isscalar(val))
                validateattributes(val,{'char'},{'row'}, ...
                    'polari','MagnitudeUnits');
            end
            p.MagnitudeUnits = val;
            
            if p.IncludeMagUnitsInMarkerDisplay
                % Units affect markers
                updateMarkers(p);  % xxx using manual push vs listener
            end
            %updateReadout(p);
        end
        
        function set.View(p,val)
            % View is not on the "getSetObservable" propChange list
            % We do all side-effects explicitly here
            
            orig_val = p.View;
            p.View = validatestring(val,p.ViewValues,'polari','View');
            
            % Side-effect: change in View forces auto mag axis mode, so
            % user can see the mag axis in case it would be out of view.
            p.MagnitudeAxisAngleMode = 'auto'; %#ok<MCSUP>
            propChange(p); % update grid, etc
            resizeAxes(p); % Resizes axes AND markers
            
            updateTitlePos(p,'top');
            updateTitlePos(p,'bottom');
            
            if ~strcmpi(orig_val,val)
                notify(p,'ViewChanged');
            end
        end
    end
    
    % Display customization
    %
    methods (Access=protected)
        header = getHeader(obj)
        group = getPropertyGroups(obj)
        group = displayGroupShort(obj,varname)
        group = displayGroupLong(obj)
    end
    
    methods (Access=protected)
        adjustFontSize(p)
%        pt = bestFontSize(p)
        enableContextMenus(p,state)
        cacheColorValues(p)
        create_context_menus(p)
        createDataContextMenu(p,hParent)
        delKeyPressed(p)
        fig = createNewFigure(p)
        createListeners(p)
        strs = createStringsForLegend(p)
%         destroyAxesChildren(p)
        destroyInstanceSpecificStuff(p,ax)
        ax = destroyStuffThatGetsRestoredWhenPlotIsCalled(p)
        drawCircles(p,isRotating)
        FigKeyEvent(p,ev)
        str = figureDataCursorUpdateFcn(p,e);
        [siz,mul] = getAngleFontSize(p,dir)
        [siz,mul] = getMagFontSize(p,dir)
        pInUse = getPolarAxes(p,forceReset)
        props = getSetObservableProps(p)
        s = initSplash(p)
        y = isPolariAxes(p)
        labelAngles(p)
        legend(p,varargin)
        legendBeingDestroyed(p)
        parseData(p,args)
        [args,pre_pv,post_pv] = parsePVPairArgs(p,args)
        [Zplane,hline,hglow] = points_recreateAllLines(p,Nd);
        plot(p,varargin)
        plot_axes(p,wasDirty);
        plot_data(p);
        plot_data_points(p);
        resetWidgetHandleProperties(p)
        setTitle(p,titleStr,place)
        updateAngleTickLabelColor(p)
        update = updateCache(p)
        updateDataLabels(p,action)
        updateGridView(p)
    end
    
    methods (Hidden)
        autoChangeMouseBehavior(p,s)
        s = computeHoverLocation(p,ev)
        c_updateLayout(p)
        executeDelayedParamChanges(p)
        installMouseBehavior(p,behaviorStr)
        y = isIntensityData(p)
        z = getDataPlotZ(p,datasetIndex)
        h = getDataWidgetHandles(p)
        th = getNormalizedAngle(p,theta)
        overrideAngleTickLabelVis(p,st)
        plot_glow(p,state,datasetIdx)
        reorderDataPlot(p,dir,datasetIdx)
        setDataPlotZ(p,z); % setDataPlotZ is called from polarbase
        %         updateTitlePos(p,select)
    end
    
    methods (Access=private)
        %         plot(p,varargin)
        suspendDataMarkers(p)
        resumeDataMarkers(p)
        a = createAntennaObjOnce(p)
        m_ToggleAntennaMetrics(p,datasetIndex)
        cleanData(p, datasetIndex)
        %         peaksIdx = peaks3D(p,datasetIndex,NPeaksOverride)
        m_toggleUpdatePeaks(p,datasetIndex)
        ids2 = expandAndCheckMarkerName(p,ids)
        [changeIdx,isZero] = findPeaksPropertyChanges(p,forceDatasetIdx)
        changed_datasetIdxVec = peaksUpdateLocationList(p,forceDatasetIdx)
        ds = getPeakMarkerDataset(p)
        plan = peakMarkerUpdatePlan(p,changedDatasets)
        setNewPeakMarkerDetailState(p,newPeakMarkers)
        setNewPeakMarkerReadoutState(p,newPeakMarkers)
        args = getPeaksArgs3D(p,im)
        labelCompassPoints(p)
        lim = findMagLimits(p)
        %         showSpanLurkingMode(p)
        %         addCursorEvery90(p,datasetIndex)
        [newMarkerIdx,currNumMarkers,currShowDetail] = ...
            nextAvailableMarkerIndex(p,markerType)
        h = angleMarker(p,markerType,markerIdx,dataIdx,datasetIndex)
        angleMarkerDetail_All(p,st,typ)
        plot_update(p,varargin);
        updateMarkersForDatasetChanges(p,prevCursorAngles);
        %         plot_axes(p,wasDirty);
        %         plot_data(p);
        %         plot_data_active(p);
        plot_data_intensity(p);
        plot_data_intensity_active(p);
        plot_data_sectors(p);
        plot_data_sectors_active(p);
        plot_data_polygon(p);
        plot_data_polygon_active(p);
        %         plot_data_points(p);
        plot_data_points_update(p);
        %         [Zplane,hline,hglow] = points_AddOrRemoveLinesAsNeeded(p,Nd);
        %         [Zplane,hline,hglow] = points_recreateAllLines(p,Nd);
        %         str = figureDataCursorUpdateFcn(p,e);
        %         plot_data_points_active(p);
        changeActiveDataset(p,newDataSetIndex);
        %         setDataPlotZ(p,z);
        %         openPropertyEditor_Dataset(p);
        %         updateAngleFont(p)
        updateMagFont(p)
        %         updateTitleFont(p)
        %         createTitlesContextMenu(p,hParent)
        %         val = getTitle(p,place)
        %         setTitle(p,titleStr,place)
        %         titleStringChanged(p,select)
        %         legend(p,varargin)
        %         strs = createStringsForLegend(p)
        %         updateLegend(p)
        %         updateLegendForActiveTrace(p)
        %         y = isLegendVisible(p)
        %         m_toggleLegend(p)
        %         legendBeingDestroyed(p)
        %         legendInteractiveChange(p)
        %         legendMarkedClean(p)
        %         post_pv = parseArgs(p,args)
        %         args = parseLeadingHandle(p,args)
        %         [args,pre_pv,post_pv] = parsePVPairArgs(p,args)
        %         fig = createNewFigure(p)
        %         getParentFig(p)
        %         pInUse = getPolarAxes(p,forceReset)
        %         y = isPolariAxes(p)
        %         y = mustDeferPropertyChange(p,propName)
        %         propChange(p)
        %         props = getSetObservableProps(p)
        %         update = updateCache(p)
        %         createListeners(p)
        %         deleteListeners(p)
        %         destroyAxes(p)
        %         destroyAxesContent(p)
        %         destroyInstanceSpecificStuff(p,ax)
        %         ax = destroyStuffThatGetsRestoredWhenPlotIsCalled(p)
        %         destroyAxesChildren(p)
        %         resetWidgetHandleProperties(p)
        %         restoreFigurePointer(p)
        destroyContextMenus(p)
        %         deleteObjectsInProperty(p,propName)
        %         s = initSplash(p)
        initBannerMessage(p)
        initToolTip(p)
        lim = constrainMagnitudeLim(p,lim)
        updateAxesMagLimits(p)
        %         changeAxesHoldState(p)
        %         z = getGridZ(p)
        drawRadialGridLines(p)
        drawGridRefinementLines(p)
        %         drawCircles(p,isRotating)
        %         updateGridView(p)
        %         cacheChangeInAxesPosition(p)
        labelMagnitudes(p)
        updateMagAxisLocator(p)
        %         labelAngles(p)
        cacheCoords_AngleTickLabels(p)
        cacheCoords_MagTickLabels(p)
        %         updateDataLabels(p,action)
        updateAngleTickLabel(p)
        %         updateAngleTickLabelColor(p)
        updateMagnitudeTickLabelColor(p)
        %         c = getPointsNextPlotColor(p)
        %         updateColorOrder(p)
        %         cacheColorValues(p)
        %         adjustFontSize(p)
        %         [siz,mul] = getTitleFontSize(p,sel,dir)
        %         [siz,mul] = getMagFontSize(p,dir)
        %         [siz,mul] = getAngleFontSize(p,dir)
        %         pt = getFontSize(p)
        %         pt = bestFontSize(p)
        %         create_context_menus(p)
        %         createDataContextMenu(p,hParent)
        createDisplayContextMenu(p,hParent)
        %createGridContextMenu(p,hParent)
        createMagnitudeContextMenu(p,hParent)
        createAngleContextMenu(p,hParent)
        createMeasurementContextMenu(p,hp,markerParent)
        %         parseData(p,args)
        updateTransformedData(p)
        pList = identifyOtherInstancesInFig(p)
        prevEna = enableMouseHandlers(pList,ena,prevEna)
        m = createAngleLimCursor(p,idx)
        updateAngleLimCursorContextMenu(p,hMenu,m)
        m_resetAngleLim(p)
        %         FigKeyEvent(p,ev)
        invokeLatestMouseMotionHandler(p,ev)
        peakTabularReadout(p,vis)
        %         enableContextMenus(p,state)
    end
    
    methods (Hidden)
        %         bgcolor = getBackgroundColorOfAxes(p)
        ext = getExtent(p,markerFlag)
        i_changeAngleAtTop(p)
        i_updateAngleLabelRotation(p)
        i_rotateToTopOfPlot(p,pt)
        i_updateAngleOfLabelMagnitudes(p,th)
        i_changeMagnitudeLim(p,labelVis)
        m_rotateToTopOfPlot(p)
        m_MagResetToDefaults(p)
        i_changeAngleLim(p)
        i_changeAngleResolution(p,res)
        i_changeAngleTickLabelColor(p)
        %         c_updateLayout(p)
        updateAngleTickLabelFormat(p)
        %         showAllProperties(obj)
        %         y = isIntensityData(p)
        %         instanceInfo(p)
        %         plot_glow(p,state,datasetIdx)
%                 reorderDataPlot(p,dir,datasetIdx)
        %         updateTitlePos(p,select)
        %         executeDelayedParamChanges(p)
        %         enableListeners(p,state)
        showBannerMessage(p,msg)
        %         resetToolTip(p)
        vecval = adjustAngleLimForFullCircle(p,val,idx)
        updateMagnitudeLim(p,lim,visFlag)
        overrideMagnitudeTickLabelVis(p,st)
        brkpt = getMagTickHoverBrkpt(p)
        %         overrideAngleTickLabelVis(p,st)
        addMeasurementAndLegendMenus(p,hc,make,topLevel,markerParent)
        %         addLegendMenus(p,hc,make)
        %         installMouseBehavior(p,behaviorStr)
        %         mb_Dispatch(p,ev,fcnType)
        %         changeMouseBehavior(p,mouseBehavior,signalChangedState)
        %         s = computeHoverLocation(p,ev)
        %         autoChangeMouseBehavior(p,s)
        %         showToolTipAndPtr_default(p)
        [pList,prevEna] = enableMouseInOtherInstances(p,ena,pList,prevEna)
        showAngleLimCursors(p,vis,prefAng)
        hiliteSpanDrag_Init(p,state)
        hiliteSpanDrag_Update(p)
        y = markersSurroundingSpan(p)
        y = isCloserToSpanStart(p,c_current)
        hiliteMagAxisDrag_Init(p,state,action)
        hiliteMagAxisDrag_Update(p,arrowAng)
        removeCursors(p,idx)
        m_addCursor(p,datasetIndex)
        m = i_addCursor(p,pt,datasetIndex)
        [m,sel] = findCursorAngleMarkerByID(p,ID)
        state = angleMarkerDetail(p,state,ID)
        updateMarkers(p)
        angleMarkerOriginLine(p,state,ID)
        angleMarkerHilite(p,newID)
        hideAngleMarkerDataDots(p,hide)
        m_reorderAngleMarker(p,ID,dir)
        [Nthis,Nall] = numMarkersOnDataset(p,datasetIndex)
        m = findAllMarkersWithSameTypeAndDataset(p,ID)
        reorderRelatedAngleMarkers(p,ID,dir)
        reorderAngleMarker(p,ID,dir)
        moveAngleMarkerVectorToFront(p,mThis)
        idx = peaks(p,varargin)
        %         resizeAxes(p)
        m = findPeakAngleMarkerByID(p,ID)
        updatePeaks(p,forceDatasetIdx)
        removePeaks(p,datasetIndex)
        userDeg = transformNormRadToUserDeg(p,normRad)
        userDeg = transformNormDegToUserDeg(p,normDeg)
        userDeg = principalRangeUserDeg(p,userDeg)
        th = getNormalizedAngleDeg(p,theta)
        userMag = transformNormMagToUserMag(p,normMag)
        r = getNormalizedMag(p,r)
        %         pdata = getAllDatasets(p)
        %         th = getNormalizedAngle(p,theta)
        [pdata,datasetIndex] = getDataset(p,datasetIndex)
        %         N = getNumDatasets(p)
        %         h = getDataWidgetHandles(p)
        removeAllCursors(p,datasetIdx)
        removeAngleMarkers(p)
        proceed = removeAngleMarkersWithDialog(p)
        m = addCursorAllArgs(p,dataIdx,datasetIndex)
        rgb = getDatasetColor(p,datasetIdx)
        m = findPeakMarkersOnDataset(p,idx)
%         z = getDataPlotZ(p,datasetIndex)
        [idx,datasetIndex] = getDataIndexFromPoint(p,pt,datasetIndex)
        magIdx = getMagIndexFromPoint(p,pt,datasetIndex)
        [mag_i,mag_scaled_i,nonRadial] = getInterpMagFromPoint(p,pt,datasetIndex)
        idx = getDataIndexFromAngle(p,ang,datasetIndex)
        [m,is_peak] = findAngleMarkerByID(p,ID)
        m_ToggleSpans(p,markerParent)
        showAngleSpan(p,newVis,markerParent)
        updatePeaksContextMenu(p,hMenu,m)
        updateCursorsContextMenu(p,hMenu,m)
        m_removeCursors(p,cursorIndex)
        m_exportCursors(p)
        m_refreshPeaks(p,datasetIndex)
        m_removePeaks(p,datasetIndex)
        m_exportPeaks(p)
        toggle = isDataClean(p, datasetIndex)
    end
    
    methods (Hidden)
        plot_data_active(p); % plot_data_active is called from polarbase
        updateLegendForActiveTrace(p) % updateLegendForActiveTrace is called from polarbase
    end
end
