function varargout = zlim(varargin)
%ZLIM Set or query z-axis limits
%   ZLIM(limits) specifies the z-axis limits for the current axes. Specify
%   limits as a two-element vector of the form [zmin zmax], where zmax is a
%   numeric value greater than zmin.
%   
%   zl = ZLIM returns a two-element vector containing the z-axis limits for
%   the current axes.
%   
%   ZLIM(limitmethod) specifies the method used to determine the z-limits
%   for the current axes. Specify the limitmethod as 'tickaligned',
%   'tight', or 'padded'. This command sets the ZLimitMethod property on
%   the axes.
% 
%   m = ZLIM('method') returns the current method for setting the z-axis
%   limits, which can be 'tickaligned', 'tight', or 'padded'. By default,
%   the method is 'tickaligned'.
%
%   ZLIM(limitmode) specifies automatic or manual z-limits selection.
%   Specify the limitmode as either 'auto' or 'manual'. This command sets
%   the ZLimMode property on the axes.
%
%   m = ZLIM('mode') returns the current value of the z-axis limits mode,
%   which is either 'auto' or 'manual'. By default, the mode is automatic
%   unless you specify limits or set the mode to manual.
%
%   ___ = ZLIM(ax, ___ ) uses the axes specified by ax instead of the
%   current axes.
%
%   ZLIM sets or gets the ZLim, ZLimMode, or ZLimitMethod property of an
%   axes.
%
%   See also PBASPECT, DASPECT, XLIM, YLIM, THETALIM, RLIM.

%   Copyright 1984-2021 The MathWorks, Inc.

varargout = matlab.graphics.internal.ruler.rulerFunctions(mfilename, nargout, varargin);

end
