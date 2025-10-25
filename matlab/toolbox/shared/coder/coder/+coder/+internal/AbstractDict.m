classdef (Abstract) AbstractDict
%#codegen
%MATLAB Code Generation Private Class

%   Copyright 2023 The MathWorks, Inc.

methods(Abstract)
    there = hasKey(this, key)

    % Given a scalar key, returns a scalar value corresponding to this key in
    % the dictionary. If the key does not exist, returns an example value and
    % sets hasValue == false.
    [valueOrExample, hasValue] = read(this, key)
    this = write(this, key, value)%includes overwrite, should this be vectorized?
    this = delete(this, key)
    keys = getKeys(this)
    values = getValues(this)
    eg = getExampleKey(this)
    eg = getExampleValue(this)
    n = getNumel(this)
end

methods(Abstract, Static)
    hash = getHash(key)
end

end
