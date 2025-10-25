function tf = isStateflowAppViewer(cbinfo)
%

%   Copyright 2019 The MathWorks, Inc.

    tf  = false;
    if SFStudio.Utils.isStateflowApp( cbinfo )
        if Stateflow.App.Cdr.Runtime.InstanceIndRuntime.isViewer()
            tf = true;
        end
    end
end
