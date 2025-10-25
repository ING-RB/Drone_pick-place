function exceptionObject = createException(component, mnemonicField, messageText, varargin)
% CREATEEXCEPTION - This creates an exception object.  The
% ErrorID is of the form
% MATLAB:ui:ComponentName:ErrorDescription
% For example:
% MATLAB:ui:Gauge:invalidValue

componentName = matlab.ui.control.internal.model.PropertyHandling.getComponentClassName(component);

errId = ['MATLAB:ui:', componentName, ':', mnemonicField];
exceptionObject = MException(errId, messageText, varargin{:});
end