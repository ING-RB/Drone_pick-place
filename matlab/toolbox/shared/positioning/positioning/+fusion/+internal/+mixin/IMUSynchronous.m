classdef IMUSynchronous < handle
%IMUSYNCHRONOUS Mixin for IMUSampleRate
%   This class is for internal use only. It may be removed in the future. 

%   Copyright 2020 The MathWorks, Inc.    

%#codegen   

    properties
        % IMUSampleRate IMU sampling rate (Hz)
        % Specify the sampling frequency of the IMU as a positive scalar.
        % The default value is 100.
        IMUSampleRate = 100;
    end

    methods
        function set.IMUSampleRate(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','scalar','positive','finite'}, ...
                '', ...
                'IMUSampleRate');
            obj.IMUSampleRate = val;
        end
    end

    methods (Access = protected)
        function s = saveObject(obj, s)
            % Add to existing struct s
            s.IMUSampleRate = obj.IMUSampleRate;
        end
        
        function loadObject(obj, s)
            obj.IMUSampleRate = s.IMUSampleRate;
        end
    end
end
