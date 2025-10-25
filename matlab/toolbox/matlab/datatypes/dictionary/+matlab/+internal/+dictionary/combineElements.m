function a = combineElements(c, targetType)
    % combineElements concatenates entry parts into a single array
    %    A = combineElements(C) returns array A containing the elements of cell
    %    array C concatenated. A is the same shape as C.
    %
    %    A = combineElements(C, TARGETTYPE) returns empty array A of type
    %    TARGETTYPE if C is empty, otherwise it is ignored.
    %
    %    NOTE: combineElements is intended for internal use only and is subject
    %    to change at any time without warning.
    %
    %    See also dictionary, sliceArray

    %   Copyright 2021-2022 The MathWorks, Inc.

    try
        if ~iscell(c)
            error(message("MATLAB:dictionary:CannotCombine"))
        end

        if isempty(c)
            fcn = str2func(targetType + ".empty");
            a = fcn(size(c));
        elseif isscalar(c)
            a = c{1};
        elseif isrow(c)
            a = horzcat(c{:});
        elseif iscolumn(c)
            a = vertcat(c{:});
        else
            a = vertcat(c{:});
            a = reshape(a,size(c));
        end
    catch e
        newE = MException(message("MATLAB:dictionary:CannotCombine"));
        throwAsCaller(newE);
    end
end