classdef (Hidden) BasicESKF < fusion.internal.PositioningHandleBase 
%BASICESKF Abstract class for ESKFs fusing IMU data
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen 
    properties (Abstract)
        State;
        StateCovariance;
    end
    
    properties (Abstract, Hidden, Constant)
        NumStates;
        NumErrorStates;
    end

    properties (Access=protected)
        OrientationIdx; % Cache of the Orientation indices in State
        ReferenceFrameObject = fusion.internal.frames.ReferenceFrame.getMathObject( ...
                fusion.internal.frames.ReferenceFrame.getDefault)% Cached Reference Frame object
    end
    
    properties (Hidden)
        ReferenceFrame = fusion.internal.frames.ReferenceFrame.getDefault;
    end
    
    methods (Abstract, Access = protected)
        injectError(obj, errorState)
        resetError(obj)
    end
    
    methods (Sealed)
        
        function [innov, innovCov] = residual(obj, idx, z, Rin)
        %RESIDUAL Residuals and residual covariance from direct state measurements
        %   [RES, RESCOV] = RESIDUAL(FUSE, IDX, Z, R) computes the
        %   residuals, RES, and residual covariance< RESCOV, based on the
        %   measurement Z and covariance R. The measurement Z maps directly
        %   to the states specified by the indices IDX.
        
            validateattributes(idx, ...
                {'numeric'}, ...
                {'vector','positive','integer','<=',obj.NumStates,'increasing'}, ...
                '', ...
                'idx');
            N = uint32(numel(idx));
            validateattributes(z, ...
                {'double','single'}, ...
                {'vector','real','finite','numel',N}, ...
                '', ...
                'z');
            % Ensure it is a column vector.
            z = z(:);
            idx = idx(:);
            
            x = obj.State;
            if all(idx(:) > 4)
                h = x(idx);
                zminush = z - h;
                errIdx = idx - 1;
            else
                coder.internal.assert(N >= 4 && all(idx(1:4) == (1:4).'), ...
                    'shared_positioning:insfilter:InvalidStateCorrection');
                % Convert subtract quaternion measurement using
                % multiplication and store the delta angle.
                zminush = zeros(N-1,1, 'like', z);
                zQ = quaternion(z(1:4).');
                hQ = quaternion(x(1:4).');
                deltaAng = rotvec( zQ * conj(hQ) ).';
                zminush(1:3) = deltaAng;
                
                % Adjust error state index.
                errIdx = zeros(N-1,1, 'like', z);
                errIdx(1:3) = (1:3).';
                
                % Subtract the remaining measurements, if any.
                if (N > 4)
                    zminush(4:end) = z(5:end) - x(idx(5:end));
                    errIdx(4:end) = idx(5:end) - 1;
                end
                N = N-1;
            end

            
            % Expand Rin and make sure it matches the number of element in 
            % the measurement.
            R = obj.validateExpandNoise(Rin, N, 'R');
            
            I = eye(obj.NumErrorStates);
            H = I(errIdx,:);
            
            [innov, innovCov] = privInnov(obj, obj.StateCovariance, zminush, H, R);
        end
        
        function correct(obj, idx, z, Rin)
        %CORRECT Correct states using direct state measurements
        %   CORRECT(FUSE, IDX, Z, R) corrects the state and state estimation error 
        %   covariance based on the measurement Z and covariance R. The measurement
        %   Z maps directly to the states specified by the indices IDX.
            
            [zminush, errIdx, numMeas] = getInnovsFromIndices(obj, idx, z);
            
            % Expand Rin and make sure it matches the number of element in 
            % the measurement.
            R = obj.validateExpandNoise(Rin, numMeas, 'R');
            
            I = eye(obj.NumErrorStates);
            H = I(errIdx,:);
            correctEqn(obj, zminush, H, R);
        end
    end
    
    methods
        function set.ReferenceFrame(obj, val)
           obj.ReferenceFrame = validatestring(val, ...
               fusion.internal.frames.ReferenceFrame.getOptions, ...
               '', 'ReferenceFrame');
       end
    end
    
    methods (Access = protected)
        function [innov, innovCov] = privInnov(~, P, zminush, H, R)
            innov = reshape(zminush, 1, []);
            innovCov = H*P*(H.') + R;
        end
        
        function [zminush, errIdx, numMeas] = getInnovsFromIndices(obj, idx, z)
        %GETINNOVSFROMINDICES Get error innovations from state indices and
        %   measurement
        %
        %   The inputs are: 
        %       IDX    - State indices
        %       Z      - Measurement
        %
        %   The outputs are:
        %       ZMINUSH    - Innovations/residuals
        %       ERRIDX     - Error state indices
        %       NUMMEAS    - Number of measurements corresponding to error
        %                    states
        %
        %   Since the 4 quaternions parts in the filter state correspond to
        %   3 delta angles in the filter error state, the output NUMMEAS
        %   may be less than the number of elements in the input Z. For the
        %   same reason, the output ERRIDX may not equal the input IDX.
        
            validateattributes(idx, ...
                {'numeric'}, ...
                {'vector','positive','integer','<=',obj.NumStates,'increasing'}, ...
                '', ...
                'idx');
            numMeas = uint32(numel(idx));
            validateattributes(z, ...
                {'double','single'}, ...
                {'vector','real','finite','numel',numMeas}, ...
                '', ...
                'z');
            % Ensure it is a column vector.
            z = z(:);
            idx = idx(:);
            
            x = obj.State;
            if all(idx(:) > 4)
                h = x(idx);
                zminush = z - h;
                errIdx = idx - 1;
            else
                coder.internal.assert(numMeas >= 4 && all(idx(1:4) == (1:4).'), ...
                    'shared_positioning:insfilter:InvalidStateCorrection');
                % Convert subtract quaternion measurement using
                % multiplication and store the delta angle.
                zminush = zeros(numMeas-1,1, 'like', z);
                zQ = quaternion(z(1:4).');
                hQ = quaternion(x(1:4).');
                deltaAng = rotvec( zQ * conj(hQ) ).';
                zminush(1:3) = deltaAng;
                
                % Adjust error state index.
                errIdx = zeros(numMeas-1,1, 'like', z);
                errIdx(1:3) = (1:3).';
                
                % Subtract the remaining measurements, if any.
                if (numMeas > 4)
                    zminush(4:end) = z(5:end) - x(idx(5:end));
                    errIdx(4:end) = idx(5:end) - 1;
                end
                numMeas = numMeas-1;
            end
        end
        
        function [innov, iCov] = correctEqn(obj, zminush, H, R)
            P = obj.StateCovariance;
            
            iCov = H*P*(H.') + R;
            W = P*(H.') / iCov;
            
            dx = W*zminush;
            obj.StateCovariance = P - W*H*P;
            
            injectError(obj, dx);
            resetError(obj);
            
            innov = reshape(zminush, 1, []);
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
            Q = G*U*(G.');
            P = F*P*(F.') + Q;
        end
        
        function Rout = validateExpandNoise(obj, Rin, num, argName, numstr)%#ok<INUSL>
            %VALIDATEEXPANDNOISE validate measurement noise input and expand
            %to matrix
            %   The optional numstr argument is a string (or char) of the
            %   num argument. This avoids doing a sprintf or string()
            %   conversion in the loop. Must be optional because correct()
            %   cannot know this value at design time.

            if nargin < 5
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
            
            switch numel(Rin)
                case 1
                    Rout = diag( repmat(Rin,1,num) );
                case num
                    Rout = diag(Rin);
                otherwise % matrix 
                    Rout = Rin;
            end
        end
    end

    methods (Abstract)
        sidx = stateinfo(obj);
    end

    methods (Hidden, Static)
        function props = matlabCodegenNontunableProperties(~)
            props = {'ReferenceFrame'};
        end
    end
end
