classdef IControllerFunctionalities < handle
    %ICONTROLLERFUNCTIONALITIES contains abstract members and proeprties
    %that all controller classes need to implement.

    % Copyright 2022-2023 The MathWorks, Inc.

    properties (Abstract)
        Closeable (1, 1) logical
    end

    properties (Abstract, SetObservable)
        VisaConnectionAndIdentification
    end

    methods (Abstract)
        % Method that contains the logic for closing the dialog window.
        close(obj);

        % Method that contains the logic for constructing the dialog window.
        construct(obj, form);
    end
end
