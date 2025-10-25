classdef SpanHandlingProvider < matlab.io.internal.FunctionInterface
% This class is undocumented and will change in a future release.

% Copyright 2021-2024 The MathWorks, Inc.

    properties (Parameter)
        %MergedCellColumnRule  what to do with horizontal spans in data rows.
        %
        %   Possible values:
        %     placeleft: Place data into the left-most field in the
        %                span, treat remaining fields as missing. (default)
        %
        %    placeright: Place data into the right-most field in the
        %                span, treat remaining fields as missing.
        %
        %     duplicate: Place data into all fields in the span.
        %
        %       omitrow: Skip non-header rows with horizontal spans.
        %
        %         error: Error during import and abort the operation.
        MergedCellColumnRule = "placeleft";

        %MergedCellRowRule  what to do with horizontal spans in data rows.
        %
        %   Possible values:
        %      placetop: Place data into the top-most field in the
        %                span, treat remaining fields as missing. (default)
        %
        %   placebottom: Place data into the bottom-most field in the
        %                span, treat remaining fields as missing.
        %
        %     duplicate: Place data into all fields in the span.
        %
        %       omitvar: Skip variables with vertical spans.
        %
        %         error: Error during import and abort the operation.
        MergedCellRowRule = "placetop";
    end

    methods
        function obj = set.MergedCellColumnRule(obj,rhs)
            rules = ["placeleft", "placeright", "duplicate", "omitrow", "error"];
            obj.MergedCellColumnRule = validatestring(rhs,rules,'','MergedCellColumnRule');
        end

        function obj = set.MergedCellRowRule(obj,rhs)
            rules = ["placetop", "placebottom", "duplicate", "omitvar", "error"];
            obj.MergedCellRowRule = validatestring(rhs,rules,'','MergedCellRowRule');
        end

        function value = get.MergedCellColumnRule(obj)
            if isa(obj, "matlab.io.internal.mixin.UsesStringsForPropertyValues")
                value = obj.MergedCellColumnRule;
            else
                value = char(obj.MergedCellColumnRule);
            end
        end

        function value = get.MergedCellRowRule(obj)
            if isa(obj, "matlab.io.internal.mixin.UsesStringsForPropertyValues")
                value = obj.MergedCellRowRule;
            else
                value = char(obj.MergedCellRowRule);
            end
        end
    end
end
