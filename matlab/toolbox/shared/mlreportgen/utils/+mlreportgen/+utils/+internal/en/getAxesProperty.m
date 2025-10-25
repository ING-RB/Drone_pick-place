%mlreportgen.utils.internal.getAxesProperty returns the specified property for the axes represented by axesHandle
%
%   val = mlreportgen.utils.internal.getAxesProperty(axesHandle, propName)
%   returns the value of the property specified by propName for the axes
%   represented by axesHandle. propName can be any valid property of an axes
%
%   [val, isValidProperty] = mlreportgen.utils.internal.getAxesProperty(axesHandle, propName)
%   returns val, the value of the property specified by propName, and
%   isValidProperty, a logical value that indicates whether the specified
%   property is a valid property.
%
%   val is empty if the property is invalid.

 
%   Copyright 2021 The MathWorks, Inc.

