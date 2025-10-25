function currFormat = variableEditorMetadata(this)
% This function is for internal use only and will change in a
% future release.  Do not use this function.

% Retrieves the datetime metadata needed for the variable editor.

% Copyright 2014-2019 The MathWorks, Inc.

if this.tz == datetime.UTCLeapSecsZoneID
    currFormat = '';
else
    currFormat = getDisplayFormat(this);
end
end


