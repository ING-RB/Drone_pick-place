classdef ukfPredictFcn < matlab.System %#codegen
   % UKF predict function implementation.

   %  Copyright 2023 The MathWorks, Inc.

   properties (Nontunable)
      DlgParamStruct  % Parent Mask Param struct
      SLFcn cell = {} % Simulink functions in use (if any)
      DataType
   end

   methods
      function obj = ukfPredictFcn(varargin)
         setProperties(obj,nargin,varargin{:});
      end
   end

   methods (Access = protected)
      function [xNew,P]  = stepImpl(obj,x,P,Q,uState,~)
         % UKF Predictor.
         % (last input only for controlling the execution order)
         pS = obj.DlgParamStruct;
         % If process noise is time-varying then compute square-root
         % factorization.
         if pS.HasTimeVaryingQ
            Q = matlabshared.tracking.internal.svdPSD(Q);
         end

         if pS.IsSimulinkFcn
            StateTransitionFcnH_SL = str2func(pS.FcnName);
            if pS.HasAdditiveNoise
               StateTransitionFcnH = @(fState)StateTransitionFcnH_SL(fState);
            else
               StateTransitionFcnH = @(fState,fProcNoise)StateTransitionFcnH_SL(fState,fProcNoise);
            end
         else
            StateTransitionFcnH = str2func(pS.FcnName);
         end
         switch pS.NumberOfExtraArgumentInports
            case 0
               extraArgs = {};
            case 1
               extraArgs = {uState};
            otherwise
               assert(false);
         end

         xNew = zeros(size(x),'like',x); %#ok<PREALL>
         if pS.HasAdditiveNoise
            % Additive noise

            % StateTransitionFcn
            xTry = StateTransitionFcnH(x, extraArgs{:});

            if pS.IsSimulinkFcn
               hasError = any(size(x) ~= size(xTry));
            else
               hasError = any(size(x) ~= size(xTry)) || ~isa(xTry, class(x));
            end

            coder.internal.errorIf(...
               hasError,...
               'shared_tracking:UnscentedKalmanFilter:StateNonMatchingSizeOrClass',...
               'StateTransitionFcn', 'State', numel(x));

            [xNew,P] = matlabshared.tracking.internal.UKFPredictorAdditive.predict(...
               Q,x,P,...
               pS.Alpha, pS.Beta, pS.Kappa,...
               StateTransitionFcnH, extraArgs{:});
         else
            % Non-additive noise

            % StateTransitionFcn
            xTry = StateTransitionFcnH(x, zeros(size(Q,1),1,'like',x),extraArgs{:});

            if pS.IsSimulinkFcn
               hasError = any(size(x) ~= size(xTry));
            else
               hasError = any(size(x) ~= size(xTry)) || ~isa(xTry, class(x));
            end

            coder.internal.errorIf(...
               hasError,...
               'shared_tracking:UnscentedKalmanFilter:StateNonMatchingSizeOrClass',...
               'StateTransitionFcn', 'State', numel(x));

            [xNew,P] = matlabshared.tracking.internal.UKFPredictorNonAdditive.predict(...
               Q,x,P,...
               pS.Alpha, pS.Beta, pS.Kappa,...
               StateTransitionFcnH, extraArgs{:});
         end

      end

      function numIn = getNumInputsImpl(~)
         % number of input ports
         numIn = 5;
      end

      function numOut = getNumOutputsImpl(~)
         % number of output ports
         numOut = 2;
      end

      function [xNew, P] = getOutputSizeImpl(obj)
         xNew =  propagatedInputSize(obj,1);
         P =  propagatedInputSize(obj,2);
      end

      function [xNew, P] = isOutputFixedSizeImpl(~)
         xNew = true;
         P = true;
      end

      function [xNew, P] = getOutputDataTypeImpl(obj)
         if obj.DataType==0
            Type = 'double';
         else
            Type = 'single';
         end
         xNew = Type;
         P = Type;
      end


      function [xNew, P] = isOutputComplexImpl(~)
         xNew = false;
         P = false;
      end

      function names = getSimulinkFunctionNamesImpl(obj)
         % Use 'getSimulinkFunctionNamesImpl' method to declare
         % the name of the Simulink function that will be called
         % from the MATLAB System block's System object code.
         names = obj.SLFcn;
      end
   end

end
