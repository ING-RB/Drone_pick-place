function out = plus(ta, tb)
%+   Plus.

% Copyright 2016-2022 The MathWorks, Inc.

allowTabularMaths = true;
[ta, tb] = tall.validateType(ta, tb, mfilename, ...
    {'numeric', 'logical', 'char', ...
    'duration', 'datetime', 'calendarDuration', ...
    'string', 'cellstr'}, ...
    1:2, allowTabularMaths);

[outAdaptor, ta, tb] = iDetermineOutputAdaptor(ta, tb);
out = elementfun(@plus, ta, tb);
out.Adaptor = copySizeInformation(outAdaptor, out.Adaptor);
end


function [outAdaptor, ta, tb] = iDetermineOutputAdaptor(ta, tb)
% Helper to work out the output adaptor given the inputs. Note that in some
% cases the inputs may need to be cast ahead of the operation so are
% returned.
ca = tall.getClass(ta);
cb = tall.getClass(tb);

import matlab.bigdata.internal.adaptors.DatetimeFamilyAdaptor;
import matlab.bigdata.internal.adaptors.GenericAdaptor;
import matlab.bigdata.internal.adaptors.StringAdaptor;

% If either is tabular then we apply the operation to the variables.
% Else, if either is datetime, then output is datetime (unless both are datetime)
% Else, if either is calendarDuration, output is calendarDuration
% Else, if either is duration, output is duration
% Else, output unknown
if istabular(ta) || istabular(tb)
    [outAdaptor, ta, tb] = determineAdaptorForTabularMath(@iDetermineOutputAdaptor, mfilename, ta, tb);
elseif any(strcmp({ca, cb}, 'datetime'))
    if all(strcmp({ca, cb}, 'datetime'))
        error(message('MATLAB:datetime:DatetimeAdditionNotDefined'));
    end
    outAdaptor = DatetimeFamilyAdaptor('datetime');
elseif any(strcmp({ca, cb}, 'calendarDuration'))
    outAdaptor = DatetimeFamilyAdaptor('calendarDuration');
elseif any(strcmp({ca, cb}, 'duration'))
    outAdaptor = DatetimeFamilyAdaptor('duration');
elseif any(strcmp({ca, cb}, 'string'))
    % PLUS on strings is special in that chars get converted to strings,
    % thus changing their size. Output is guaranteed to be string.
    outAdaptor = StringAdaptor();
    % Convert any non-string input to string to ensure the resulting
    % operation is still elementwise.
    if ~strcmp(ca,'string')
        ta = string(ta);
    end
    if ~strcmp(cb,'string')
        tb = string(tb);
    end
else
    cc = calculateArithmeticOutputType(ca, cb);
    outAdaptor = matlab.bigdata.internal.adaptors.getAdaptorForType(cc);
end
end
