function varargout = polarpattern(varargin)
%POLARPATTERN Interactive plot of radiation patterns in polar format.
%  POLARPATTERN plots sensor radiation patterns in polar format, as well as
%  other types of polar data where interactive data visualization and
%  measurement is desired. Right click on the figure window to interact.
%
%  POLARPATTERN(D) creates a polar plot based on real magnitude values in
%  vector D, with angles uniformly spaced on the unit circle starting at 0
%  degrees.  Magnitudes may be negative when dB data units are used. The
%  lowest (nearest -inf) magnitude is plotted at the origin and the highest
%  (nearest +inf) is at maximum radius.
%
%  For a matrix D, columns of D are independent datasets. For N-D arrays,
%  dimensions 2 and greater are independent datasets.  For complex values,
%  magnitude and angle are derived from D.
%
%  POLARPATTERN(A1,M1,A2,M2, ...) specifies angle vectors A1, A2, ... in
%  degrees along with real data matrices M1, M2, ...  More information
%  about data <a href="matlab:help internal.polari/formats">formats</a> is
%  available.
%
%  P = POLARPATTERN(___) returns an object that can customize the plot and
%  add measurements using MATLAB commands. Properties are found by
%  displaying variable P in the MATLAB command window. For example, P.Peaks
%  = 3 identifies and displays the 3 highest peaks in the data.
%
%  P = POLARPATTERN('gco') returns object P from the POLARPATTERN plot in
%  the current figure.  This is useful if P was not retained when a plot
%  was created.
%
%  Additional data can be added to the plot using add(P,...) using any
%  input format shown above.  Data can be replaced using replace(P,...).
%
%  To animate traces in the display, use animate(P,...) which forces a
%  graphical update and preserves axes limits, labels, etc, to achieve a
%  fast display rate.  When finished animating a polar plot, call
%  animate(P,'end').
%
%  POLARPATTERN(___,'P1',V1,'P2',V2, ...) sets the properties 'P1','P2',
%  ... to values V1,V2, ... when the POLARPATTERN object is created.
%
%  POLARPATTERN(H,___) where H is an axes handle is supported.
%  POLARPATTERN also supports the syntax of POLAR.
%
%  Many properties of P can be changed interactively within the plot.
%  Functions specific to POLARPATTERN may be discovered using methods(P),
%  and are intended for automating setup of the display and measurements.
%
%  See also <a href="matlab:help internal.polari.formats">formats</a>, <a href="matlab:help internal.polari.multiaxes">multiaxes</a>, <a href="matlab:help internal.polari.TitleTop">TitleTop</a>,
%  <a href="matlab:help internal.polari.LegendLabels">LegendLabels</a>, <a href="matlab:help internal.polari.Peaks">Peaks</a>, <a href="matlab:help internal.polari.add">add</a>, <a href="matlab:help internal.polari.replace">replace</a>, <a href="matlab:help internal.polari.animate">animate</a>.

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end
    
if nargin==1 && strcmpi(varargin{1},'gco')
    % Find instance in current figure
    p = internal.polari.getCurrentPlot;
else
    % Create a new instance
    p = internal.polari(varargin{:});
end

% c = internal.BannerMessage(p.hFigure);
% c.RemainFor = 10;
% c.Location  = 'top';
% c.String    = 'Right click in the figure window to interact with the plot';
% start(c);
% 
% c.RemainFor = 5;
% c.Location  = 'bottom';
if nargout ~= 0
    varargout{1} = p;
end