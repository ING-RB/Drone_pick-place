function copyUnlinked(gobj)
%

% Copyright 2008-2020 The MathWorks, Inc.

% Find brushed graphics in this container
sibs = datamanager.getAllBrushedObjects(gobj);

if length(sibs)==1
    localMultiObjCallback(sibs);
elseif length(sibs)>1 % More than 1 obj brushed, open disambiguation dialog
    datamanager.disambiguate(handle(sibs),{@localMultiObjCallback});
end


function localMultiObjCallback(gobj)

cmdStr = datamanager.var2string(brushing.select.getArraySelection(gobj));

clipboard('copy',cmdStr);

