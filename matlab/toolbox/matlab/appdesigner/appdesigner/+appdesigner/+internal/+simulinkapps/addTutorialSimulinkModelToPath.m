function addTutorialSimulinkModelToPath()
    % ADDTUTORIALSIMULINKMODELTOPATH Gets the path to the bouncingBall.slx model
    %   and adds it to the MATLAB path.

    % Copyright 2024 The MathWorks, Inc.

    addpath(fullfile(matlabroot, 'toolbox', 'slsim', 'bind', 'appdesigner', 'tutorials'));
end