function ret_fig = clf(varargin)
%CLF Clear current figure.
%   CLF deletes all children of the current figure with visible handles.
%
%   CLF RESET deletes all children (including ones with hidden
%   handles) and also resets all figure properties, except Position,
%   Units, PaperPosition and PaperUnits, to their default values.
%
%   CLF(FIG) or CLF(FIG,'reset') clears all figures specified by FIG.
%
%   FIG_H = CLF(...) returns the handle of the figure.
%
%   See also CLA, RESET, HOLD.

%   CLF(..., HSAVE) deletes all children except those specified in
%   HSAVE.
%
%   Copyright 1984-2023 The MathWorks, Inc.

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

narginchk(0,3);

% Look for double handles, verify that they are valid and convert them to
% regular handles. This will also accept [] and create an empty handle.
if nargin > 0 && isa(varargin{1}, "double")
    if ~all(isgraphics(varargin{1}),"all")
        error(message('MATLAB:clf:InvalidFigureHandle'));
    end
    varargin{1} = handle(varargin{1});
end

if nargin > 0 && isa(varargin{1},'matlab.ui.Figure')
    % Accept an array of figures of any size (including empty) as the target
    % figure to clear. isa is required to prevent accepting non-figures.
    if ~all(isgraphics(varargin{1}),'all') % Throw error for deleted targets
        error(message('MATLAB:clf:InvalidFigureHandle'));
    end
    fig = varargin{1};
    extra = varargin(2:end);
    if isempty(fig) % Empty array of figure handles is a no-op.
        if (nargout ~= 0)
            ret_fig = fig;
        end
        return
    end
else
    % Default target is current figure
    fig = gcf;
    extra = varargin;
end

% Parse the extra input arguments for reset and hsave
reset = [];
hsave = [];
if length(extra) == 2
    reset = extra{1};
    verifyNotFigureAndNonFigureMixedInput(extra{2});
    hsave = extra{2};
elseif isscalar(extra)
    if ~matlab.graphics.internal.isCharOrString(extra{1})
        verifyNotFigureAndNonFigureMixedInput(extra{1});
        hsave = extra{1};
    else
        reset = extra{1};
    end
end

if isnumeric(hsave) && all(isgraphics(hsave),'all')
    hsave = handle(hsave);
end

% Notify the editor that something in the figure is being deleted.
clearingSomething = true;
if ~isempty(hsave)
    hsave = reshape(hsave,[],1);
    ch = fig.Children;
    if length(ch) == length(hsave) && isequal(sort(hsave),sort(ch))
        clearingSomething = false;
    end
end
if clearingSomething
    matlab.graphics.internal.clearNotify(fig, [], 'delete');
end

% Annotations are cleared by hand since the handle is hidden
clearscribe(fig);


% If the reset option was selected, clear any active modes and any link plot
% state.
if ~isempty(reset)
    for i = 1:numel(fig)
        hfig = fig(i);
        scribeclearmode(hfig);
        if isprop(hfig,'ModeManager') && ~isempty(get(hfig,'ModeManager'))
            clearModes(get(hfig,'ModeManager'));
            set(hfig,'ModeManager','');
            uiundo(hfig,'clear');
        end
        if ~isdeployed % linkdata is not deployable
            linkDataState = linkdata(hfig);
            if strcmp(get(linkDataState,'Enable'),'on')
                linkdata(hfig,'off');
            end
        end
        % TODO: This was added because clf('reset') is not supported in web
        % graphics. Since live editor uses web graphics, if clf('reset') is
        % called, live editor triggers a morph. Once clf('reset') is supported
        % for web figures, we can remove this call to clearNotify.
        matlab.graphics.internal.clearNotify(hfig, [], 'reset');
    end
end

% Call clo on the figure
for i = 1:numel(fig)
    if ~isempty(fig(i).CurrentAxes)
        fig(i).CurrentAxes = [];
    end
    clo(fig(i), reset, hsave);
end


% Cause a complete redraw of the figure, so that movie frame remnants
% are cleared as well.
% Calling clo may have caused the figure to be deleted, so make sure the
% figure handle is valid before calling refresh.
if isgraphics(fig)
    for i = 1:numel(fig)
        refresh(fig(i))
    end
end

% Now that IntegerHandle can be changed by reset, make sure we're returning
% the new handle:
if (nargout ~= 0)
    ret_fig = fig;
end

end

function verifyNotFigureAndNonFigureMixedInput(hsave)
areFigures = isgraphics(hsave,'figure');
if any(areFigures) && ~all(areFigures)
    throwAsCaller(MException(message('MATLAB:clf:InvalidFigureHandle')));
end
end
