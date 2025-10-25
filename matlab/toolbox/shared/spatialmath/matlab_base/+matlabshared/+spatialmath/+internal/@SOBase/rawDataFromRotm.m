function [M, MInd] = rawDataFromRotm(rotm,sz)
%This method is for internal use only. It may be removed in the future.

%rawDataFromRotm Get the raw data property values when initializing object from a rotation matrix
%   The M and MInd outputs can be assigned directly to the properties of
%   the same name in the so2 and so3 objects.
%   The SZ input will preserve a certain array shape in the MInd output
%   (this will determine the object array shape).

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    M = rotm;

    if nargin < 2
        MInd = cast(1:size(rotm,3), "like", rotm);
    else
        % Use size information
        if isempty(rotm)
            MInd = cast(zeros(sz), "like", rotm);
        else
            MInd = reshape(cast(1:size(rotm,3), "like", rotm), sz);
        end
    end


end
