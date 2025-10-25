classdef (Hidden) BasicEKF < fusion.internal.PositioningHandleBase ...
    & positioning.internal.EKF
%BASICEKF Abstract class for EKFs
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2018-2021 The MathWorks, Inc.

%#codegen 
    properties (Abstract)
        State;
        StateCovariance;
    end
    
    properties (Abstract, Hidden, Constant)
        NumStates;
    end
    
    properties (Access=protected)
        OrientationIdx; % Cache of the Orientation indices in State
        ReferenceFrameObject = fusion.internal.frames.ReferenceFrame.getMathObject( ...
                fusion.internal.frames.ReferenceFrame.getDefault)% Cached Reference Frame object
    end

    properties (Hidden)
        ReferenceFrame = fusion.internal.frames.ReferenceFrame.getDefault;
    end

    methods
        function obj = BasicEKF(varargin)
            % Cache the OrientationIdx
            si = stateinfo(obj);
            obj.OrientationIdx = si.Orientation;
        end
    end
   
    methods (Abstract, Access = protected)
        x = getState(obj);
        setState(obj, val);
        x = getStateCovariance(obj);
        setStateCovariance(obj, val);
    end

    methods (Sealed)
        function correct(obj, idx, z, Rin)
        %CORRECT Correct states using direct state measurements
        %   CORRECT(FUSE, IDX, Z, R) corrects the state and state estimation error 
        %   covariance based on the measurement Z and covariance R. The measurement
        %   Z maps directly to the states specified by the indices IDX.
            
            validateattributes(idx, ...
                {'numeric'}, ...
                {'vector','positive','integer','<=',obj.NumStates,'increasing'}, ...
                '', ...
                'idx');
            N = numel(idx);
            validateattributes(z, ...
                {'double','single'}, ...
                {'vector','real','finite','numel',N}, ...
                '', ...
                'z');
            % Ensure it is a column vector.
            z = z(:);
            
            % Expand Rin and make sure it matches idx.
            R = obj.validateExpandNoise(Rin, N, 'R');
            
            x = getState(obj);
            P = getStateCovariance(obj); 
            
            h = x(idx);
            I = eye(obj.NumStates);
            H = I(idx,:);
            [st,  scov] = correctEqn(obj, ...
                x, P, h, H, z, R);
            setState(obj, st);
            setStateCovariance(obj, scov);
        end
        
        function [innov, innovCov] = residual(obj, idx, z, Rin)
        %RESIDUAL Residuals and residual covariance from direct state measurements
        %   [RES, RESCOV] = RESIDUAL(FUSE, IDX, Z, R) computes the
        %   residuals, RES, and residual covariance, RESCOV, based on the
        %   measurement Z and covariance R. The measurement Z maps directly
        %   to the states specified by the indices IDX.
        
            validateattributes(idx, ...
                {'numeric'}, ...
                {'vector','positive','integer','<=',obj.NumStates,'increasing'}, ...
                '', ...
                'idx');
            N = numel(idx);
            validateattributes(z, ...
                {'double','single'}, ...
                {'vector','real','finite','numel',N}, ...
                '', ...
                'z');
            % Ensure it is a column vector.
            z = z(:);
            
            % Expand Rin and make sure it matches idx.
            R = obj.validateExpandNoise(Rin, N, 'R');
            
            x = getState(obj);
            P = getStateCovariance(obj);
            
            h = x(idx);
            I = eye(obj.NumStates);
            H = I(idx,:);
            
            [innov, innovCov] = privInnov(obj, P, h, H, z, R);
        end
    end
    
    methods
        function set.ReferenceFrame(obj, val)
           obj.ReferenceFrame = validatestring(val, ...
               fusion.internal.frames.ReferenceFrame.getOptions, ...
               '', 'ReferenceFrame');
       end
    end
    
    methods (Abstract)
        sidx = stateinfo(obj);
    end

    methods (Access = protected)
        function [innov, innovCov] = privInnov(~, P, h, H, z, R)
            [innov, innovCov] ...
                = positioning.internal.EKF.equationInnovation( ...
                P, h, H, z, R);
            % Make the innovation a row vector to match the measurement 
            % shape.
            innov = innov.';
        end
        
        function [x, P, innov, innovCov] = correctEqn(obj, x, P, h, H, z, R)
            [x, P, innov, innovCov] ...
                = positioning.internal.EKF.equationCorrect( ...
                x, P, h, H, z, R);
            x = repairQuaternion(obj, x);

            % Make the innovation a row vector to match the measurement shape
            innov = reshape(innov, 1,[]);

        end

        function x = repairQuaternion(obj, x)
            % Normalize quaternion and enforce a positive angle of
            % rotation. Avoid constructing a quaternion here. Just do the
            % math inline.

            % Used cached OrientationIdx
            idx = obj.OrientationIdx;
            qparts = x(idx);
            n = sqrt(sum(qparts.^2));
            qparts = qparts./n;
            if qparts(1) < 0
                x(idx) = -qparts;
            else
                x(idx) = qparts;
            end
        end

        function P = predictCovEqn(~, P, F, U, G)
            P = positioning.internal.EKF.equationPredictCovariance( ...
                P, F, U, G);
        end
        
        function Rout = validateExpandNoise(~, Rin, num, argName, numstr)
            %VALIDATEEXPANDNOISE validate measurement noise input and expand
            %to matrix
            %   The optional numstr argument is a string (or char) of the
            %   num argument. This avoids doing a sprintf or string()
            %   conversion in the loop. Must be optional because correct()
            %   cannot know this value at design time.

            if nargin < 5
                numstr = string(num);
            end

            Rout = positioning.internal.EKF.validateAndExpandNoise( ...
                Rin, num, argName, numstr);
        end
    end
    methods (Hidden, Static)
        function props = matlabCodegenNontunableProperties(~)
            props = {'ReferenceFrame'};
        end
    end
end

