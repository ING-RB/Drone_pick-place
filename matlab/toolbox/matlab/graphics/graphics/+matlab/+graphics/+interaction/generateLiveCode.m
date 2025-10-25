function generateLiveCode(hObj,action,isUndoable)
% An API to call the Live Editor Code Generation mechanism

%   Copyright 2020-2021 The MathWorks, Inc.

if nargin < 3
    isUndoable = true;
end

hFig = ancestor(hObj,'figure');
if isprop(hFig,'CodeGenerationProxy')
    hFig.CodeGenerationProxy.interactionOccured(hObj,action,isUndoable);
end

end

