function value = isequaln(pkg, varargin)
    % Fall back to isequal, as there is no NaN support in MF0, i.e.,
    % isequal and isequaln will always return the same result.
    value = isequal(pkg, varargin{:});
end