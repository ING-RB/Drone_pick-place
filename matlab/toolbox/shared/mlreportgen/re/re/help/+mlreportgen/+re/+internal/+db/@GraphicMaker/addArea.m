%addArea Add area region
%  id = addArea(gm,coords,linkends) adds an area region defined for the
%  callout, based on the specified coords and linkends. The area region can
%  be used to create hyperlinks on the graphics. The coords argument must
%  be a numeric vector defining the coordinates of the area. The linkends
%  argument can be specified as a character vector or string scalar and
%  points to the callout which refer to this area, and can be used for
%  bidirectional linking. This method returns a unique id that can be used
%  to add callout for this area.
%
%  id = addArea(gm,otherUnits,coords,linkends) adds an area region defined
%  for the callout, based on the specified otherUnits, coords, and
%  linkends. The otherUnits argument can be specified as a character vector
%  or string scalar, which indicates how the coords argument is
%  interpreted. The coords argument can be specified as a character vector
%  or string scalar defining the coordinates of the area. The linkends
%  argument can be specified as a character vector or string scalar and
%  points to the callout which refer to this area. This method returns a
%  unique id that can be used to add callout for this area.
%
%  area = addArea(gm,id,otherUnits,coords,linkends) adds an area region
%  defined for the callout, based on the specified id, otherUnits, coords,
%  and linkends. The id argument must be a unique id for this area that can
%  be used to add callout. It can be specified as a character vector or
%  string scalar. The otherUnits argument can be specified as a character
%  vector or string scalar, which indicates how the coords argument is
%  interpreted. The coords argument can be specified as a character vector
%  or string scalar defining the coordinates of the area. The linkends
%  argument can be specified as a character vector or string scalar and
%  points to the callout which refer to this area. This method returns a
%  matlab.io.xml.dom.Element object defining the area.
%
%   See matlab.io.xml.dom.Element,
%   https://tdg.docbook.org/tdg/4.5/area.html

% Copyright 2021 MathWorks, Inc.