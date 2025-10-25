function varargout = caxis(varargin)
%CAXIS Set or query color limits
%
%   CAXIS is not recommended. Use CLIM instead.
%
%   CAXIS(limits) specifies the color limits for the current axes. Specify
%   limits as a two-element vector of the form [cmin cmax], where cmax is a
%   numeric value greater than cmin.
%
%   cl = CAXIS returns a two-element vector containing the color limits for
%   the current axes.
%   
%   CAXIS('auto') lets the axes choose the color limits. This command sets
%   the CLimMode property for the axes to 'auto'.
%
%   CAXIS('manual') freezes the color limits at the current values.This 
%   command sets the XLimMode property for the axes to 'manual'.
% 
%   m = CAXIS('mode') returns the current value of the color limits mode,
%   which is either 'auto' or 'manual'. By default, the mode is automatic
%   unless you specify limits or set the mode to manual.
%
%   ___ = CAXIS(ax, ___ ) uses the axes specified by ax instead of the
%   current axes.
% 
%   CAXIS sets or gets the CLim or CLimMode property of an axes.

%   Copyright 1984-2021 The MathWorks, Inc.

try
    [varargout{1:nargout}] = clim(varargin{:});
catch me
    throw(me)
end
