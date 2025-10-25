classdef SuiteModifierService < matlab.unittest.internal.services.Service
    %

    % Copyright 2021-2024 The MathWorks, Inc.

    methods (Abstract, Access=protected)
        % getSuiteModifier - Return suite modifier instance.
        %
        %   MODIFIER = getSuiteModifier(SERVICE, OPTIONS) shall be implemented
        %   to return a suite modifier for test suite creation.
        modifier = getSuiteModifier(service, options);

        % getSuiteSelector - Return suite selector instance.
        %
        %   SELECTOR = getSuiteSelector(SERVICE, OPTIONS) shall be implemented
        %   to return a suite selector for use after suite creation.
        selector = getSuiteSelector(service, options);
    end

    methods (Sealed)
        function fulfill(services, liaison)
            import matlab.unittest.internal.selectors.Modifier;

            modifiers = arrayfun(@(s)getModifier(s,liaison), services, UniformOutput=false);
            liaison.Modifier = Modifier.combine(modifiers, @and);
        end
    end
end

function modifier = getModifier(service, liaison)
modifier = service.getSuiteSelector(liaison.Options);
validateattributes(modifier, "matlab.unittest.selectors.Selector", ...
    "scalar"); % getSuiteSelector must always return a selector
if ~liaison.OnlySelectors
    modifier = modifier & service.getSuiteModifier(liaison.Options);
end
end

