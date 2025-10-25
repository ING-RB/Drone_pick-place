function p = tunerCostFcnParam(filt)
%TUNERCOSTFCNPARAM Example first parameter for tuning cost function
%   Create a struct that has the same fields as needed for tuning an insEKF
%   filter with a custom cost function. This is particularly useful when
%   trying to generate C-code for a cost function using MATLAB Coder.
%
%   Example:
%   % Tune the insEKF with a MEX-accelerated custom cost function.
%   % This example requires MATLAB Coder. 
%   %
%   filt = insEKF;
%   createTunerCostTemplate(filt); % open new cost function in the editor
%   % Save the file in the editor as-is 
%   doc = matlab.desktop.editor.getActive;
%   doc.saveAs(fullfile(pwd, 'tunercost.m'));
%  
%   % Use this cost function to autotune.
%   % Load sensor data and ground truth
%   ld = load("accelGyroINSEKFData.mat");
%       
%   % MEX-accelerate the cost function with MATLAB Coder
%   p = tunerCostFcnParam(filt);
%   disp('Generating MEX-accelerated cost function');
%   codegen tunercost.m -args {p, ld.sensorData, ld.groundTruth};
%
%   stateparts(filt, "Orientation", compact(ld.initOrient));
%   statecovparts(filt, "Orientation", 1e-2);
%  
%   mnoise = tunernoise(filt);
%   cfg = tunerconfig(filt, MaxIterations=1, ...
%          ObjectiveLimit=1e-4, ...
%          Cost="custom", ...
%          CustomCostFcn = @tunercost_mex);
%   tunedmn = tune(filt, mnoise, ld.sensorData, ...
%           ld.groundTruth, cfg);
%  
%   See also: insEKF/tune, insEKF/createTunerCostTemplate

%   Copyright 2021 The MathWorks, Inc.


p = fusion.internal.tuner.makeFilterParameters(filt, tunernoise(filt), true);
end
