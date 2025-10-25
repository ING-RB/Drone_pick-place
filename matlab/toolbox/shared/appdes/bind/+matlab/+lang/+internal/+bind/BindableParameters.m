classdef BindableParameters < handle
    %BINDABLEPARAMETERS Determines what parameters (properties, events, key
    % indexes) of a Source or Destination object can be bound to.

    % Copyright 2022 The MathWorks, Inc.

    properties (Constant, Access=private)
        BindingExtensionsService = matlab.lang.internal.bind.BindExtensionService
        HandleMethods = methods("handle")
        HandleProperties = properties("handle")
    end

    methods
        function choices = getSourceParameters(obj, source)
            %GETSOURCEPARAMETERS Returns the properties, events, and key
            %indexes of the specified source object.

            choices = [];

            bindingExtensions = obj.BindingExtensionsService.Extensions;

            sourceClass = class(source);
            if isConfigured(bindingExtensions) && isKey(bindingExtensions, sourceClass)
                extensionInfo = bindingExtensions(sourceClass);
                sourceParameterString = extensionInfo.sourceParameters;

                obj.evalChoices(sourceParameterString);
            else
                mc = metaclass(source);
                props = mc.PropertyList;
                propNames = {props.Name};

                choices = propNames([props.SetObservable] & strcmp({props.GetAccess}, "public"))';
            end
        end

        function choices = getDestinationParameters(obj, destination)
            %GETDESTINATIONPARAMETERS Returns the properties, events, and
            %key indexes of the specified destination object.
            
            choices = [];

            bindingExtensions = obj.BindingExtensionsService.Extensions;

            destinationClass = class(destination);
            if isConfigured(bindingExtensions) && isKey(bindingExtensions, destinationClass)
                extensionInfo = bindingExtensions(destinationClass);
                destinationParameterString = extensionInfo.destinationParameters;

                obj.evalChoices(destinationParameterString);
            else
                % Generic object
                className = obj.getClassName(destination);
                choices = sort(setdiff([properties(destination); methods(destination)], [obj.HandleProperties; obj.HandleMethods; className]));
            end

        end
    end

    methods (Static)
        function evalChoices(choiceStr)
            choiceStr = choiceStr + ";";
            evalin("caller", choiceStr);
        end

        function name = getClassName(srcOrDst)
            name = split(class(srcOrDst));
            name = name{end};
        end
    end
end

