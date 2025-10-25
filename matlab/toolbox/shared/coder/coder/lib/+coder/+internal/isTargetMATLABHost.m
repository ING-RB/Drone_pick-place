function tf = isTargetMATLABHost()
% tf = isTargetMATLABHost
% Return true if the generated code or this function is running on MATLAB
% host and can take advantage of MATLAB-provided shared libraries.

%   Copyright 2014-2019 The MathWorks, Inc.

%#codegen
if coder.target('MATLAB')
    tf = true;
    return
end

if coder.target('rtwForRapid')
    tf = true;
    return
end

% Anything running in MATLAB is MATLAB host by definition
if coder.internal.runs_in_matlab
    tf = true;
    return
end

buildConfig = eml_option('CodegenBuildContext');
if isempty(buildConfig)
    % This is one of those clients that doesn't set a build config. Don't
    % assume anything about the target, (it might be host based, it might not).
    tf = false;
    return
end

tf = coder.const(feval('isMatlabHostTarget',buildConfig));
end
