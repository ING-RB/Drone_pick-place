function p = isscalar(~) %#codegen
    % matlab.internal.coder.tabular relies on being treated like a scalar
    %   even when its size() doesn't return [1 1 ...]
    p = true;
end