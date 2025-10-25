function T = onesLike(obj,varargin)
%This method is for internal use only. It may be removed in the future.

%ONESLIKE Create identity transformation with an exemplar's datatype
%   This method is called if the user tries the following syntax:
%   ones(1, "like", se3)

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Call static "ones" method that is defined on all subclasses.
    T = obj.ones(varargin{:}, underlyingType(obj));

end
