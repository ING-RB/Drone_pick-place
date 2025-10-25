function [sCoder,sData] = cstructname(sData,vszfields,structName,headerName)
%This function is for internal use only. It may be removed in the future.
%
%cstructname Generate struct with varsize fields for codegen+builtins
%
%   This utility allows one to generate codegen-compatible types for
%   structs containing varsize fields without making copies of the
%   underlying data-structure. This requires a two step process:
%
%   [SCODER,SDATA] = cstructname(SDATA,VSZFIELDS,STRUCTNAME,HEADERNAME)
%   convert the struct-array, SDATA, to a codegen-compatible array with
%   raw-pointers to the data inside fields. VSZFIELDS is a cell-array of
%   char-arrays denoting the fields in SDATA that are varsize, and
%   STRUCTNAME is the desired name of the generated struct typedef. Upon
%   generating code, a new struct definition will be placed inside
%   <entrypoint_fcn>_types.hpp.
%
%   [SCODER,SDATA] = cstructname(___,HEADERNAME) once this tool has been
%   used to generate a struct typedef, e.g. MyStructDef, copy the
%   definition to a desired external header, corresponding to HEADERNAME,
%   and update the call "cstructname(___)"->"cstructname(___,HEADERNAME)"
%
%   Example:
%
% % 1) Create entrypoint struct with varsize fields and generate code
%    % Create struct with varsize elements
%    nx3 = coder.typeof(0,[inf,3]);
%    nx1 = coder.typeof(0,[inf,1]);
%    sElem     = struct("A",nan,"B",rand(10,3),"C",rand(15,1));
%    sElemType = struct("A",0,"B",nx3,"C",nx1);
%
%    % Create array and input to entry-point
%    sData = repmat(sElem,5,1);
%    cgInput = coder.typeof(sElemType,[inf 1]);
%
% % See also nav.geometry.internal.coder.cstructname/genType
%    % Generate types
%    codegen('genType','-args',cgInput);
%
% % 2) Copy the typedef for 'MyStruct' from the generated code to a
% %    custom header, e.g. "genType_types.hpp" -> 'PregenTypes.hpp'
%
% % 3) Use the custom header/struct and verify it works
%
% % See also nav.geometry.internal.coder.cstructname/usePregenType
%    % Call external C-code which that structs with varsize fields
%    codegen('usePregenType','-args',cgInput);
%
%    % Verify it works
%    val0 = sData(1).B(1);
%    [sData,n_B] = usePregenType_mex(sData);
%    assert(n_B == size(sData(1).B,1));  % Verify num rows was passed correctly
%    assert(sData(1).B(1) == val0+10);   % Verify data was modified
%
%
%   Copyright 2023 The MathWorks, Inc.

%#codegen

    arguments
        sData (:,1) {mustBeA(sData,'struct')}
        vszfields (1,:) {mustBeA(vszfields,'cell')}
        structName (1,1) string
        headerName = []
    end

    % Avoid copies
    coder.internal.reference_parameter(sData);
    coder.inline('never');

    % Determine varsize fields
    names = fieldnames(sData);
    nElem = numel(sData);
    nField = numel(names);
    isvarsz = false(nField,1);
    for i = 1:nField
        isvarsz(i) = any(strcmp(names{i},vszfields));
    end

    % Add dimension fields to struct. Use cell-array -> struct to support
    % incremental struct creation
    val = cell(2,nField+nnz(isvarsz));
    icell = 1;
    for i = 1:nField
        if isvarsz(i)
            val{1,icell} = names{i};
            val{1,icell+1} = ['N_' names{i}];
            val{2,icell} = coder.nullcopy(coder.opaque([class(sData(1).(names{i})) '*'],'NULL'));
            val{2,icell+1} = uint64(0);
            icell = icell+2;
        else
            val{1,icell} = names{i};
            val{2,icell} = coder.nullcopy(sData(1).(names{i}));
            icell = icell+1;
        end
    end

    % Create the struct
    sCoder = repmat(struct(val{:}),nElem,1);
    if isempty(headerName)
        % Use this to generate the codegen struct, which will be placed in
        % the <entrypoint>_types.hpp. Then manually add to desired header
        coder.cstructname(sCoder,structName);
        coder.ceval('//');
    else
        % Coder expects to find a previously generated type for sCoder in
        % headerName. Use this syntax once you have already generated the
        % typedef
        coder.cstructname(sCoder,structName,'extern','HeaderFile',headerName);
    end

    % Convert the input struct to one that passes dynamic arrays as raw
    % data pointers
    for i = 1:nElem
        for n = 1:numel(names)
            if isvarsz(n)
                [sCoder(i).(names{n}),sData(i).(names{n})] = getPointer(sData(i).(names{n}));
                sCoder(i).(['N_' names{n}]) = uint64(size(sData(i).(names{n}),1));
            else
                sCoder(i).(names{n}) = sData(i).(names{n});
            end
        end
    end
end

function [ptr,vszField] = getPointer(vszField)
%getPointer Use ceval to retrieve the raw pointer from varsize array
    coder.internal.reference_parameter(vszField);
    coder.inline('never');
    cls = class(vszField);
    ptr = coder.opaque([cls '*'],'NULL');
    ptr = coder.ceval(['(' cls '*)'],coder.ref(vszField));
end

%% Example Helpers:

% Step 1) Generate struct typedef, will be found in genType_types.hpp
function sData = genType(sData) %#ok<DEFNU>
%genType Code to generate type for sData

% Convert sData to codegen-stable representation
    [sCoder,sData] = nav.geometry.internal.coder.cstructname(...
        sData,{'B','C'},'MyStruct');

    % Pass raw struct representation to C-function by reference, this
    % ensures the type is created
    coder.ceval('MyStruct* a = ',coder.ref(sCoder));
end

% Step 2) Copy struct definition to custom header, e.g. a builtin header

% Step 3) Use pre-generated type in codegen
function [sData,nrow_B] = usePregenType(sData) %#ok<DEFNU>
%usePregenType Use the previously generated 'MyStruct' typedef

% Include custom header
    coder.cinclude('PregenTypes.hpp');

    % Convert sData to codegen-stable representation, with definition found
    % in 'PregenTypes.hpp'
    [sCoder,sData] = nav.geometry.internal.coder.cstructname(...
        sData,{'B','C'},'MyStruct','PregenTypes.hpp');

    % Create reference to struct in C-code
    coder.ceval('MyStruct* s = &',coder.ref(sCoder));

    % Query and modify the struct.
    % WARNING: changes to sCoder should be reflected in sData, so be careful!
    nrow_B = uint64(nan);
    nrow_B = coder.ceval('s[0].N_B; //');
    coder.ceval('s[0].B[0] += 10; //');
end
