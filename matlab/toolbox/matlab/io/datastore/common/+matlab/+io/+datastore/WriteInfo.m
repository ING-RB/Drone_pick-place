classdef WriteInfo < handle
%WRITEINFO Object that contains information required by writeall regarding
%   This class creates an object that contains information about the data
%   read, the suggested output file name, and the location to be written.
%   WriteInfo is a handle class.

%   Copyright 2019-2020 The MathWorks, Inc.
    properties
        ReadInfo;
        SuggestedOutputName (1,:) string = missing;
        Location (1,:) string = missing;
    end
    
    methods % constructor
        function writeInfo = WriteInfo(readInfo, outName, location)
            writeInfo.ReadInfo = readInfo;
            writeInfo.SuggestedOutputName = outName;
            writeInfo.Location = location;
        end
    end
end