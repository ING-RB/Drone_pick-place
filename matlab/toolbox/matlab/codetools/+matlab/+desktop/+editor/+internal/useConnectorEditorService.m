function useConnector = useConnectorEditorService()
%matlab.desktop.editor.internal.useConnectorEditorService returns true if editor APIs should use connector editor service
%   Currently, connector editor service is only used by MATLAB Mobile
%   to open native plain code editor or MATLAB Live Editor.
%
%   This function is unsupported and might change or be removed without
%   notice in a future version.

%   Copyright 2022 The MathWorks, Inc.

clientType = connector.internal.getClientType();
useConnector = startsWith(clientType, 'mobile', 'IgnoreCase', true);

end
