function [parent, ancestorAxes, nextplot] = prepareAxes(parent, hasParent, showInteractionInfoPanel)
% This function is undocumented and may change in a future release.

%   Copyright 2021-2023 The MathWorks, Inc.

% [parent, ancestorAxes, nexplot] = prepareAxes(parent, hasParent, showInteractionInfoPanel)
%   calls newplot, updates the parent, and chooses ancestor axes as
%   appropriate.
%
%   Inputs:
%   
%   * parent is the value for parent specified by the user (which might be
%   empty). This is the output from peelFirstArgParent or getParent.
%
%   * hasParent indicates whether a parent was explicitly specified
%   (including if it was specified as empty). If hasParent is false, the
%   parent input argument is ignored. The second output from getParent can
%   be used as the hasParent input for prepareAxes.
%
%   * showInteractionInfoPanel indicates whether to show the interaction
%   info panel. If showInteractionInfoPanel is true the interaction info
%   panel maybeShow() method will be called if hasParent is false and there
%   is no current figure.
%
%   There are three pathways that might be taken by prepareAxes:
%
%   * If parent implements the CurrentAxes mixin: parent is the output from
%   newplot(parent).
%
%   * If parent is not specified (i.e. hasParent is false): parent is the
%   output from newplot with no input arguments.
%
%   * If parent is specified and does not implement the CurrentAxes mixin
%   (e.g. hggroup or hgtransform) or if it is explicitly specified as empty
%   (e.g. gobjects(0)): parent is not modified and newplot is not called.
%
%   In all cases:
%
%   * ancestorAxes is the nearest AbstractAxes ancestor of the resulting
%   parent. Note that the ancestorAxes might be empty if no axes is found.
%
%   * If the resulting parent is an axes, nextplot is set to the value of
%   NextPlot on the parent.
%
%   * Note that the resulting parent is not guaranteed to be a Cartesian
%   axes. For example, if the user explicitly specifies a Figure, hggroup,
%   polaraxes, or chart (such as a HeatmapChart), the output parent might
%   not be a Cartesian axes.

arguments
    parent
    hasParent logical
    showInteractionInfoPanel logical = false
end

if hasParent
    if isscalar(parent) && isa(parent, 'matlab.graphics.mixin.CurrentAxes')
        parent = newplot(parent);
    elseif numel(parent) >= 2
        err = MException(message('MATLAB:graphics:axescheck:NonScalarHandle'));
        throwAsCaller(err);
    end
else
    showInteractionInfoPanel = showInteractionInfoPanel && isempty(get(groot, 'CurrentFigure'));
    parent = newplot;
    
    if showInteractionInfoPanel
        matlab.graphics.internal.InteractionInfoPanel.maybeShow(parent);
    end
end

% Find the nearest axes ancestor of the parent.
ancestorAxes = ancestor(parent, 'matlab.graphics.axis.AbstractAxes');

% ancestor will return empty double for empty input or if no
% ancestor is found. Replace it with gobjects(0) instead.
if isempty(ancestorAxes)
    ancestorAxes = gobjects(0);
end

nextplot = '';
if isscalar(parent) && isa(parent, 'matlab.graphics.axis.AbstractAxes')
    nextplot = parent.NextPlot;
end
