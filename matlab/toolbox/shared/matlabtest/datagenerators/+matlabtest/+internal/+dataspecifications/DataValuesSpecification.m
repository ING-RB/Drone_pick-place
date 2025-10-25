%

%   Copyright 2023 The MathWorks, Inc.

classdef DataValuesSpecification < handle
   properties
      Name
      Data
   end
   methods
       function obj = DataValuesSpecification(theName,theData)
           arguments
               theName {mustBeTextScalar} = '';
               theData = [];
           end
           obj.Name = theName;
           obj.Data = theData;
       end
   end
   
end
