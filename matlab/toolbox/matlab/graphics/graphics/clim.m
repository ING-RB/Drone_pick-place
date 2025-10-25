function varargout = clim(varargin)
%CLIM Set or query color limits
%   CLIM(limits) specifies the color limits for the current axes. Specify
%   limits as a two-element vector of the form [cmin cmax], where cmax is a
%   numeric value greater than cmin.
%
%   cl = CLIM returns a two-element vector containing the color limits for
%   the current axes.
%   
%   CLIM('auto') lets the axes choose the color limits. This command sets
%   the CLimMode property for the axes to 'auto'.
%
%   CLIM('manual') freezes the color limits at the current values.This 
%   command sets the XLimMode property for the axes to 'manual'.
% 
%   m = CLIM('mode') returns the current value of the color limits mode,
%   which is either 'auto' or 'manual'. By default, the mode is automatic
%   unless you specify limits or set the mode to manual.
%
%   ___ = CLIM(ax, ___ ) uses the axes specified by ax instead of the
%   current axes.
% 
%   CLIM sets or gets the CLim or CLimMode property of an axes.
%
%   See also COLORBAR, AXIS, YLIM, ZLIM, THETALIM, RLIM.

%   Copyright 2021-2023 The MathWorks, Inc.
nargoutchk(0,2);
reqArgsOut = nargout > 0;
out = matlab.graphics.internal.ruler.rulerFunctions(mfilename, reqArgsOut, varargin);
if nargout == 2
    varargout{1} = out{:}(1);
    varargout{2} = out{:}(2);
else
    varargout = out;
end