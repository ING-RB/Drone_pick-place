function gt = theme(varargin)
%

% Copyright 2024 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
narginchk(0,2);
[fig, args] = peelFirstArgParent(varargin);

if ~isempty(args)
    themeState = convertStringsToChars(args{1});
    mustBeNonempty(themeState)
end

if ~isempty(fig) && ~all(isgraphics(fig,'matlab.graphics.mixin.ThemeContainer'),'all')
    error(message('MATLAB:graphics:themes:InvalidFigure'))
end

propToSet = [];
if ~isempty(args)
    if (isa(themeState,'matlab.graphics.theme.GraphicsTheme') && isscalar(themeState)) || ...
            (ischar(themeState) && any(strcmpi(themeState,{'dark','light'})))
        propToSet = 'Theme';
    elseif ischar(themeState) && strcmpi(themeState,'auto')
        propToSet = 'ThemeMode';
    else
        error(message('MATLAB:graphics:themes:InvalidThemeOrThemeMode'))
    end
    if numel(args) > 1
        error(message('MATLAB:graphics:themes:OnlyOneTheme'))
    end
end

if isempty(fig)
    % Only get gcf if we've already validated the inputs to avoid creating
    % a figure in an error condition.
    fig = gcf;
end

if ~isempty(propToSet)
    % Only update the Figure's theme if we haven't hit one of the error
    % conditions.
    set(fig,propToSet,themeState);
end

if nargout > 0 || isempty(args)
    gt = get(fig,'Theme');
    if iscell(gt)
        gt = [gt{:}];
        if ~isempty(gt)
            gt = reshape(gt,size(fig));
        end
    end
end
end