function varargout = ylim(varargin)
%YLIM Set or query y-axis limits
%   YLIM(limits) specifies the y-axis limits for the current axes. Specify
%   limits as a two-element vector of the form [ymin ymax], where ymax is a
%   numeric value greater than ymin.
%   
%   yl = YLIM returns a two-element vector containing the y-axis limits for
%   the current axes.
%   
%   YLIM(limitmethod) specifies the method used to determine the y-limits
%   for the current axes. Specify the limitmethod as 'tickaligned',
%   'tight', or 'padded'. This command sets the YLimitMethod property on
%   the axes.
%
%   m = YLIM('method') returns the current method for setting the y-axis
%   limits, which can be 'tickaligned', 'tight', or 'padded'. By default,
%   the method is 'tickaligned'.
% 
%   YLIM(limitmode) specifies automatic or manual y-limits selection.
%   Specify the limitmode as either 'auto' or 'manual'. This command sets
%   the YLimMode property on the axes.
%
%   m = YLIM('mode') returns the current value of the y-axis limits mode,
%   which is either 'auto' or 'manual'. By default, the mode is automatic
%   unless you specify limits or set the mode to manual.
%
%   ___ = YLIM(ax, ___ ) uses the axes specified by ax instead of the
%   current axes.
%
%   YLIM sets or gets the YLim, YLimMode, or YLimitMethod property of an
%   axes.
%
%   See also PBASPECT, DASPECT, XLIM, ZLIM, THETALIM, RLIM.

%   Copyright 1984-2021 The MathWorks, Inc.

varargout = matlab.graphics.internal.ruler.rulerFunctions(mfilename, nargout, varargin);

end
