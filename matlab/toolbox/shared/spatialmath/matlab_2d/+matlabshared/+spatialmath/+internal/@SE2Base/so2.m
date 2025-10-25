function R = so2(obj)
%SO2 Extract SO(2) rotation array
%   R = SO2(T) extracts the rotational part of the SE2
%   transformation, T, and returns it as an so2 object,
%   R. The translational part of T is ignored.
%
%   If T is an array of N transformations, then R is an array of the same
%   size.
%
%   See also rotm.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    if isempty(obj)
        % Handle special case of empty object
        % Reshape below will work to get the actual shape, e.g. if size(obj) ==
        % [2 1 0].
        soObj = so2(cast([],"like",obj.M));
    else
        d = obj.Dim-1;
        soObj = so2(obj.M(1:d,1:d,:));
    end

    % Ensure that size matches se2 object array
    R = reshape(soObj,size(obj));

end
