function fieldName = getFieldName(msgID)
% Get label of a widget from the message catalog, remove the trailing colon
%
% This is used for error reporting in the MaskInit code of EKF, UKF, PF
% blocks.

%   Copyright 2017 The MathWorks, Inc.

fieldName = getString(message(msgID));
if endsWith(fieldName,':')
    fieldName = extractBefore(fieldName,length(fieldName));
end
end