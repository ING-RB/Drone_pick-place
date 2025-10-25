function fig = observeFigureNextPlot(fig, target, targetSpecified)
% This function is undocumented and may change in a future release.

% Prepare a figure for plotting by responding to the `NextPlot` property.
% This function is guaranteed to return a figure.

%   Copyright 2023 The MathWorks, Inc.

arguments
    fig (1,1) matlab.ui.Figure
    target {mustBeScalarOrEmpty} = []
    targetSpecified (1,1) logical = isscalar(target)
end

switch fig.NextPlot
    case 'new'
        % If the caller specified a target, treat NextPlot == 'new' like
        % NextPlot == 'add' and do nothing, so that the figure returned is
        % the ancestor figure of the target.

        % Only create a new figure if the caller did not specify a target.        
        if ~targetSpecified
            fig = figure;
        end
    case 'replace'
        % Reset the figure but preserve the target object.
        clf(fig, 'reset', target);
    case 'replacechildren'
        % Clear the figure but preserve the target object.
        clf(fig, target);
    case 'add'
        % No-op
end

% It is possible that clf triggered a side-effect that deleted the figure.
% If that happens, create a new figure.
if ~isgraphics(fig) && isempty(target)
    fig = figure;
end

% Set figure's NextPlot property to 'DefaultFigureNextplot' after obeying
% the previous setting.
if isgraphics(fig)
    fig.NextPlot = get(groot, 'DefaultFigureNextplot');
end

end
