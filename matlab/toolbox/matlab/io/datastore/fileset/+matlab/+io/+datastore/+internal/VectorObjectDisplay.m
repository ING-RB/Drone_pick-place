classdef VectorObjectDisplay
%VECTOROBJECTDISPLAY Parent class for table-like objects
%   This class implements methods required for objects that require
%   table-like behavior in terms of indexing, display, concatenation,
%   assignment.

%   Copyright 2019-2020 The MathWorks, Inc.
    methods (Hidden)
        function displayInfo(~, T)
            % Render the table display into a string.
            fh = feature('hotlinks');
            if fh
                disp(T);
            else
                % For no desktop, use hotlinks off on evalc to get rid of
                % xml attributes for display, like, <strong>Var1</strong>, etc.
                disp(evalc('feature hotlinks off; disp(T);'));
                feature('hotlinks', fh);
            end
        end

        % Overload definition of numel
        function n = numel(obj, varargin)
            n = getSize(obj);
        end

        % Overload definition of size
        function [m, n] = size(obj, dim)
            if nargin == 1
                dim = [];
            else
                % check that the indices provided are correct
                throwSizeIndexingError(obj, dim);
            end
            % get size of object
            m = getSize(obj);
            n = 1; % constant value

            % only queried one of the size dimensions
            if dim == 1
                n = [];
            elseif dim == 2
                m = [];
            end

            % based on number of outputs asked
            if nargout == 0 || nargout == 1
                m = [m, n];
            end
        end

        % Overload definition of length
        function n = length(obj)
            n = getSize(obj);
        end

        % Overload definition of cat
        function C = cat(dim, varargin)
            if dim == 1
                fields = fieldnames(varargin{1});
                C = cell(numel(fields),1);
                for ii = 1 : numel(fields)
                    for jj = 1 : numel(varargin)
                        C{ii} = [C{ii}; varargin{jj}.(fields{ii})];
                    end
                end
                C = constructObj(varargin{1},C);
            else
                error(message("MATLAB:datastoreio:dsfileset:noHorzcat",class(obj1)));
            end
        end

        % Overload definition of subsasgn
        function out = subsasgn(obj, ~, ~) %#ok<STOUT>
            error(message("MATLAB:datastoreio:dsfileset:noSubsasgn",class(obj)));
        end

        % Overload definition of horzcat
        function C = horzcat(obj1, ~) %#ok<STOUT>
            error(message("MATLAB:datastoreio:dsfileset:noHorzcat",class(obj1)));
        end

        % Overload definition of vertcat
        function C = vertcat(varargin)
            C = cat(1, varargin{:});
        end

        % Overloaded definition of end 
        function n = end(obj,~,~)
            n = getSize(obj);
        end

        % Overloaded definition of numArgumentsFromSubscript
        function n = numArgumentsFromSubscript(~,~,~)
            % Always returns 1
            n = 1;
        end
    end

    methods (Hidden, Abstract)
        % Clients have to implement getSize
        n = getSize(obj);
        throwSizeIndexingError(obj, dim);
    end

    methods (Access = protected)
        function buildHeader(obj, className)
            dims = matlab.internal.display.dimensionString(obj);
            if matlab.internal.display.isHot
                fontType = 'style="font-weight:bold"';
                out = [dims, ' <a href="matlab:helpPopup ' ,class(obj), ...
                    '" ', fontType, '>', className, '</a>'];
            else
                out = [dims,' ',className];
            end
            out = [char(32), char(32), out];
            fprintf(out); 
            fprintf(newline);
        end
    end
end