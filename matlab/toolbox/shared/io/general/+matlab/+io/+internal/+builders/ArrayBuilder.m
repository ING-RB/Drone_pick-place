classdef (AllowedSubclasses = {?matlab.io.internal.builders.CellBuilder}) ArrayBuilder...
        < matlab.io.internal.builders.Builder
% ARRAYBUILDER constructs an array based on the data read from a tabular
% text file.

%   Copyright 2019 The MathWorks, Inc. 
    methods
        function data = build(builder, reader, data_untreated, omit_rows, omit_vars)
        % BUILD Constructs and returns an array from the untreated data.

            % get the options for the selected IDS
            varopts = reader.Options.fast_var_opts;
            vartypes = varopts.Types;
            if ~isempty(vartypes) && ~isempty(reader.SelectedIDs)
                if isempty(data_untreated)
                    data = double.empty(0, numel(reader.SelectedIDs));
                else
                    matdata = data_untreated{1};

                    data = matdata.rawdata;
                    firstVarOpts = varopts.getVarOptsStruct(reader.SelectedIDs(1));
                    firstVarOpts = firstVarOpts{1};
                    if matdata.hasExtraCols
                        extracols = matlab.io.internal.builders.Builder.processExtra(data_untreated{2},...
                            matdata.n, firstVarOpts.FillValue, firstVarOpts);
                    else
                        extracols = [];
                    end
    
                    dates = strcmp(vartypes, 'datetime');
                    cats = strcmp(vartypes, 'categorical');
                    times = strcmp(vartypes, 'duration');
                    
                    if all(dates)                   
                        data = matlab.io.internal.builders.Builder.processDates(data,...
                            firstVarOpts.DatetimeFormat, firstVarOpts.InputFormat, firstVarOpts.TimeZone);
                    elseif all(cats)
                        data = matlab.io.internal.builders.Builder.processCats(data,...
                            firstVarOpts.Ordinal, firstVarOpts.Protected);
                    elseif all(times)
                        data = matlab.io.internal.builders.Builder.processTimes(data,...
                            firstVarOpts.DurationFormat,firstVarOpts.InputFormat);
                    end

                    data = builder.shapedata(reader,data,matdata,extracols,matdata.hasExtraCols);
                end

                % Remove omitted rows and vars
                data = matlab.io.internal.builders.Builder.removeOmittedRowsAndVars(data,...
                omit_rows, omit_vars);
            else
                data = [];
            end
            

        end
    end
    
    methods(Access = protected)
        function data = shapedata(~, parser,rawdata,matdata,extracols,hasExtra)
        % SHAPEDATA reshapes the data into the appropriate size and adds
        % any extra columns if necessary.
        
            assert(matdata.m > 0, 'Must be called with non-zero columns'); 
            data = reshape(rawdata,matdata.m,matdata.n).';
            if strcmp(parser.Options.ExtraColumnsRule,'addvars') && hasExtra
                data = [data extracols];
            end
        end 
    end
end


