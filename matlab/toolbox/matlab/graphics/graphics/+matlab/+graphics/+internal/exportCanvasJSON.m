function exportCanvasJSON(target, file)
%

%   Copyright 2024 The MathWorks, Inc.

arguments
    target (1,1) matlab.ui.internal.mixin.CanvasHostMixin
    file (1,1) string
end

can = target.getCanvas;
assert(isa(can,'matlab.graphics.primitive.canvas.HTMLCanvas'))

cleanupGuard = matlab.graphics.internal.exportCanvasJSONScopeGuard;

deferToIdleState = feature('DeferInteractionsToMatlabIdle');
cleanupGuard.addCallback(@()feature('DeferInteractionsToMatlabIdle', deferToIdleState))
feature('DeferInteractionsToMatlabIdle', false)

allAxes = findobjinternal(can,'-isa','matlab.graphics.axis.AbstractAxes');
needsUpdate = false;
for i = 1:numel(allAxes)
    ax=allAxes(i);

    % Disable AxesToolbar for this Axes
    oldVis = ax.Toolbar.Visible;
    oldVisMode = ax.Toolbar.VisibleMode;
    if oldVis
        ax.Toolbar.Visible = 'off';
        cleanupGuard.addCallback(@()set( ...
            ax.Toolbar, Visible=oldVis, VisibleMode=oldVisMode))
    end

    % Disable Datatips for this Axes
    oldDt = ax.InteractionOptions.DatatipsSupported;
    oldDtMode = ax.InteractionOptions.DatatipsSupportedMode;
    if oldDt
        setInteractionOptions(ax, DatatipsSupported = false)
        needsUpdate = true;
        cleanupGuard.addCallback(@()setInteractionOptions( ...
            ax, DatatipsSupported=oldDt, DatatipsSupportedMode=oldDtMode))
    end

    allLines = findobjinternal(ax, '-isa', 'matlab.graphics.primitive.Line', ...
        '-or', '-isa', 'matlab.graphics.chart.primitive.Line');
    for ii = 1:numel(allLines)
        oldDetail = allLines(ii).EdgeDetailLimit;
        oldDetailMode = allLines(ii).EdgeDetailLimitMode;
        set(allLines(ii), EdgeDetailLimit = inf)
        cleanupGuard.addCallback(@()set(allLines(ii), ...
            EdgeDetailLimit = oldDetail, ...
            EdgeDetailLimitMode = oldDetailMode))
    end
    
end

if needsUpdate
    matlab.graphics.internal.drawnow.startUpdate
end

matlab.graphics.internal.writeCanvasCommandsToDisk(can, file)
end

function setInteractionOptions(ax,varargin)
nargs = nargin - 1;
for i = 1:2:nargs
    ax.InteractionOptions.(varargin{i}) = varargin{i+1};
end
end
