function y = mexInterceptionDebugMode(val)
    persistent isDebugModeEnabled;
    if isempty(isDebugModeEnabled)
        isDebugModeEnabled = false;
    end
    y = isDebugModeEnabled;
    if nargin > 0
        assert(isscalar(val));
        isDebugModeEnabled = logical(val);
    end
end