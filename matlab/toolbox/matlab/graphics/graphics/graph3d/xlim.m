function varargout = xlim(varargin)
%XLIM Set or query x-axis limits
%   XLIM(limits) specifies the x-axis limits for the current axes. Specify
%   limits as a two-element vector of the form [xmin xmax], where xmax is a
%   numeric value greater than xmin.
%   
%   xl = XLIM returns a two-element vector containing the x-axis limits for
%   the current axes.
%   
%   XLIM(limitmethod) specifies the method used to determine the x-limits
%   for the current axes. Specify the limitmethod as 'tickaligned',
%   'tight', or 'padded'. This command sets the XLimitMethod property on
%   the axes.
% 
%   m = XLIM('method') returns the current method for setting the x-axis
%   limits, which can be 'tickaligned', 'tight', or 'padded'. By default,
%   the method is 'tickaligned'.
%
%   XLIM(limitmode) specifies automatic or manual x-limits selection.
%   Specify the limitmode as either 'auto' or 'manual'. This command sets
%   the XLimMode property on the axes.
%
%   m = XLIM('mode') returns the current value of the x-axis limits mode,
%   which is either 'auto' or 'manual'. By default, the mode is automatic
%   unless you specify limits or set the mode to manual.
%
%   ___ = XLIM(ax, ___ ) uses the axes specified by ax instead of the
%   current axes.
%
%   XLIM sets or gets the XLim, XLimMode, or XLimitMethod property of an
%   axes.
%
%   See also PBASPECT, DASPECT, YLIM, ZLIM, THETALIM, RLIM.

%   Copyright 1984-2021 The MathWorks, Inc.

varargout = matlab.graphics.internal.ruler.rulerFunctions(mfilename, nargout, varargin);

end
