function millis = createFromText(data,inputFormat,displayFormat,supplied)
% Convert timer text of the form [dd:]hh:mm:ss[.SSS] to durations.

%   Copyright 2018-2019 The MathWorks, Inc.

import matlab.internal.duration.getDetectionFormats
import matlab.internal.duration.getBaseFormat
import matlab.internal.duration.tryTextFormats
import matlab.internal.datatypes.throwInstead;

% Convert the data from text
if ischar(data), data = {data};end
if isempty(data)
    millis = zeros(size(data));
    return; 
end

if ~supplied.InputFormat
    [formats, numColons] = getDetectionFormats(data);
    if supplied.Format && contains(displayFormat,':')
        formats = unique([replace(displayFormat,{'.','S'},''); formats(:)],'stable');
    end
    try
        millis = tryTextFormats(data,formats);
    catch ME 
        if numColons == 1
            error(message('MATLAB:duration:DetectedTwoPart','hh:mm','mm:ss'));
        end
        throwInstead(ME,{'MATLAB:duration:AutoConvertString'}, ...
            message('MATLAB:duration:UndetectableFormat',getFirstUnrecognized(data),'hh:mm:ss', 'dd:hh:mm:ss'));
    end
else % inputFormat passed in.
    [inputFormatEff, allowFractionalSeconds] = getBaseFormat(inputFormat);
    try
        millis = tryTextFormats(data,{inputFormatEff},allowFractionalSeconds);
    catch ME
        throwInstead(ME,{'MATLAB:duration:AutoConvertString'}, ...
            message('MATLAB:duration:DataMismatchedFormat',getFirstUnrecognized(data),inputFormat));
    end
end
end

%-----------------------------------------------------------------------
function d = getFirstUnrecognized(data)
% This relies on the fact that tryTextFormats succeeds if _any_ element of data
% was recognized as a finite duration timestamp, and therefore the only way to
% get here is if the only things recognized were literal-nonfinites, but at
% least one element was not recognized. Find the first one of those.
% tryTextFormats already found it, but it's only in the MException message text.
tf = matlab.internal.datetime.isLiteralNonFinite(data,["NaN" "Inf"],true); % include ''
d =  data{find(~tf(:),1)};
d = ['''' d ''''];
end