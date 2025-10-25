classdef ekfPredictFcn < matlab.System %#codegen

   %  Copyright 2023 The MathWorks, Inc.

   properties (Nontunable)
      DlgParamStruct  % Parent Mask Param struct
      SLFcn cell = {} % Simulink functions in use (if any)
      DataType 
   end

   methods
      function obj = ekfPredictFcn(varargin)
         setProperties(obj,nargin,varargin{:});
      end
   end

   methods (Access = protected)
      function [xNew,P]  = stepImpl(obj,x,P,Q,uState,~)
         % EKF Predictor.
         % (last input only for controlling the execution order)
         pS = obj.DlgParamStruct;

         % If process noise is time-varying then compute square-root
         % factorization.
         if pS.HasTimeVaryingQ
            Q = matlabshared.tracking.internal.svdPSD(Q);
         end

         % Construct fcn handles
         if pS.IsSimulinkFcn
            StateTransitionJacobianFcnH_SL = str2func(pS.FcnName);
            if pS.HasAdditiveNoise
               StateTransitionFcnH = @(fState)StateTransitionJacobianFcnH_SL(fState);
            else
               StateTransitionFcnH = @(fState,fProcNoise)StateTransitionJacobianFcnH_SL(fState,fProcNoise);
            end
         else
            StateTransitionFcnH = str2func(pS.FcnName);
         end
         if pS.HasJacobian
            if pS.IsSimulinkFcn
               StateTransitionJacobianFcnH_SL = str2func(pS.JacobianFcnName);
               if pS.HasAdditiveNoise
                  StateTransitionJacobianFcnH = @(fState)StateTransitionJacobianFcnH_SL(fState);
               else
                  StateTransitionJacobianFcnH = @(fState,fProcNoise)StateTransitionJacobianFcnH_SL(fState,fProcNoise);
               end
            else
               StateTransitionJacobianFcnH = str2func(pS.JacobianFcnName);
            end
         else
            StateTransitionJacobianFcnH = [];
         end

         switch pS.NumberOfExtraArgumentInports
            case 0
               extraArgs = {};
            case 1
               extraArgs = {uState};
            otherwise
               assert(false);
         end

         % Check if dimensions and type of State and Jacobian are correct
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
               'shared_tracking:ExtendedKalmanFilter:StateNonMatchingSizeOrClass',...
               'StateTransitionFcn', 'State', numel(x));

            if pS.HasJacobian
               % Jacobian
               F = StateTransitionJacobianFcnH(x, extraArgs{:});
               % F needs to be square
               isSizeNotCorrect = ~all(size(F) == numel(x));

               if pS.IsSimulinkFcn
                  hasError = isSizeNotCorrect;
               else
                  hasError = isSizeNotCorrect || ~isa(F, class(x));
               end

               coder.internal.errorIf(...
                  hasError,...
                  'shared_tracking:ExtendedKalmanFilter:StateTransitionJacobianNonMatchingSizeOrClass',...
                  'StateTransitionJacobianFcn', numel(x));
            end
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
               'shared_tracking:ExtendedKalmanFilter:StateNonMatchingSizeOrClass',...
               'StateTransitionFcn', 'State', numel(x))

            if pS.HasJacobian
               % Jacobian
               F = StateTransitionJacobianFcnH(x, zeros(size(Q,1),1,'like',x),extraArgs{:});
               % F needs to be square
               isSizeNotCorrect = ~all(size(F) == numel(x));

               if pS.IsSimulinkFcn
                  hasError = isSizeNotCorrect;
               else
                  hasError = isSizeNotCorrect || ~isa(F, class(x));
               end

               coder.internal.errorIf(...
                  hasError,...
                  'shared_tracking:ExtendedKalmanFilter:StateTransitionJacobianNonMatchingSizeOrClass',...
                  'StateTransitionJacobianFcn', numel(x));
            end
         end

         xNew = zeros(size(x),'like',x); %#ok<PREALL>

         if pS.HasAdditiveNoise
            [xNew,P] = matlabshared.tracking.internal.EKFPredictorAdditive.predict(...
               Q,x,P,StateTransitionFcnH,StateTransitionJacobianFcnH,extraArgs{:});
         else
            [xNew,P] = matlabshared.tracking.internal.EKFPredictorNonAdditive.predict(...
               Q,x,P,StateTransitionFcnH,StateTransitionJacobianFcnH,extraArgs{:});
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
