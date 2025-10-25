function list = baseClassesFromName(cls)
%   This function is for internal use only. It may be removed in the future.   
% BASECLASSESFROMNAME return a list of all base classes of class CLS. The
%   input CLS is a string or char array identifying the class to inspect. The
%   output LIST is a string array of root base class names having no further
%   base classes
%
%   Example:
%       bcls = fusion.internal.tuner.baseClassesFromName('ahrsfilter')
%

%   Copyright 2020 The MathWorks, Inc.    

% This is a basic Breadth-First-Search up the meta class tree
mc = meta.class.fromName(cls);
list = string.empty;
if ~isempty(mc)
    queue = mc.SuperclassList;
    while ~isempty(queue)
        sc = queue(1).SuperclassList;
        
        % Suppress MLINT here. There is no way to tell how tall the
        % hierarchy is beforehand to preallocate. It is likely short
        % though.
        list(end+1) = queue(1).Name; %#ok<AGROW>
        queue(1) = [];
        queue(end+1: end+numel(sc)) = sc;
    end
end    
end
