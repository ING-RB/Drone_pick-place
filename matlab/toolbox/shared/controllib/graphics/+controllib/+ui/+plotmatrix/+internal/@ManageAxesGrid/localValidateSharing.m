function result = localValidateSharing(x)
%

%   Copyright 2015-2020 The MathWorks, Inc.

result = false;
if strcmpi(x, 'default') || strcmpi(x, 'all')
    result = true;
else
    error(message('Controllib:general:UnexpectedError', ...
        'Sharing must be set to ''default'' or ''all'''));
end
end
