function result = canContainNovelComponents(fig)
% CANCONTAINNOVELCOMPONENTS Returns whether the given Figure can host the new app building
% component set (i.e. components created by functions like uibutton, uigridlayout).

% Copyright 2021 The MathWorks, Inc.

    if ~isa(fig,"matlab.ui.Figure")
        error("MATLAB:internal:canContainNovelComponents:InvalidFigureHandle","Invalid figure handle.");
    end

    if ishandle(fig)
        result = isempty(fig.JavaFrame_I) && ~isWebFigureType(fig,'EmbeddedMorphableFigure');
    else
        result = false;
    end

end
