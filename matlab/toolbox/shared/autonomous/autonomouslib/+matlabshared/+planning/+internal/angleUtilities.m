%angleUtilities
%   Class containing static utility methods for dealing with angles.

% Copyright 2017-2018 The MathWorks, Inc.


%#codegen

classdef angleUtilities
    
    methods (Static)
        %------------------------------------------------------------------
        function theta = wrapTo2Pi(theta)
            %wrapTo2Pi wrap an angle in radians to the range [0,2pi].
            %	thetaout = wrapTo2Pi(thetain) wraps angles in thetain, in
            %	radians, to the interval [0 2*pi] such that zero maps to
            %	zero and 2*pi maps to 2*pi. (In general, positive multiples
            %	of 2*pi map to 2*pi and negative multiples of 2*pi map to
            %	zero.)
            
            % Cast 2*pi to input type
            twoPi = cast(2*pi, 'like', theta);
            
            positiveInput = theta > 0;
            
            % Wrap to 2pi
            theta = mod(theta, twoPi);
            
            % Not using logic indexing to avoid variable-size signal
            % support requirement in Simulink code generation for ERT
            positiveInput = (theta == 0) & positiveInput;
            theta = theta + twoPi*positiveInput; 
        end
        
        %------------------------------------------------------------------
        function theta = wrapToPi(theta)
            %wrapToPi wrap an angle in radians to the range [-pi,pi].
            %   thetaout = wrapToPi(thetain) wraps angles in thetain to the
            %   interval [-pi,pi]. Positive, odd multiples of pi are mapped
            %   to pi and negative, odd multiples of pi are mapped to -pi.
            
            % Cast pi to input type
            piVal = cast(pi, 'like', theta);
            
            theta = matlabshared.planning.internal.angleUtilities.wrapTo2Pi(theta+piVal) - piVal;
        end
        
        %------------------------------------------------------------------
        function delta = angdiff(x,y)
            %angdiff Calculate difference between two angles
            %   delta = angdiff(x,y) returns the angular difference delta =
            %   y-x. x and y must be numeric arrays of the same size
            %   representing angles in radians.
            %
            %   This function ensures that delta is in the range [-pi,pi).
            
            delta = matlabshared.planning.internal.angleUtilities.wrapToPi(y - x);
        end
        
        %------------------------------------------------------------------
        function theta = convertAndWrapTo2Pi(theta)
            %convertAndWrapTo2Pi convert to radians and wrap in [0,2pi].
            
            theta = matlabshared.planning.internal.angleUtilities.wrapTo2Pi( (pi/180) * theta );
        end
        
        %------------------------------------------------------------------
        function theta = convertAndWrapToPi(theta)
            %convertAndWrapToPi convert to radians and wrap in [-pi,pi].
            
            theta = matlabshared.planning.internal.angleUtilities.wrapToPi( (pi/180) * theta );
        end
    end
end
