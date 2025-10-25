function elementwise()
%CODER.DNN.ELEMENTWISE specifies function should be treated as elementwise
%   function
%   CODER.DNN.ELEMENTWISE() is a pragma that specifies all the 
%   computation within this function are elementwise. This pragma 
%   does not require input parameters and optimizes generated 
%   code for custom layers by not requiring permute operations
%   at the boundaries of custom and built-in layers
%
%   Example:
% 
%   methods 
%       function layer = aMIMOLayer(name)
%           layer.Name = name;
%           layer.InputNames = ["input_a", "input_b"]; 
%           layer.OutputNames = ["sum","substract"]; 
%       end 
%      
%       function [Z1, Z2] = predict(~,x,y) 
%           coder.dnn.elementwise();
%           Z1 = x + y;
%           Z2 = x - y;
%       end
%   end
%
%   This is a code generation function.  It has no effect in MATLAB.
%

%#codegen
%   Copyright 2020 The MathWorks, Inc.
    if (~coder.target('MATLAB'))
        coder.allowpcode('plain');
        coder.inline('never');
        coder.dnn.internal.elementwiseImpl(true);
    end
end
