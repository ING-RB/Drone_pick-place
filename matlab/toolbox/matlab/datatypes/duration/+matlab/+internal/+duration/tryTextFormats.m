function millis = tryTextFormats(data,formats,allowFractionalSeconds)
% Convert using the first format which succeeds for any of the data.

% Copyright 2017-2019 MathWorks, Inc.

import matlab.internal.duration.createFromString
import matlab.internal.datetime.isLiteralNonFinite

if ischar(data), data = {data};end
if nargin < 3 
    allowFractionalSeconds = true;
end

for i = 1:numel(formats)
    millis = createFromString(data,formats{i},allowFractionalSeconds);
    if any(isfinite(millis),'all')
        % Something finite was recognized. Call that a success.
        millis = reshape(millis,size(data));
        return
    else
        % Nothing finite was recognized. What about literal 'Inf', 'NaN', or ''?
        tf = isLiteralNonFinite(data,["NaN" "Inf"],true); % include ''
        if all(tf,'all')
            % All elements were literal non-finite. Call that a success.
            millis = reshape(millis,size(data));
            return
        end
        % Nothing finite was recognized, and something else was not recognized
        % at all, move on to try the next format.
    end
end
error(message('MATLAB:duration:AutoConvertString',data{find(~tf(:),1)}));
end
