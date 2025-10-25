function [c, h] = sliceArray(array, targetType)
    % sliceArray distributes array elements into cell array elements
    %    C = sliceArray(ARRAY, TARGETTYPE) returns cell array C containing
    %    the elements of ARRAY. Elements of ARRAY are converted to
    %    TARGETTYPE if necessary. C is the same shape as ARRAY.
    %
    %    [C, H] = sliceArray(ARRAY, TARGETTYPE) also returns H containing
    %    the UINT64 hashcodes for the elements of ARRAY. Elements of ARRAY
    %    are converted to TARGETTYPE if necessary. H is the same shape as
    %    ARRAY.
    %
    %    NOTE: sliceArray is intended for internal use only and is subject
    %    to change at any time without warning.
    %
    %    See also dictionary, keyHash, keyMatch

    %   Copyright 2021-2022 The MathWorks, Inc.

    shouldReturnHash = nargout==2;
    
    if ~strcmp(class(array),targetType) && ~isa(array,targetType)
         valueConverter = str2func(targetType);
         classIn = class(array);

        array = valueConverter(array);
        if ~strcmp(class(array),targetType)
            exp = MException(message("MATLAB:invalidConversion", targetType, classIn));
            throwAsCaller(exp);
        end      
    end
    
    if issparse(array)
        array = full(array);
    end

    dims = size(array);
    
    if isequal(dims,[1 1]) % isscalar

        % Use numeric indexing to deflate complex with zero imaginary part.
        if isnumeric(array)
            array = array(1);
        end

        c = {array};
    
        if shouldReturnHash
            h = uint64(keyHash(array));
        end
    else
        c = cell(dims);
    
        if shouldReturnHash

            h = uint64(zeros(dims));

            if isempty(h)
                % Call keyHash on empty arrays in case it errors. We won't use the
                % result because there are no entries.
                keyHash(array);
            end
        end

        for i=1:numel(c)
            element = array(i);
            c{i} = element;
            if shouldReturnHash
                h(i) = keyHash(element);
            end
        end
    end
end
