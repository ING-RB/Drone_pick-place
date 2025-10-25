function [b,f,c] = mode(a,dim)
%

% Copyright 2014-2024 The MathWorks, Inc.

narginchk(1, 2);

if isa(a,"categorical")
    acodes = a.codes;
    
    % Rely on built-in's NaN handling if input contains any <undefined> elements.
    acodes = categorical.castCodesForBuiltins(acodes);
    
    % Rely on mode's behavior with dim vs. without, especially for empty input
    outArgs = cell(1,nargout-1);
    try
        if nargin == 1
            [bcodes,outArgs{:}] = mode(acodes);
        else
            [bcodes,outArgs{:}] = mode(acodes,dim);
        end
    catch ME
        throw(ME);
    end
    
    if isfloat(bcodes)
        % Cast back to integer codes, including NaN -> <undefined>
        numCats = length(a.categoryNames);
        bcodes = categorical.castCodes(bcodes,numCats);
    end
    b = a; % preserve subclass
    b.codes = bcodes;
    
    if nargout > 1
        f = outArgs{1};
        if nargout > 2
            c = outArgs{2};
            % Convert each vector of codes to a categorical vector
            c_i = a;
            for i = 1:numel(c)
                if isfloat(c{i})
                    c{i} = categorical.castCodes(c{i},numCats);
                end
                c_i.codes = c{i};
                c{i} = c_i;
            end
        end
    end
else
    [b,f,c] = matlab.internal.datatypes.fevalFunctionOnPath("mode",a,dim);
end
