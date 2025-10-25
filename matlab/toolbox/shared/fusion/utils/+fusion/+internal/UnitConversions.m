classdef (Hidden) UnitConversions
%UNITCONVERSIONS Internal class used for unit conversions. 
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2017-2024 The MathWorks, Inc.

%#codegen
    
    methods (Static)
        % g's to m/s^2
        function y = geeToMetersPerSecondSquared(x)
            dtype = class(x);
            y = x .* cast(fusion.internal.ConstantValue.Gravity, dtype);
        end
        % % m/s^2 to g's
        % function y = metersPerSecondSquaredToGee(x)
        %     dtype = class(x);
        %     y = x ./ cast(fusion.internal.ConstantValue.Gravity, dtype);
        % end
        % G to uT
        function y = gaussToMicroteslas(x) 
            dtype = class(x);
            y = x .* cast(100, dtype);
        end
        % % uT to G
        % function y = microteslas2Gauss(x)
        %     dtype = class(x);
        %     y = x ./ cast(100, dtype);
        % end
    
        %DB2DBM Converts values from decibels to milli-decibels
        %   xdBm = fusion.internal.UnitConversions.db2dbm(xdB) converts the
        %   values in the array x from decibels to milli-decibels.
        %
        %   % Example:
        %   % Convert 100 from dB to dBm
        %   fusion.internal.UnitConversions.db2dbm(100)
        function xdBm = db2dbm(xdB)
            % Returns value in milli-decibels
            
            xdBm = xdB+30;
        end
    
        %DBM2DB Converts values from milli-decibels to decibels
        %   xdB = fusion.internal.UnitConversions.dbm2db(xdBm) converts the
        %   values in the array x from milli-decibels to decibels.
        %
        %   % Example:
        %   % Convert 100 from dBm to dB
        %   fusion.internal.UnitConversions.dbm2db(100)
        function xdB = dbm2db(xdBm)
            % Returns value in decibels
            
            xdB = xdBm-30;
        end
        
        %INTERVAL Wraps numbers to lie within the defined interval
        %   xWrapped = fusion.internal.UnitConversions.interval(x,bounds)
        %   returns the values in the array x wrapped to lie in the
        %   interval [bounds(1) bounds(2)), where bounds is a 2-element
        %   vector defining the lower and upper bounds of the interval. If
        %   bounds is a scalar, then the interval is defined as [0
        %   bounds(1)).
        %
        %   % Example 1:
        %   % Wrap the values to lie in the interval of [1 5)
        %   x = -3:6
        %   y = fusion.internal.UnitConversions.interval(x,[1 5])
        %
        %   % Example 2:
        %   % Wrap the values to lie in the interval of [0 4)
        %   x = -3:6
        %   y = fusion.internal.UnitConversions.interval(x,4)
        function x = interval(x,bounds)
            
            if isscalar(bounds)
                bounds = [0 bounds];
            end
            bounds = cast(bounds,'like',x);
            
            x = x-bounds(1);
            
            % Constrain to the interval [0 (bounds(2)-bounds(1)))
            upLim = bounds(2)-bounds(1);
            num = floor(x/upLim);
            x = x-num*upLim;
            
            % Constrain to the interval [bounds(1) bounds(2))
            x = x+bounds(1);
        end
    end
end
