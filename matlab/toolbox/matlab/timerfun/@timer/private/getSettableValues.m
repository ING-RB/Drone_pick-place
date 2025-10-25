function [propNames, propVals] = getSettableValues(obj)
%getSettableValues gets all the settable values of a timer object array
%
%    getSettableValues(OBJ) returns the settable values of OBJ as a list of settable
%    property names and a cell array containing the values.
%
%    RDD 1-18-2002
%    Copyright 2001-2022 The MathWorks, Inc.

objlen = length(obj);

propnames = [];
propVals = cell(objlen,1);

%attribVal = cell(objlen, numel(settableAttrib));

for objnum=1:objlen
    currObj = obj(objnum);
    if (isvalid(currObj))
        if isempty(propnames)
            % property names should be same for all timers, so
            % calculating only once should suffice.
            settableAttrib = findAttrValue(obj(1),'SetAccess','public');
            propNames = transpose(settableAttrib);
        end

        for i = 1: numel(settableAttrib)
            attribVal{i} = get(currObj, settableAttrib{i});
        end
        propVals{objnum} = attribVal;
    end
end
