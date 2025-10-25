function indices = getDataTypeDisplaySize(sz)
% Returns a string which represents the dimensions
% from the validation struct. The returned values are suitable
% as inputs to reshape to create different sizes of empty arrays.
% E.g. (2,:) => "2x0"

%   Copyright 2018-2020 The MathWorks, Inc.

    indices = "";
    for i=1:numel(sz)
        switch (class(sz{i}))
            case 'uint64'
                indices(i) = string(num2str(sz{i}));
            case 'char'
                indices(i) = "D" + string(sz{i});
        end       
        
    end
    
    indices = join(indices, 'x');
end
