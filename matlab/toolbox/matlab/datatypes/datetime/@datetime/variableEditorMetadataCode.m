function [metadataCode,warnmsg] = variableEditorMetadataCode(this, varName, ~, propertyName, propertyString)
% This function is for internal use only and will change in a
% future release.  Do not use this function.

% Generate MATLAB command to modify datetime metadata

% Copyright 2014-2019 The MathWorks, Inc.

warnmsg = '';
if matches("Format", propertyName,"IgnoreCase",true) && (this.tz ~= datetime.UTCLeapSecsZoneID)
    metadataCode = [varName '.Format = ''' fixquote(propertyString) ''';'];
else
    metadataCode = [];
end
