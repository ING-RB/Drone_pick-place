classdef mtree
%MTREE  Create and manipulate M parse trees
%   This is an experimental program whose behavior and interface is likely
%   to change in the future.

% Copyright 2006-2022 The MathWorks, Inc.

    properties (SetAccess='protected', GetAccess='protected', Hidden)
        T    % parse tree array
                 % column 1: kind of node
                 % column 2: index of left child
                 % column 3: index of right child
                 % column 4: index of next node
                 % column 5: position of node
                 % column 6: size of node
                 % column 7: symbol table index (V)R/
                 % column 8: string table index
                 % column 9: index of parent node
                 % column 10: setting node
                 % column 11: lefttreepos
                 % column 12: righttreepos
                 % column 13: true parent
                 % column 14: righttreeindex
                 % column 15: rightfullindex
        S    % symbol table
        C    % character strings
        % The node kind index list of the active (selected) nodes
        % When tree is first constructed, all nodes are active.
        % Possible new name: ActiveSet
        IX

        n    % number of nodes

        % Number of active (selected) nodes
        % Possible new name: ActiveCount
        % m = sum(IX)
        m
        lnos % line number translation
        str  % input string that created the tree
    end
    properties (SetAccess='private', GetAccess='public')
        % The type of the code file represented by the tree
        % This will be one of the values of the mtree.Type
        % enum, such as mtree.Type.ScriptFile, etc.
        FileType
    end
    properties (GetAccess='public', Constant, Hidden)

        % Conceptually, a "map" from node kind index
        % to the node kind name (as a character vector).
        % This is implemented as a cell array which maps indices into values.
        % The inverse "map" is stored in the K property.
        % Possible new name: NodeKindName
        N  = mtree_info(1)

        % Conceptually, a "map" from node kind name to the node kind index.
        % This is implemented as a struct which maps fields into values. 
        % The inverse "map" is stored in the N property.
        % Possible new name: NodeKindIndex
        K  = mtree_info(2)

        KK = mtree_info(3)  % the internal names (for debugging)
        Uop = mtree_info(4) % true if node is a unary op
        Bop = mtree_info(5) % true if node is a binary op
        Stmt = mtree_info(6) % true if node is a statement

        % Conceptually, a "map" from link name (e.g., Ins, Outs, Fname, ...)
        % to the link index.
        % This is implemented as a struct which maps fields into values.
        % Possible new name: LinkIndex
        Linkno = mtree_info(7)

        % Conceptually, a "map" from link index to a navigation path in the tree.
        % The path is returned as a vector of column indices to apply to the tree table. 
        % For example, a path of [3, 4] means to first navigate to the
        % right child (node in column 3 in the tree table),
        % then to the next child (node stored in column 4 in the tree table).
        % This is implemented as a cell array which maps indices into row vectors.
        % Possible new name: LinkToPath
        Lmap = mtree_info(8)

        % Conceptually, a "map" returning true for a pair (link index, node kind index)
        % if and only if the link index is a valid navigation link for that node kind index.
        % For example, the link "Try" is only valid on the "TRY" node kind.
        % This is implemented as a logical matrix.
        % Possible new name: IsValidLinkNodePair.
        Linkok = mtree_info(9)

        PTval = mtree_info(10) % array of nodes whose V is a position value
        V  = { '2.50', '2.50' };   % version array
    end
    methods
        [v1,v2] = version(o)
    end
    methods (Access='protected')
        % housekeeping methods
        L = linelookup( o, P )
    end
    methods
        % CONSTRUCTOR
        function o = mtree( text, varargin )
        %MTREE  o = MTREE( text, options ) constructs an mtree object
        %
        % Options include:
        %     -file:  the text argument is treated as a filename
        %     -comments:   comments are included in the tree
        %     -cell:  cell markers are included in the tree
            try
                [text, args] = validateInput(text, varargin);
            catch E
                throw(E)
            end
            opts = {};
            for i=1:nargin-1
                if strcmp( args{i}, '-file' )
                    try
                        fname = text;
                        text = matlab.internal.getCode(text);
                    catch x
                        error(message('MATLAB:mtree:input', fname));
                    end
                else
                    switch args{i}
                      case '-comments'
                        opts{end+1} = '-com'; %#ok<AGROW>
                      otherwise
                        opts{end+1} = args{i}; %#ok<AGROW>
                    end
                end
            end
            o.str = text;
            [o.T, o.S, o.C, filetype, o.lnos] = mtreemex( text, opts{:} );
            o.FileType = mtree.Type(filetype);
            o = wholetree( o );
        end
        o = wholetree( o )
    end
    methods (Hidden)
        b = eq( o, oo )
        b = ne( o, oo )
        b = le( o, oo )
        o = subtree(o) % Deprecated.
        o = fullsubtree( o ) % Deprecated.
        function o = list(o)
        %LIST  list is deprecated -- use List
            o = List(o);
        end

        function o = full(o)
        %full  full is deprecated -- use wholetree
            o = wholetree(o);
        end
        b = isfull(o) % Deprecated.
    end
    methods
        m = count( o )
        oo = root( o )
        oo = null( o )
    end
    methods (Access='protected',Hidden)
        oo = makeAttrib( o, I )
        [I,ipath,flag,rest] = pathit( o, I, ipath )
        a = restrict( o, ipath, s )
    end
    methods (Hidden)
        function a = path(o, pth )
            %

            %PATH a = PATH( obj, path_string )   Deprecated Mtree -- use mtpath


            a = mtpath( o, pth );
        end
        function s = string( o )
            %

            %STRING str = STRING( o )  return a string for an Mtree node


            % o must be a single element set -- returns the string
            % an error if count(o)~=1 or the node does not have a string
            i = find( o.IX );
            if length(i)~=1
                error(message('MATLAB:mtree:string'));
            end
            i = o.T(i,8);
            if i==0
                error(message('MATLAB:mtree:nostring'));
            end
            s = o.C{i};
        end
        function c = strings( o )
            %

            %STRINGS  c = STRINGS( obj ) return the strings for the Mtree obj


            c = cell( 1, o.m );
            SX = o.T( o.IX, 8 );  % string indices
            J = (SX==0);  % elements with no strings
            [c(J)] = {''};
            [c(~J)] = o.C(SX(~J));
        end
        function a = find( o, varargin )
            %

            %FIND   Deprecated Mtree method -- use mtfind
            % deprecated, because code analysis report checks argument count


            a = mtfind( o, varargin{:} );
        end
    end
    methods
        a = mtpath(o, pth )
        c = stringvals( o )
        s = stringval( o )
        a = mtfind( o, varargin )
        o = sets( o )
    end
    methods   % methods for following paths...
        o = Left(o)
        o = Arg(o)
        o = Try(o)
        o = Attr(o)
        o = Right(o)
        o = Body(o)
        o = Catch(o)
        o = CatchID(o)
        o = Next(o)
        o = Parent(o)
        o = Outs(o)
        o = Index(o)
        o = Cattr(o)
        o = Vector(o)
        o = Cexpr(o)
        o = Ins(o)
        o = Fname(o)
        o = lhs( o )
        o = previous( o )
        oo = first( o )
        o = last( o )
    end

    properties(Dependent)
        Arguments;
        ArgumentInitialization;
        ArgumentValidation;
        VarName;
        VarNamedClass;
        VarNamedField;
        VarType;
        VarDimensions;
        VarValidators;
    end

    methods
        function argument = get.Arguments(o)
            argument = navigate(o, o.Linkno.Arguments);
        end
        function init = get.ArgumentInitialization(o)
            init = navigate(o, o.Linkno.ArgumentInitialization);
        end
        function type = get.ArgumentValidation(o)
            type = navigate(o, o.Linkno.ArgumentValidation);
        end
        function name = get.VarName(o)
            name = navigate(o, o.Linkno.VarName);
        end
        function namedClass = get.VarNamedClass(o)
            namedClass = navigate(o, o.Linkno.VarNamedClass);
        end
        function namedField = get.VarNamedField(o)
            namedField = navigate(o, o.Linkno.VarNamedField);
        end
        function type = get.VarType(o)
            type = navigate(o, o.Linkno.VarType);
        end
        function dims = get.VarDimensions(o)
            dims = navigate(o, o.Linkno.VarDimensions);
        end
        function vals = get.VarValidators(o)
            vals = navigate(o, o.Linkno.VarValidators);
        end
    end

    methods(Access=private, Hidden)
        function o = navigate(o, linkIndex)
        % navigate the tree on the link
        % link is a named way to traverse the tree from certain nodes,
        % e.g. Ins for FUNCTION node, VarName for PROPTYPEDECL node.

            % Get the path for the link using the map,
            % which is a series of Left(2), Right(3), Next(4)
            path = o.Lmap{linkIndex};

            % Navigate the first step.
            % T is the tree table, IX is the current selected nodes.
            step = path(1);
            childIndex = o.T( o.IX, step);

            % The active set in the tree may contain nodes for which the linkIndex 
            % is not valid. Restrict ourselves to the subset of the active set
            % where the link is valid and the child exists.
            isValid = o.Linkok( linkIndex, o.T( o.IX, 1 ) ) & (childIndex~=0)';
            childIndex = childIndex(isValid);
            % Navigate the remaining steps. We know all subsequent steps in the path
            % will be valid, so we only need to guard against non-existing children.
            for step = path(2:end)
                childIndex = o.T(childIndex, step);
                childIndex = childIndex(childIndex ~= 0);
            end
            % Reset and update the selected nodes.
            o.IX(o.IX) = false;
            o.IX(childIndex)= true;
            o.m = length(childIndex);
        end
    end

    methods
        oo = setter( o )
    end
    methods (Hidden)
        % Low-level methods that are used for testing or special purposes
        % and will not be documented.
        b = sametree( o, oo )
        oo = rawset( o )
        T = newtree( o, varargin )
        s = getpath( o, r )

        function o = L(o)
        %L  o = L(o)  Raw Left operation

        % fast for single nodes...
            J = o.T( o.IX, 2 );
            J = J(J~=0);
            o.IX(o.IX) = false;
            o.IX(J)= true;
            o.m = length(J);
        end

        function o = R(o)
        %R  o = R(o)  Raw Right operation
            J = o.T( o.IX, 3 );
            J = J(J~=0);
            o.IX(o.IX) = false;
            o.IX(J)= true;
            o.m = length(J);
        end

        function o = P(o)
        %P  o = P(o)  Raw Parent operation
            J = o.T( o.IX, 9 );
            J = J(J~=0);
            o.IX(o.IX) = false;
            o.IX(J)= true;
            o.m = length(J);
        end

        function o = X(o)
        %X  o = X(o)  Raw Next operation
            J = o.T( o.IX, 4 );
            o.m = o.m - sum( J==0 );
            J = J(J~=0);
            o.IX(o.IX) = false;
            o.IX(J)= true;
        end

        o = or( o, o2 )
        o = and( o, o2 )
        o = not( o )
        o = minus( o, o2 )
    end
    methods
        oo = allsetter( o, o2 ) % Deprecated.
        oo = anysetter( o, o2 ) % Deprecated.
        disp(o)
        show(o)
        dump(o)  % Deprecated.
        dumptree(o)
        rawdump(o)

        o = List( o )
        o = Full( o )
        o = Tree( o )
        oo = asgvars( o )
        oo = geteq( o )
        oo = dominator( o )
        ooo = dominates( oo, o )
        b = isbop( o )
        b = isuop( o )
        b = isop( o )
        b = isstmt( o )
        o = ops( o )
        o = bops( o )
        o = uops( o )
        o = stmts( o )
        o = operands( o )
        oo = depends( o )
        o = setdepends( o )
        o = growset( o, fh )
        o = fixedpoint( o, fh )
        L = lineno( o )
        C = charno( o )
        P = position( o )
        [l,c] = pos2lc( o, pos )
        pos = lc2pos( o, l, c )
        EP = endposition( o )
        LP = leftposition(o)
        RP = rightposition(o)
        RP = righttreepos(o)
        LP = lefttreepos(o)
        RP = righttreeindex(o)
        RP = rightfullindex(o)
        oo = trueparent(o)
        b = isempty( o )
        b = isnull( o )
        a = kinds( o )
        a = kind( o )
        b = iskind( o, kind )
        b = anykind( o, kind )
        b = allkind( o, kind )
        b = isstring( o, strs )
        b = allstring( o, strs )
        b = anystring( o, strs )
        b = ismember( o, a )
        b = allmember( o, a )
        b = anymember( o, a )
        o = select( o, ix )
        ln = getlastexecutableline( o )
        [ln,ch] = lastone( o )
        n = nodesize( o )
        I = indices(o)
        b = iswhole( o )
        s = tree2str( S, varargin )
    end
    methods % (Hidden)
            % these methods are only for the very well informed...
            % I wanted to make them protected and Hidden, but the Simulink
            % dependency analysis test explicitly tests for this method
            % being visible.  TODO: track down why this is so....

        o = setIX( o, I )
        I = getIX( o )
    end
    methods (Access=protected,Hidden)
        chk( o )
    end
end

function [file, args] = validateInput(file, args)
    if nargin == 0 || ~(ischar(file) || (isstring(file) && isscalar(file)))
        error(message('MATLAB:mtree:usage'));
    end

    if isstring(file)
        file = char(file);
    end

    for idx=1:length(args)
        if(isstring(args{idx}) && isscalar(args{idx}))
            args{idx} = char(args{idx});
        elseif(isstring(args{idx}) && ~isscalar(args{idx}))
            args{idx} = cellstr(args{idx}); 
        end
    end    
end
