classdef IModalDialogFunctionality < handle
    %IMODALDIALOGFUNCTIONALITY contains abstract methods and properties
    %that any modal dialog type (VXI-11, Socket, HiSLIP) needs to
    %implement.

    % Copyright 2022-2023 The MathWorks, Inc.

    properties (Abstract)
        Controller matlabshared.transportapp.internal.visamodaldialog.IControllerFunctionalities
        BuilderConstants
    end

    properties (Abstract, Dependent, ...
            SetAccess = ?matlabshared.transportapp.internal.utilities.ITestable)
        Closeable
    end

    methods (Abstract)
        form = construct(obj);
        teardown(obj);
    end
end
