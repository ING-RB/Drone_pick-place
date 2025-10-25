classdef TextConverter
%TEXTCONVERTER converts a text array according to the rules of a variable
%import options object.

% Copyright 2021-2022 The MathWorks, Inc.  

    methods (Static)
        function [convertedData,info] = convert(varopts,textdata,whitespace)
        %CONVERT Converts a text array according to the rules of a variable
        %import options object.
            
            if ischar(textdata)
                % might have a character vector.
                sz = [1 1];
            else
                sz = size(textdata);
                textdata = textdata(:);
            end

            if isa(varopts,'matlab.io.VariableImportOptions')
                varopts = varopts.makeOptsStruct();
            end

            % convert cellstrs to string array
            textdata = convertCharsToStrings(textdata);
            [convertedData, info.Errors, info.Placeholders] = matlab.io.text.internal.datatypeConvertFromString(varopts,textdata,char(whitespace));
            convertedData = reshape(convertFromRaw(varopts,convertedData),sz);
            [fill,convertedData] = matlab.io.internal.processRawFill(varopts.FillValue,convertedData);
            convertedData(info.Errors|info.Placeholders) = fill;

            convertedData = reshape(convertedData,sz);
            info.Errors = reshape(info.Errors,sz);
            info.Placeholders = reshape(info.Placeholders,sz);
        end
    end
end

function finaldata = convertFromRaw(varopts, rawdata)
% converts data from an intermediate form to the final MATLAB Type
switch varopts.Type
    case 'datetime'
        % has Data, and Format if being detected
        finaldata = matlab.io.internal.builders.Builder.processDates(rawdata,varopts.DatetimeFormat,varopts.InputFormat,varopts.TimeZone);
    case 'duration'
        % duration needs convert to seconds
        finaldata = matlab.io.internal.builders.Builder.processTimes(rawdata,varopts.DurationFormat,varopts.InputFormat);
    case 'categorical'
        % can be set categories, or detected
        finaldata = matlab.io.internal.builders.Builder.processCats(rawdata,varopts.Ordinal,varopts.Protected);
    otherwise
        finaldata = rawdata;
end
end