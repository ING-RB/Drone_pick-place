classdef EKFPredictor
    %

    %   Copyright 2016-2020 The MathWorks, Inc.

    %#codegen
    properties(Abstract)
        HasAdditiveNoise;
    end    
    
    methods(Abstract,Static)
        hasError = validateStateTransitionFcn(h,x,numW,varargin);  
        hasError = validateStateTransitionJacobianFcn(h,x,numW,varargin); 
        expectedNargin =  getExpectedNargin(fcnH);
        [x,S] = predict(Qs,x,S,stateFcn,stateJacobianFcn,varargin);
        [dFdx,Qsqrt,wZeros] = predictionMatrices(Qs,x,f,df,varargin);
    end
    
    methods(Static,Hidden)
        function props = matlabCodegenNontunableProperties(~)
            % Let the coder know about non-tunable parameters so that it
            % can generate more efficient code.
            props = {'HasAdditiveNoise'};
        end
    end
end
