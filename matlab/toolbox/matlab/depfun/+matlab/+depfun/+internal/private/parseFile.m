function result = parseFile(mparser, file)
% Copyright 2020, The MathWorks, Inc.

    result = mparser.getSymbols(file);
    if ~isempty(result.syntax_error)
        err = cell(size(result.syntax_error));
        for k = 1:numel(result.syntax_error)
            err{k} = getString(message('MATLAB:depfun:req:BadSyntaxWithLocation', ...
                result.syntax_error(k).line, ...
                result.syntax_error(k).column, ...
                result.syntax_error(k).message));
        end
        error(message('MATLAB:depfun:req:BadSyntax', file, strjoin(err)));
    end
end