function c = times(a,b)
%

%   Copyright 2014-2024 The MathWorks, Inc.

try
    [c,scale,right] = parseMultiplicationInputs(a,b);
    
    % Apply multiplication
    c_components = c.components;
    [c_components.months,isPlaceholderMonths] = applyScale(c_components.months,scale,right);
    [c_components.days,isPlaceholderDays]   = applyScale(c_components.days,scale,right);
    [c_components.millis,isPlaceholderMillis] = applyScale(c_components.millis,scale,right);
    
    % A scalar zero has components that all look like placeholders, but at least
    % one has to be treated as an actual zero.
    if (isPlaceholderMonths && isPlaceholderDays && isPlaceholderMillis)
        c_components.days = scale .* 0; % ~isfinite(scale); % set to zero, or to non-finite scale
    end
    
    c.components = c_components;

catch ME
    throw(ME);
end


function [result,isPlaceholder] = applyScale(component,scale,right)
% Switch between applying left and right multiplication
isPlaceholder = isequal(component,0);
if isPlaceholder
    % Preserve a scalar zero placeholder where present.
    result = 0;
elseif right
    result = component .* scale;
else
    result = scale .* component;
end
