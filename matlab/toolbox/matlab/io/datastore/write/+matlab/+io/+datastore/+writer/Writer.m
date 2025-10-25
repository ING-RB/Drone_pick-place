classdef Writer
%WRITER This class captures the interface expected of writable datastores

%   Copyright 2023 The MathWorks, Inc.
    methods (Abstract)
        write(data, writeInfo, outputFmt, varargin);
    end
end