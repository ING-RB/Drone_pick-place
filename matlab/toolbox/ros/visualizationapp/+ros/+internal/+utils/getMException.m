function ME = getMException(msgId,varargin)
%This class is for internal use only. It may be removed in the future.

%   This is used for generating MATLAB execution only for Visualization App.
%   The first input must be a valid message ID.
%   All inputs will be passed to the MATLAB MESSAGE function.

%   Copyright 2022 The MathWorks, Inc.
ME = MException(message(msgId, varargin{:}));
