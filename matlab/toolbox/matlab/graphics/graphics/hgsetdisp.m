function hgsetdisp(h)
%

%  Copyright 2012-2020 The MathWorks, Inc.

% This function displays the possible values for the settable properties of
% a handle object. Note that this output is expanded from the struct values
% returned from set(h) to display the detailed options for each property.

if isscalar(h)
    p = set(h);
    pnames = fieldnames(p);
    sp = sort(pnames);
    v = cell(0);
    for i=1:length(sp)
        try
            v{i} = set(h,sp{i}).';
        catch
        end
    end
    o = cell2struct(v,sp,2);
    disp(o)
end
end
