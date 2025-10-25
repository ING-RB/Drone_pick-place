function s = funstring(fun)
% Yield a string representing fun.

%   Mike Karr, Jacek Kierzenka, 11-19-99
%   Copyright 1984-2021 The MathWorks, Inc.

if isa(fun, 'function_handle')
    % Char and string function inputs are converted to function handles
    % before funstring is called
    s = upper(func2str(fun));
elseif isa(fun, 'inline')
    s = formula(fun);
else
    s = 'unknown';
end
