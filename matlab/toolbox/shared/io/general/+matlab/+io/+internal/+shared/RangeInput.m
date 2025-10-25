classdef RangeInput < matlab.io.internal.FunctionInterface
    %
    
    %   Copyright 2018-2020 The MathWorks, Inc.
    
    properties (Parameter)
        Range = '';
    end
    
    methods % set/get methods
        function obj = set.Range(obj,rhs)
            rhs = convertStringsToChars(rhs);
            if isnumeric(rhs)
                try
                    assert(all(rhs > 0) && all(isfinite(rhs)) && all(floor(rhs)==rhs));
                    switch numel(rhs)
                        case 4 % [start-row start-col end-row end-col]
                            assert(rhs(3) >= rhs(1) && rhs(4) >= rhs(2));
                            rhs = char(getCellName(rhs(1),rhs(2))+":"+ getCellName(rhs(3),rhs(4)));
                        case 3 % [start-row start-col end-row inf]
                            assert(false); % Not supported
                        case 2 % [start-row start-col inf     inf]
                            rhs = char(getCellName(rhs(1),rhs(2)));
                        case 1 % [start-row 1         inf     inf]
                            rhs = char(getCellName(rhs(1),1));
                        otherwise
                            assert(false);
                    end
                catch
                    error(message('MATLAB:spreadsheet:sheet:numericRangeWrong'));
                end
                
            elseif ~ischar(rhs)
                error(message('MATLAB:spreadsheet:sheet:rangeMustBeString'));
            else
                rhs = strip(rhs);
            end
            obj.Range = rhs;
        end
    end
    
    methods (Access = {?matlab.io.internal.functions.DetectImportOptionsText,?matlab.unittest.TestCase})
        function nrng = getNumericRange(obj)
            rngStr = split(string(obj.Range),':');
            if numel(rngStr) > 2
                error(message('MATLAB:spreadsheet:sheet:rangeParseInvalid'))
            end
            
            [r,c] = getRC(rngStr);
            
            if any(isnan(r)|isnan(c)) ... % NaNs come from bad conversions
            || any(any(isinf([r,c])) & ~all(isinf([r,c]))) % partial text range A:B3
                error(message('MATLAB:spreadsheet:sheet:rangeParseInvalid'))
            end
            % [row-start, row-end;
            %  col-start, col-end]
            nrng = [r(:)';c(:)'];
            % Fill with inf for start cell
            nrng(2*numel(rngStr)+1:4) = inf;
            % Force into a row.
            nrng = nrng(:)';
        end
    end
end

function [r,c] = getRC(rng)
% gets the row and column number of each cell.
r = inf(size(rng));
c = inf(size(rng));
try
    % Regexep returns a string, not a cell, for scalar string, so appending
    % "" forces the output to be a cell.
    [cols,rows] = regexp([rng;""],'[a-zA-Z]+','match','split');
    for i = 1:numel(rng)
        col = cols{i};
        row = rows{i};
        
        col(strlength(col)==0) = [];
        assert(numel(col)<=1);
        if ~isempty(col)
            c(i) = matlab.io.spreadsheet.internal.columnNumber(col{:});
        end
        
        row(strlength(row)==0) = [];
        assert(numel(row)<=1);
        if ~isempty(row)
            r(i) = double(row);
        end
    end
catch
    error(message('MATLAB:spreadsheet:sheet:rangeParseInvalid'))
end
end

function cell = getCellName(r,c)
cell = sprintf('%s%d',matlab.io.spreadsheet.internal.columnLetter(c),r);
end