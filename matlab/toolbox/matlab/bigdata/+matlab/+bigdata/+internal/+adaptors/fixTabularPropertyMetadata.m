function tX = fixTabularPropertyMetadata(tX, adaptor)
%fixTabularPropertyMetadata fixes tabular property metadata for join type operations.
%   TX = FIXTABULARPROPERTYMETADATA(TX, ADAPTOR) copies all tabular
%   properties from ADAPTOR to the tall table/timetable TX making sure that
%   all row/time-related properties are taken from TX instead.

%   Copyright 2020-2023 The MathWorks, Inc.

sample = buildSample(adaptor, 'double');
newProperties = sample.Properties;
if istimetable(tX)
   newProperties.RowTimes = tX.Properties.RowTimes;
   newProperties.StartTime = tX.Properties.StartTime;
   newProperties.SampleRate = tX.Properties.SampleRate;
   newProperties.TimeStep = tX.Properties.TimeStep;
else
   newProperties.RowNames = tX.Properties.RowNames;
end
% Keep VariableTypes information from TX
newProperties.VariableTypes = tX.Properties.VariableTypes;
tX.Properties = newProperties;