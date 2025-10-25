function announceKeyboardInteractionResult(fig)
%

%   Copyright 2021 The MathWorks, Inc.

% This function sends a message to the screen-reader to announce the
% changed properties of an axes (either view or limits) at the end of a
% keyboard interaction. 

old_state = getappdata(fig, 'AxesStateBeforeKeyPress');

% If the appdata doesn't exist, nothing to do, so return
if(isempty(old_state))
    return;
end

ax = old_state.Axes;
old_xlim = old_state.XLim;
old_ylim = old_state.YLim;
old_zlim = old_state.ZLim;
old_view = old_state.View;

str = '';

if(~isequal(ax.View, old_view))
    % If the view property has changed, announce the new view.
    strview = strjoin({'The new axes view is : ', num2str(ax.View)});
    str = strjoin({str, strview});
else
    % If the limits have changed, gather all the dimensions for which the
    % limits have changed, and announce them together.
    if(~isequal(ax.XLim, old_xlim))
        strx = strjoin({'The new x limits are : ', num2str(ax.XLim)});
        str = strjoin({str, strx});
    end
    
    if(~isequal(ax.YLim, old_ylim))
        stry = strjoin({'The new y limits are : ', num2str(ax.YLim)});
        str = strjoin({str, stry});
    end
    
    if(~isequal(ax.ZLim, old_zlim))
        strz = strjoin({'The new z limits are : ', num2str(ax.ZLim)});
        str = strjoin({str, strz});
    end

end

if(isempty(str))
    return;
end

fsrm = matlab.graphics.internal.AriaFigureScreenReaderManager;
fsrm.updateFigureAriaLiveTextContent(fig, str);

end
