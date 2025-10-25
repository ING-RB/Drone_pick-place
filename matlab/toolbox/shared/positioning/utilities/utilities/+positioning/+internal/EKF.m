classdef (Hidden, HandleCompatible) EKF
%EKF Unified internal helper class for EKF equations.
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2021 The MathWorks, Inc.

%#codegen 

    methods (Static, Access = protected)
        function [innov, innovCov] = equationInnovation(P, h, H, z, R)
            innovCov = H*P*(H.') + R;
            innov = (z(:) - h(:));
        end
        
        function [x, P, innov, innovCov] = equationCorrect(x, P, h, H, z, R)
            [innov, innovCov] = positioning.internal.EKF.equationInnovation(P, h, H, z, R);
            
            W = P*(H.') / innovCov;
            x = x + W*(innov);
            P = P - W*H*P;
        end

        function P = equationPredictCovariance(P, F, U, G)
            Q = G*U*(G.');
            P = F*P*(F.') + Q;
        end

        function Rout = validateAndExpandNoise(Rin, num, argName, numstr)
            %VALIDATEANDEXPANDNOISE validate measurement noise input and expand
            %to matrix
            %   The optional numstr argument is a string (or char) of the
            %   num argument. This avoids doing a sprintf or string()
            %   conversion in the loop. Must be optional because correct()
            %   cannot know this value at design time.

            if nargin < 4
                numstr = string(num);
            end

            validateattributes(Rin, {'double', 'single'}, ...
                {'2d', 'nonempty', 'real'}, '', argName);

            sz = size(Rin);
            coder.internal.assert(isscalar(Rin) || ...
                isequal(sz, [num 1]) || isequal(sz, [1 num]) || ...
                isequal(size(Rin), [num num]), ...
                'shared_positioning:insfilter:MeasurementNoiseSize',  ...
                argName, numstr);
            
            % Figure out Rout with an if-elseif-else statement, not a
            % switch statement, otherwise codegen throws a warning if
            % num==1 and we have redundant branches.
            Nrin = numel(Rin);
            if Nrin == 1
               Rout = diag( repmat(Rin,1,num) );
            elseif Nrin == num
                Rout = diag(Rin);
            else
                Rout = Rin;
            end
        end
    end
end
