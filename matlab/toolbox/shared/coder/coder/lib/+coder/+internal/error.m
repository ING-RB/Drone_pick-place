function error(msgId,varargin)
%MATLAB Code Generation Private Function

%   This is used for MATLAB execution only.
%   The first input must be a valid message ID.
%   All inputs will be passed to the MATLAB MESSAGE function.

%   Copyright 2007-2021 The MathWorks, Inc.
ME = MException(message(msgId, varargin{:}));
ME.throwAsCaller();
