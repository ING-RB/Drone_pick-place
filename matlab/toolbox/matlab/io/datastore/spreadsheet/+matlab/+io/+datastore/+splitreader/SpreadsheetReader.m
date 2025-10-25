classdef SpreadsheetReader < matlab.io.datastore.splitreader.SplitReader
%SPREADSHEETREADER SpreadsheetReader for reading spreadsheet files

%   Copyright 2015-2024 The MathWorks, Inc.
    
    properties
        Split
    end
    
    properties (Transient, Access = 'private')
        SizeRead = 0       % size currently read from the split        
        %REMOTETOLOCALOBJ
        % Hold on to the local file from remote until delete.
        % This will be used if there's an error in the file and we don't have
        % to download again.
        RemoteToLocalObj = []
    end
    
    methods
        function rdr = SpreadsheetReader()
            % split must be initialized before use.
            rdr.Split = [];
        end
        
        function tf = hasNext(rdr)
            %HASNEXT Return logical scalar indicating availability of data
            tf = ~isempty(rdr.Split) && rdr.SizeRead < rdr.Split.Size;
        end
        
        function [data, info] = getNext(rdr)
            % Return "data" and "info" read while iterating over the split
            split = rdr.Split;

            % return the file name as the data
            import matlab.io.datastore.mixin.RemoteToLocalFile;
            import matlab.io.internal.common.validators.isGoogleSheet
            if isGoogleSheet(rdr.Split.Filename)
                rdr.RemoteToLocalObj = [];
                data = rdr.Split.Filename;
            else
                rdr.RemoteToLocalObj = RemoteToLocalFile(rdr.Split.Filename);
                data = rdr.RemoteToLocalObj.LocalFileName;
            end

            % populate the info struct
            info = struct('Filename', split.Filename, 'FileSize', split.FileSize);            

            % the entire split has been returned for conversion
            rdr.SizeRead = split.Size;
        end
        
        function reset(rdr)
            % All SplitReaders must check if the current split's
            % Filename is valid, in case the file is deleted inadvertently.
            [~] = matlab.io.datastore.internal.pathLookup(rdr.Split.Filename);
            rdr.SizeRead = 0;
        end
        
        function frac = progress(rdr)
            frac = 1;
            if (rdr.SizeRead == 0)
                frac = 0;
            end
        end
    end
    
    methods (Access = 'protected')
        function rdrCopy = copyElement(rdr)
           % make a shallow copy of all properties
           rdrCopy = copyElement@matlab.mixin.Copyable(rdr);           
        end
    end
end
