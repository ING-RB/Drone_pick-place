function obj = isetfield(obj, field, value)
%ISETFIELD Set instrument object internal fields.
%
%   OBJ = ISETFIELD(OBJ, FIELD, VAL) sets the value of OBJ's FIELD 
%   to VAL.
%
%   This function is a helper function for the concatenation and
%   manipulation of instrument object arrays. This function should
%   not be used directly by users.
%

%   MP 7-13-99
%   Copyright 1999-2011 The MathWorks, Inc. 
%   $Revision: 1.1.6.2 $  $Date: 2011/05/13 18:05:54 $

% Assign the specified field information.
try
    obj.(field) = value;
catch %#ok<CTCH>
   error(message('instrument:icinterface:isetfield:invalidFIELD', field));
end
