function out = igetfield(obj, field)
%IGETFIELD Get instrument object internal fields.
%
%   VAL = IGETFIELD(OBJ, FIELD) returns the value of object's, OBJ,
%   FIELD to VAL.
%
%   This function is a helper function for the concatenation and
%   manipulation of instrument object arrays. This function should
%   not be used directly by users.
%

%   MP 7-27-99
%   Copyright 1999-2011 The MathWorks, Inc. 
%   $Revision: 1.1.6.2 $  $Date: 2011/05/13 18:06:11 $


% Return the specified field information.
switch field
case 'store'
   out = obj.store;
otherwise
   error(message('instrument:instrument:igetfield:invalidFIELD', field));
end
