classdef insOptions < positioning.internal.INSOptionsBase & matlab.mixin.CustomDisplay
%INSOPTIONS Options for insEKF configuration
%   O = INSOPTIONS creates a default set of options for the design of the
%   insEKF. 
%
%   O = INSOPTIONS('Prop1', 'Val1', ..., 'PropN', 'ValN') creates a set of
%   options for the design of the insEKF with option Prop1 set to Val1,
%   etc.
%
%   INSOPTIONS properties:
%   Datatype          - class of internal insEKF variables
%   SensorNamesSource - source of sensor names
%   SensorNames       - custom names for sensors being fused
%   ReferenceFrame    - NED or ENU
%
%   Example:
%   opt = insOptions('Datatype', 'single');
%
%   See also: insEKF

%   Copyright 2021 The MathWorks, Inc.    

    methods (Hidden, Static)
        function name = matlabCodegenRedirect(~)
            name = 'positioning.internal.INSOptionsBase';
        end
    end
    methods (Access = protected)
        function  p = getPropertyGroups(obj)
            if isscalar(obj)
                grp = struct( ...
                    'Datatype', obj.Datatype, ...
                    'SensorNamesSource', obj.SensorNamesSource, ...
                    'ReferenceFrame', obj.ReferenceFrame);
                if strcmpi(obj.SensorNamesSource, 'property')
                    grp.SensorNames = obj.SensorNames;
                end
                p = matlab.mixin.util.PropertyGroup(grp);
            else
                % In the vector case, just use the default.
                p = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            end
        end
    end
end



