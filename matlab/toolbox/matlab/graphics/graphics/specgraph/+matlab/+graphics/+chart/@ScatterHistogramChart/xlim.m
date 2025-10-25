function xl = xlim(sh,limits)
% XLIM Set or query x-axis limits
%   XLIM(SH, limits) specifies the x-axis limits on the scatterhistogram
%   SH. Specify limits as a two-element vector of the form [xmin xmax]
%   
%   xl = XLIM(SH) returns a two-element vector containing the x-axis limits
%   for the the scatterhistogram SH.
%   
%   XLIM(SH, 'auto') resets the x-axis limits on the scatterhistogram SH to
%   the full range of the values in the 'XData' vector.
%   
%   XLIM(SH, 'manual') freezes the x-axis limits on the scatterhistogram SH
%   at the current values.
%   
%   m = XLIM(SH, 'mode') returns the current value of the x-axis limits
%   mode on the scatterhistogram SH, which is either 'auto' or 'manual'. By
%   default, the mode is automatic unless you specify limits or set the
%   mode to manual.

%   Copyright 2018 The MathWorks, Inc.

markFigure = false;
if nargin < 2
    % If no additional inputs were provided, return the current value of
    % the XLimits property.
    xl = get(sh, 'XLimits');
elseif (ischar(limits) || (isstring(limits) && isscalar(limits))) && ...
        ismember(lower(limits), {'auto','manual','mode'})
    if strcmpi(limits,'mode')
        % Query XLimitsMode
        xl = get(sh, 'XLimitsMode');
    elseif nargout > 0
        % No output arguments are returned when you set the XLimits.
        error(message('MATLAB:nargoutchk:tooManyOutputs'));
    else
        % Set the XLimitsMode to either auto or manual.
        set(sh, 'XLimitsMode', lower(limits));
        markFigure = true;
    end
elseif nargout > 0
    % No output arguments are returned when you set the XLimits.
    error(message('MATLAB:nargoutchk:tooManyOutputs'));
else
    % Set the XLimits to the specified value.
    set(sh, 'XLimits', limits);
    markFigure = true;
end

% This command notifies the Live Editor of potential changes to the figure.
if markFigure
    matlab.graphics.internal.markFigure(sh);
end

end