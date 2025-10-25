function info = actxcontrollist()
%ACTXCONTROLLIST Return a list of ActiveX controls.
%  ACTXCONTROLLIST will be removed in a future release.
%  INFO = ACTXCONTROLLIST 
%  returns the Name, ProgID, and Filename of ActiveX controls on a computer
%  system.
%
%  INFO is a cell array with three columns {Name, ProgID, Filename}. The
%  number of rows of this cell array is the number of ActiveX controls
%  installed on a computer system. Each row is filled with information
%  related to a specific ActiveX control. All the rows are sorted by the
%  first column: Name.
%
%  Example: info=actxcontrollist
%   
%  See also ACTXCONTROL, ACTXCONTROLSELECT.

% Copyright 1984-2004 The MathWorks, Inc.
% $Revision: 1.0 
if feature("webui")
    error(message('MATLAB:actxcontrol:FunctionHasBeenRemoved','ACTXCONTROLLIST'));
else
    warning(message('MATLAB:ui:actxcontrollist:FunctionToBeRemoved'));
    info = actxcontrollist_internal();
end
