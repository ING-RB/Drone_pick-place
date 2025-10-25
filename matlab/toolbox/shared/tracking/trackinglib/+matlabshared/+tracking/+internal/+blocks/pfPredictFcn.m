classdef pfPredictFcn < matlab.System %#codegen
   % Particle filter predict function implementation.

   %  Copyright 2023 The MathWorks, Inc.

   properties (Nontunable)
      DlgParamStruct  % Parent Mask Param struct
      SLFcn cell = {} % Simulink functions in use (if any)
      DataType
   end

   methods
      function obj = pfPredictFcn(varargin)
         setProperties(obj,nargin,varargin{:});
      end
   end

   methods (Access = protected)
      function predictedParticles  = stepImpl(obj,particles,uState,~)
         % Particle Filter Predictor.
         % (last input only for controlling the execution order)
         pS = obj.DlgParamStruct;
         %
         % Inputs:
         %    particles - Particles before prediction
         %    pS        - Structure containing nontunable parameters
         %                 FcnName - Name of the state transition fcn, a Simulink fcn
         %                 IsStateOrientationColumn - particles is [Ns Np] if true
         %                                            particles is [Np Ns] if false
         %                 IsStateVariableCircular - [1 Ns] logical array. Indicates
         %                                           the circular states

         if pS.IsSimulinkFcn
            fcnH_SL = str2func(pS.FcnName);
            fcnH = @(fParticles)fcnH_SL(fParticles);
         else
            fcnH = str2func(pS.FcnName);
         end

         switch pS.NumberOfExtraArgumentInports
            case 0
               extraArgs = {};
            case 1
               extraArgs = {uState};
            otherwise
               assert(false);
         end

         predictedParticles = ...
            matlabshared.tracking.internal.ParticleFilter.pfBlockPredict(fcnH,particles,pS,extraArgs{:});
      end

      function numIn = getNumInputsImpl(~)
         % number of input ports
         numIn = 3;
      end

      function numOut = getNumOutputsImpl(~)
         % number of output ports
         numOut = 1;
      end

      function P = getOutputSizeImpl(obj)
         P =  propagatedInputSize(obj,1);
      end

      function P = isOutputFixedSizeImpl(~)
         P = true;
      end

      function P = getOutputDataTypeImpl(obj)
         if obj.DataType==0
            P = 'double';
         else
            P = 'single';
         end
      end

      function P = isOutputComplexImpl(~)
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
