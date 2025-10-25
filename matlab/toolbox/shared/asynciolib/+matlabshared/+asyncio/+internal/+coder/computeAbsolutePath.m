function absolutePath = computeAbsolutePath(inputFileName)
% COMPUTEABSOLUTEPATH Computes the absolute path for a file specified in
% INPUTFILENAME. If the specified file name does not exist, it returns an
% empty. The maximum length supported length for the absolute path is 4096
% characters. Currently, non-ASCII characters are not supported.
% NOTE: This is used only in generated code.

% Copyright 2018-2024 The MathWorks, Inc.

%#codegen


absolutePath = matlabshared.asyncio.internal.coder.API.computeAbsolutePath(inputFileName);

% LocalWords:  INPUTFILENAME
