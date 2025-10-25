function varargout = setupExample(arg,workDir)
%

%   Copyright 2017-2023 The MathWorks, Inc.

if isstruct(arg)
    metadata = arg;
else
    metadata = findExample(arg);
end

% Determine workDir
if nargin < 2 || strlength(workDir) == 0
    workDir = matlab.internal.examples.getWorkDir(metadata);
else
    workDir = convertCharsToStrings(workDir);
    workDir = matlab.internal.examples.validateWorkDir(workDir,metadata.foundBy);
end

% Setup workdir.
reuse = isempty(metadata.project) || ~metadata.project(1).supported;
workDir = matlab.internal.examples.setupWorkDir(workDir,reuse);

% Supporting files.
metadata = matlab.internal.examples.setupSupportingFiles(metadata, workDir);

% Main file.
matlab.internal.examples.setupMainFile(metadata, workDir);

if nargout
    varargout{1} = workDir;
    varargout{2} = metadata;
end
end

