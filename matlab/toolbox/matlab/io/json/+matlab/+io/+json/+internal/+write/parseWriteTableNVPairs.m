function results = parseWriteTableNVPairs(varargin)
%

%   Copyright 2024 The MathWorks, Inc.

    persistent parser
    if isempty(parser)
        parser = inputParser;
        parser.FunctionName = "writetable";
        parser.StructExpand = false;

        % Shared across writetable impls.
        parser.addParameter("WriteRowNames", false);
        parser.addParameter("DateLocale", matlab.internal.datetime.getDefaults('locale'));

        % Specific to JSON writetable, documented.
        parser.addParameter("PrettyPrint", true);
        parser.addParameter("PreserveInfAndNaN", true);

        % Specific to JSON writetable, undocumented.
        parser.addParameter("Encoding", "UTF-8");
        parser.addParameter("IndentText", "    ");
    end

    parser.parse(varargin{:});
    results = parser.Results;

    import matlab.internal.datatypes.validateLogical
    import matlab.internal.datetime.verifyLocale
    results.WriteRowNames = validateLogical(results.WriteRowNames, "WriteRowNames");
    results.PrettyPrint = validateLogical(results.PrettyPrint, "PrettyPrint");
    results.PreserveInfAndNaN = validateLogical(results.PreserveInfAndNaN, "PreserveInfAndNaN");
    results.DateLocale = verifyLocale(results.DateLocale);
end
