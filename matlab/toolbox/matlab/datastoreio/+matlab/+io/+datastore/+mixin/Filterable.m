classdef Filterable < handle
    %Filterable   Common mixin class for datastores that use a RowFilter property.

    %   Copyright 2021 The MathWorks, Inc.

    properties
        %RowFilter   matlab.io.RowFilter instance used for filtering rows while
        %         reading a Parquet file.
        %
        %   Example:
        %
        %     % Make a ParquetDatastore on the airlinesmall dataset:
        %     pds = parquetDatastore("airlinesmall.parquet");
        %
        %     % Define a Filter for a specific date range.
        %     rf = rowfilter("Date");
        %     filter = rf.Date > datetime("2007-06-02");
        %
        %     % Apply the date range filter to the datastore.
        %     pds.RowFilter = filter;
        %
        %     % Read all rows in the Parquet file matching the filter
        %     % condition.
        %     data = readall(pds);
        %
        %   See also parquetread, rowfilter
        RowFilter(1, 1) matlab.io.RowFilter = rowfilter(missing);
    end

    methods
        function set.RowFilter(ds, filter)
            try
                validateScalarFilter(filter);

                validateFilterProperties(ds, filter);

                originalFilter = ds.RowFilter;
                ds.RowFilter = filter;

                % The default filtering case only happens early during
                % construction and during loadobj. Neither of these require
                % a reset().
                isFromDefaultFilter = isequaln(originalFilter, rowfilter(missing));
                % Avoid calling reset() if the RowFilter did not change.
                % This avoids some issues on loadobj.
                isSameRowFilter = isequaln(originalFilter, filter);

                if isSameRowFilter || isFromDefaultFilter
                    return;
                end

                resetDatastoreOnFilterUpdate(ds);
            catch ME
                throwAsCaller(ME);
            end
        end
    end

    methods (Access = protected)
        function resetDatastoreOnFilterUpdate(ds)
            ds.reset();
        end
    end

    methods (Access = protected, Abstract)
        %validateFilterProperties   Called by the Filter setter every time a
        %   new RowFilter object is set on the datastore.
        %
        %   Subclasses of matlab.io.datastore.mixin.Filterable must
        %   implement this method to verify that the Filter doesn't have any
        %   incorrect table variable names.
        validateFilterProperties(ds, filter);
    end

    methods (Static, Access = protected)
        function configureInputParserForFilter(inputParser)
            %configureInputParser adds rules for parsing
            % RowFilter from an input parser object.
            addParameter(inputParser, "RowFilter", rowfilter(missing), ...
                @validateScalarFilter);
        end
    end
end

function validateScalarFilter(filter)
%validateScalarFilter   validates that the input has the right datatype and
%   size.

validateattributes(filter, "matlab.io.RowFilter", "scalar", string(missing), "RowFilter");
end