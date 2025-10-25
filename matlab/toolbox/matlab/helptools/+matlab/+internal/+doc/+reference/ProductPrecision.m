classdef ProductPrecision
   enumeration
       Filter,Sort
   end
   
   methods
       function filter = isFilter(obj)
           filter = obj == matlab.internal.doc.reference.ProductPrecision.Filter;
       end
       
       function sort = isSort(obj)
           sort = obj == matlab.internal.doc.reference.ProductPrecision.Sort;
       end
   end
end

% Copyright 2020 The MathWorks, Inc.
