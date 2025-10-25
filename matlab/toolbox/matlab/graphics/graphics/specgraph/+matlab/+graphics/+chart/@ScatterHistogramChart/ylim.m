function yl = ylim(sh,limits)
% YLIM Set or query x-axis limits
%   YLIM(SH, limits) specifies the y-axis limits on the scatterhistogram
%   SH. Specify limits as a two-element vector of the form [ymin ymax]
%   
%   yl = YLIM(SH) returns a two-element vector containing the y-axis limits
%   for the the scatterhistogram SH.
%   
%   YLIM(SH, 'auto') resets the y-axis limits on the scatterhistogram SH to
%   the full range of the values in the 'YData' vector.
%   
%   YLIM(SH, 'manual') freezes the y-axis limits on the scatterhistogram SH
%   at the current values.
%   
%   m = YLIM(SH, 'mode') returns the current value of the y-axis limits
%   mode on the scatterhistogram SH, which is either 'auto' or 'manual'. By
%   default, the mode is automatic unless you specify limits or set the
%   mode to manual.

%   Copyright 2018 The MathWorks, Inc.

markFigure = false;
if nargin < 2
    % If no additional inputs were provided, return the current value of
    % the YLimits property.
    yl = get(sh, 'YLimits');
elseif (ischar(limits) || (isstring(limits) && isscalar(limits))) && ...
        ismember(lower(limits), {'auto','manual','mode'})
    if strcmpi(limits,'mode')
        % Query YLimitsMode
        yl = get(sh, 'YLimitsMode');
    elseif nargout > 0
        % No output arguments are returned when you set the XLimits.
        error(message('MATLAB:nargoutchk:tooManyOutputs'));
    else
        % Set the YLimitsMode to either auto or manual.
        set(sh, 'YLimitsMode', lower(limits));
        markFigure = true;
    end
elseif nargout > 0
    % No output arguments are returned when you set the YLimits.
    error(message('MATLAB:nargoutchk:tooManyOutputs'));
else
    % Set the YLimits to the specified value.
    set(sh, 'YLimits', limits);
    markFigure = true;
end

% This command notifies the Live Editor of potential changes to the figure.
if markFigure
    matlab.graphics.internal.markFigure(sh);
end

end