classdef ekfCorrectFcn < matlab.System %#codegen
   % EKF Correct Fcn implementation.

   %  Copyright 2023 The MathWorks, Inc.

   properties (Nontunable)
      DlgParamStruct  % Parent Mask Param struct
      SLFcn cell = {} % Simulink functions in use (if any)
      DataType
      SampleTime
   end

   methods
      function obj = ekfCorrectFcn(varargin)
         obj@matlab.System();
         setProperties(obj,nargin,varargin{:});
      end
   end

   methods (Access = protected)
      function [xNew,P,blockOrdering] = stepImpl(obj,x,P,yMeas,R,uMeas,blockOrdering)
         pM = obj.DlgParamStruct;
         % If measurement noise is time-varying then compute square-root
         % factorization.
         if pM.HasTimeVaryingR
            R = matlabshared.tracking.internal.svdPSD(R);
         end

         % Construct the function handle for measurement fcn
         if pM.IsSimulinkFcn
            MeasurementFcnH_SL = str2func(pM.FcnName);
            if pM.HasAdditiveNoise
               MeasurementFcnH = @(fState)MeasurementFcnH_SL(fState);
            else
               MeasurementFcnH = @(fState,fMeasNoise)MeasurementFcnH_SL(fState,fMeasNoise);
            end
         else
            MeasurementFcnH = str2func(pM.FcnName);
         end

         % Construct the function handle for measurement Jacobian fcn
         if pM.HasJacobian
            if pM.IsSimulinkFcn
               MeasurementJacobianFcnH_SL = str2func(pM.JacobianFcnName);
               if pM.HasAdditiveNoise
                  MeasurementJacobianFcnH = @(fState)MeasurementJacobianFcnH_SL(fState);
               else
                  MeasurementJacobianFcnH = @(fState,fMeasNoise)MeasurementJacobianFcnH_SL(fState,fMeasNoise);
               end
            else
               MeasurementJacobianFcnH = str2func(pM.JacobianFcnName);
            end
         else
            MeasurementJacobianFcnH = [];
         end

         % Handle (optional) extra input arguments of the measurement & jacobian fcns
         switch pM.NumberOfExtraArgumentInports
            case 0
               extraArgs = {};
            case 1
               extraArgs = {uMeas};
            otherwise
               assert(false);
         end

         % Construct the corrector, perform the update
         if pM.HasAdditiveNoise
            ekfCorrector = matlabshared.tracking.internal.EKFCorrectorAdditive();
         else
            ekfCorrector = matlabshared.tracking.internal.EKFCorrectorNonAdditive();
         end

         % Check if dimensions and type of Measurement and Jacobian are correct
         if pM.HasAdditiveNoise
            % Additive noise

            % MeasurementFcn
            ztry = MeasurementFcnH(x, extraArgs{:});

            if pM.IsSimulinkFcn
               hasError = (numel(ztry) ~= numel(yMeas));
            else
               hasError = (numel(ztry) ~= numel(yMeas)) || ~isa(ztry, class(x));
            end


            coder.internal.errorIf(...
               hasError,...
               'shared_tracking:ExtendedKalmanFilter:MeasurementNonMatchingSizeOrClass',...
               'MeasurementFcn');

            if pM.HasJacobian
               % MeasurementJacobianFcn
               Htry = MeasurementJacobianFcnH(x, extraArgs{:});
               isSizeNotCorrect = numel(yMeas) ~= size(Htry,1) || numel(x) ~= size(Htry,2);

               if pM.IsSimulinkFcn
                  hasError = isSizeNotCorrect;
               else
                  hasError = isSizeNotCorrect || ~isa(Htry, class(x));
               end

               coder.internal.errorIf(...
                  hasError,...
                  'shared_tracking:ExtendedKalmanFilter:MeasurementJacobianNonMatchingSizeOrClass',...
                  'MeasurementJacobianFcn',numel(yMeas),numel(x));
            end
         else
            % Non-additive noise

            % MeasurementFcn
            ztry = MeasurementFcnH(...
               x, zeros(size(R,1),1,'like',x), ...
               extraArgs{:});

            if pM.IsSimulinkFcn
               hasError = (numel(ztry) ~= numel(yMeas));
            else
               hasError = (numel(ztry) ~= numel(yMeas)) || ~isa(ztry, class(x));
            end

            coder.internal.errorIf(...
               hasError,...
               'shared_tracking:ExtendedKalmanFilter:MeasurementNonMatchingSizeOrClass',...
               'MeasurementFcn');

            if pM.HasJacobian
               % MeasurementJacobianFcn
               Htry = MeasurementJacobianFcnH(...
                  x, zeros(size(R,1),1,'like',x), ...
                  extraArgs{:});

               isSizeNotCorrect = numel(yMeas) ~= size(Htry,1) || numel(x) ~= size(Htry,2);

               if pM.IsSimulinkFcn
                  hasError = isSizeNotCorrect;
               else
                  hasError = isSizeNotCorrect || ~isa(Htry, class(x));
               end

               coder.internal.errorIf(...
                  hasError,...
                  'shared_tracking:ExtendedKalmanFilter:MeasurementJacobianNonMatchingSizeOrClass',...
                  'MeasurementJacobianFcn',numel(yMeas),numel(x));
            end
         end
         % Measurement wrapping
         ekfCorrector.HasMeasurementWrapping = pM.HasWrapping;

         xNew = zeros(size(x),'like',x); %#ok<PREALL>

         [xNew,P] = ekfCorrector.correct(...
            yMeas,R,x,P,MeasurementFcnH,MeasurementJacobianFcnH,extraArgs{:});

      end

      function numIn = getNumInputsImpl(~)
         % number of input ports
         numIn = 6;
      end

      function numOut = getNumOutputsImpl(~)
         % number of output ports
         numOut = 3;
      end

      function [xNew, P, b] = getOutputSizeImpl(obj)
         xNew =  propagatedInputSize(obj,1);
         P =  propagatedInputSize(obj,2);
         b =  propagatedInputSize(obj,6);
      end

      function [xNew, P, b] = isOutputFixedSizeImpl(~)
         xNew = true;
         P = true;
         b = true;
      end

      function [xNew, P, b] = getOutputDataTypeImpl(obj)
         if obj.DataType==0
            Type = 'double';
         else
            Type = 'single';
         end
         xNew = Type;
         P = Type;
         b = 'logical';
      end

      function [xNew, P, b] = isOutputComplexImpl(~)
         xNew = false;
         P = false;
         b = false;
      end

      function names = getSimulinkFunctionNamesImpl(obj)
         % Use 'getSimulinkFunctionNamesImpl' method to declare
         % the name of the Simulink function that will be called
         % from the MATLAB System block's System object code.
         names = obj.SLFcn;
      end

      function sts = getSampleTimeImpl(obj)
         % required for multirate support
         if obj.SampleTime < 0
            sts = createSampleTime(obj,'Type','Inherited');
         else
            sts = createSampleTime(obj,'Type','Discrete',...
               'SampleTime',obj.SampleTime);
         end
      end
   end

end
