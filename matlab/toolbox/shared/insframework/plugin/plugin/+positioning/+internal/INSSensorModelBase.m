classdef INSSensorModelBase < positioning.internal.INSModelShared
%   This class is for internal use only. It may be removed in the future.
%INSSensorModelBase Base class of positioning.INSSensorModel    
%

%   Copyright 2021-2022 The MathWorks, Inc.      
  
%#codegen
    
    properties (Access = {?positioning.internal.insEKFBase,?positioning.internal.INSSensorModelBase}) 
        % ListIndex Compile time constant index of sensor in insEKF.Sensors 
        ListIndex
        InFilter = false;
    end
    methods(Static)
        function props = matlabCodegenNontunableProperties(~)
            props = {'ListIndex'};
        end
    end
    
    methods 
        function set.ListIndex(obj,idx)
            % Allow this sensor to only be added to one filter, and only
            % once, by asserting that the original value of InFilter is false.
            % Suppressing MLINT about reading one prop in another's set.
            % This is the only way to do it and make codegen work.
            % ListIndex is a compile time prop. It's nontunable and doesn't exists in the generated code.
            % InFilter is a runtime prop. It exists in the generated code.
            coder.internal.assert(~obj.InFilter,'insframework:insEKF:SensorTwice' ) %#ok<MCSUP> 
            obj.ListIndex = idx;
            obj.InFilter = true; %#ok<MCSUP> 
        end
    end

    methods (Access = protected)
        function p = getInternalProps(~)
            p = {'ListIndex', 'InFilter'};
        end
    end
    methods (Access = {?positioning.internal.insEKFBase,?positioning.internal.INSSensorModelBase}) 
        function n = defaultName(obj)
            % We want the non-package-qualified name
            cls = class(obj);
            if ~contains(cls, '.')
                n = coder.const(cls);
            else
                n = coder.const(...
                    fliplr( extractBefore(fliplr(cls),'.') ));
            end
        end
        
        function [h, H] = validateAndTrimMeasurements(sensor, numMeas, numStates, h, H)
            % Validate that the measurement is of the expected size.
            
            % Ensure measurement is the right size
            coder.internal.assert(numMeas == numel(h), 'insframework:insEKF:MeasSizeExpected', numel(h), numMeas);
            
            % Ensure measurement jacobian is the right size.
            [rH, cH] = size(H);
            coder.internal.assert(numMeas == rH && ...
                numStates == cH && ismatrix(H), ...
                'insframework:insEKF:MeasJacobianSizeExpected', class(sensor), numMeas, numStates, rH, cH);
        end

        function z = convertMeasurement(sensor, filt, z) %#ok<INUSL> 
            % CONVERTMEASUREMENT convert measurement prior to fusion
            %   Sensor classes can overload this method to convert the
            %   input measurement to fuse or residual, Z, to different units.

            % default is no conversion. MLINT suppressed to define API.
        end
    end
    
    methods (Static, Hidden)
        function c = commonstates(~)
            c = {};
        end
    end

    methods
        function statesdot = stateTransition(obj, filt, ~, varargin)
            %STATETRANSITION constant over time state transition function
            s = sensorstates(obj, filt.Options);
            f = fieldnames(s);
            for ii=1:numel(f)
                fld = f{ii};
                exemplar = s.(fld);
                s.(fld) = zeros(size(exemplar), 'like', filt.State);
            end
            statesdot = s;
        end
        
        function  dhdx = measurementJacobian(sensor, filt)
            %MEASUREMENTJACOBIAN compute a numerical Jacobian of measurement()
            
            % function handle with state as input.
            function z = fun(s)
                filt.State = s;
                z = measurement(sensor, filt);
            end
            dhdx = sensor.computeWithNumericJacobian(filt, @fun);
        end
    end
end
