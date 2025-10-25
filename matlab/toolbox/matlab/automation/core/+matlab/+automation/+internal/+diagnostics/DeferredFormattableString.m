classdef DeferredFormattableString < matlab.automation.internal.diagnostics.FormattableString
    % This class is undocumented and may change in a future release.

    % DeferredRichString - FormattableString obtained by evaluating a
    % function handle, but only when the Text is accessed.

    % Copyright 2020-2022 The MathWorks, Inc.

    properties (Dependent, SetAccess=private)
        Text string;
    end

    properties (Access=private)
        Function (1,1) function_handle = @()[];
        DeferredFormattingOperations = {};
    end

    methods
        function str = DeferredFormattableString(fcn)
            str.Function = fcn;
        end

        function txt = get.Text(str)
            formattableString = str.Function();
            assert(isa(formattableString, "matlab.automation.internal.diagnostics.FormattableString"), ...
                "DeferredFormattableString:internal:SanityCheck", "");

            % Apply deferred formatting
            for idx = 1:numel(str.DeferredFormattingOperations)
                formattableString = str.DeferredFormattingOperations{idx}(formattableString);
            end

            txt = formattableString.Text;
        end

        function str = wrap(str, width)
            str.DeferredFormattingOperations{end+1} = @(str)str.wrap(width);
        end

        function str = enrich(str)
            str.DeferredFormattingOperations{end+1} = @enrich;
        end
    end

    methods (Access=protected)
        function str = applyBoldHandling(str)
            str.DeferredFormattingOperations{end+1} = @applyBoldHandling;
        end
        
        function str = applyIndention(str, indention)
            str.DeferredFormattingOperations{end+1} = @(str)str.applyIndention(indention);
        end
    end
end

