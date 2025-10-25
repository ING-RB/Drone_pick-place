classdef pfCorrectFcn < matlab.System %#codegen
   % Particle filter correct function implementation.

   %  Copyright 2023 The MathWorks, Inc.

   properties (Nontunable)
      DlgParamStruct  % Parent Mask Param struct
      SLFcn cell = {} % Simulink functions in use (if any)
      DataType      
      SampleTime
   end

   % Pre-computed constants or internal states
   properties (Access = private)
      rngState
   end
   
   methods
      function obj = pfCorrectFcn(varargin)
         setProperties(obj,nargin,varargin{:});
      end
   end

   methods (Access = protected)

      function [particles,weights,intervalCounter,blockOrdering] = ...
            stepImpl(obj,particles,weights,intervalCounter,yMeas,uMeas,blockOrdering)
         pM = obj.DlgParamStruct;
         % pfCorrect Correction and resampling step for particle filter

         if pM.IsSimulinkFcn
            fcnH_SL = str2func(pM.FcnName);
            fcnH = @(fParticles,fMeasurement)fcnH_SL(fParticles,fMeasurement);
         else
            fcnH = str2func(pM.FcnName);
         end
         switch pM.NumberOfExtraArgumentInports
            case 0
               extraArgs = {};
            case 1
               extraArgs = {uMeas};
            otherwise
               assert(false);
         end

         [particles,weights,intervalCounter] = ...
            matlabshared.tracking.internal.ParticleFilter.pfBlockCorrectAndResample(...
            fcnH, particles, weights,intervalCounter,yMeas,pM,extraArgs{:});
         obj.rngState = rng();
      end

      function resetImpl(obj)
         % Initialize / reset internal properties
         pM = obj.DlgParamStruct;
         rng(pM.Seed,pM.RandomNumberGenerator);
         obj.rngState = rng();
      end

      function numIn = getNumInputsImpl(~)
         % number of input ports
         numIn = 6;
      end

      function numOut = getNumOutputsImpl(~)
         % number of output ports
         numOut = 4;
      end

      function [P,W,I,B] = getOutputSizeImpl(obj)
         P =  propagatedInputSize(obj,1);
         W =  propagatedInputSize(obj,2);
         I =  propagatedInputSize(obj,3);
         B =  propagatedInputSize(obj,6);
      end

      function [P,W,I,B] = isOutputFixedSizeImpl(~)
         P = true;
         W = true;
         I = true;
         B = true;
      end

      function [P,W,I,B] = getOutputDataTypeImpl(obj)
         if obj.DataType==0
            Type = 'double';
         else
            Type = 'single';
         end
         P = Type;
         W = Type;
         I = Type;
         B = 'logical';
      end

      function [P,W,I,B] = isOutputComplexImpl(~)
         P = false;
         W = false;
         I = false;
         B =  false;
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
