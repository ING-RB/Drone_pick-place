function groups = getPropertyGroups(obj)
%GETPROPERTYGROUPS Property group lists for gnssMeasurementGenerator

%   Copyright 2022 The MathWorks, Inc.

list.SampleRate = obj.SampleRate;
list.InitialTime = obj.InitialTime;
list.ReferenceLocation = obj.ReferenceLocation;
list.MaskAngle = obj.MaskAngle;
list.RangeAccuracy = obj.RangeAccuracy;
list.RandomStream = obj.RandomStream;
if ~isInactiveProperty(obj, 'Seed')
    list.Seed = obj.Seed;
end
groups = matlab.mixin.util.PropertyGroup(list);
end
