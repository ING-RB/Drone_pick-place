classdef UKFPredictor
    %#codegen
    
    % Copyright 2016-2019 The MathWorks, Inc.
    properties(Abstract)
        HasAdditiveNoise;
    end
    
    methods(Abstract,Static)
        hasError = validateStateTransitionFcn(h,x,numW,varargin);
        expectedNargin =  getExpectedNargin(fcnH);
        [x,S] = predict(Qs,x,S,alpha,beta,kappa,f,varargin)
    end
    
    methods(Static,Hidden)
        function props = matlabCodegenNontunableProperties(~)
            % Let the coder know about non-tunable parameters so that it
            % can generate more efficient code.
            props = {'HasAdditiveNoise'};
        end        
    end
end
