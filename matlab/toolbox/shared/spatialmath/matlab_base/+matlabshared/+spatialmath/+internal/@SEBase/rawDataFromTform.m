function [M, MInd] = rawDataFromTform(tf,sz)
%This method is for internal use only. It may be removed in the future.

%rawDataFromTform Get the raw data property values when initializing object from a transformation matrix
%   The M and MInd outputs can be assigned directly to the properties of
%   the same name in the se2 and se3 objects.
%   The SZ input will preserve a certain array shape in the MInd output
%   (this will determine the object array shape).

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    M = tf;

    if nargin < 2
        MInd = cast(1:size(tf,3), "like", tf);
    else
        % Use size information
        if isempty(tf)
            MInd = cast(zeros(sz), "like", tf);
        else
            MInd = reshape(cast(1:size(tf,3), "like", tf), sz);
        end
    end


end
