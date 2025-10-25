function [data, info] = carlaWeatherParameters
%CarlaWeatherParameters gives an empty data for carla_msgs/CarlaWeatherParameters

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/CarlaWeatherParameters';
[data.Cloudiness, info.Cloudiness] = ros.internal.ros.messages.ros.default_type('single',1);
[data.Precipitation, info.Precipitation] = ros.internal.ros.messages.ros.default_type('single',1);
[data.PrecipitationDeposits, info.PrecipitationDeposits] = ros.internal.ros.messages.ros.default_type('single',1);
[data.WindIntensity, info.WindIntensity] = ros.internal.ros.messages.ros.default_type('single',1);
[data.FogDensity, info.FogDensity] = ros.internal.ros.messages.ros.default_type('single',1);
[data.FogDistance, info.FogDistance] = ros.internal.ros.messages.ros.default_type('single',1);
[data.Wetness, info.Wetness] = ros.internal.ros.messages.ros.default_type('single',1);
[data.SunAzimuthAngle, info.SunAzimuthAngle] = ros.internal.ros.messages.ros.default_type('single',1);
[data.SunAltitudeAngle, info.SunAltitudeAngle] = ros.internal.ros.messages.ros.default_type('single',1);
info.MessageType = 'carla_msgs/CarlaWeatherParameters';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,9);
info.MatPath{1} = 'cloudiness';
info.MatPath{2} = 'precipitation';
info.MatPath{3} = 'precipitation_deposits';
info.MatPath{4} = 'wind_intensity';
info.MatPath{5} = 'fog_density';
info.MatPath{6} = 'fog_distance';
info.MatPath{7} = 'wetness';
info.MatPath{8} = 'sun_azimuth_angle';
info.MatPath{9} = 'sun_altitude_angle';
