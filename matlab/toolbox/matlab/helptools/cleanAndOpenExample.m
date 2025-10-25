function cleanAndOpenExample(exampleInfo, varargin)
%

%   Copyright 2021 The MathWorks, Inc.
    if iscell(exampleInfo)
        %   This code is executed when cleanAndOpenExample is invoked from the   
        %   Documentation and varargin always is empty in this case.
        id = matlab.internal.examples.identifyExample(exampleInfo{1});
        matlab.internal.examples.cleanWorkDir(matlab.internal.examples.getWorkDir(findExample(id)));
        if numel(exampleInfo) > 1
            openExample(id, exampleInfo{2:end});
        else
            openExample(id);
        end
    else
        id = matlab.internal.examples.identifyExample(exampleInfo);
        matlab.internal.examples.cleanWorkDir(matlab.internal.examples.getWorkDir(findExample(id)));
        if isempty(varargin)
            openExample(exampleInfo);
        else
            openExample(exampleInfo, varargin{:});
        end
    end
end

