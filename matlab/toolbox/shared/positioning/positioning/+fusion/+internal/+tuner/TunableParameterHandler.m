classdef TunableParameterHandler 
%   This class is for internal use only. It may be removed in the future. 
%TUNABLEPARAMETERHANDLER Handle TunableParameter property of tunerconfig
%   This class contains static methods for validating the TunableParameter
%   property. It also contains an expand() method for converting
%   TunableParameters into a form suitable for the tune() function.

%   Copyright 2021 The MathWorks, Inc.      

   methods (Static)
       
       function validateTunableParametersFully(tunableParameters, allowedNames, filterparams)
           % Deep validation of TunableParameters for form and content
           fusion.internal.tuner.TunableParameterHandler.validateForm(tunableParameters);
           fusion.internal.tuner.TunableParameterHandler.validateParams(tunableParameters, allowedNames);
           fusion.internal.tuner.TunableParameterHandler.validateIndices(tunableParameters, filterparams);
       end
       
       function validateForm(tp)
           % Validation on the form of TunableParameters 
           % Allowed:
           %    String array of noise names
           %    Cell array of char vectors and/or strings of noise names 
           %    Cell array of char vectors and/or strings of noise names and
           %        nested 1-by-2 cell arrays of {noise, index array} pairs
            if isstring(tp)
                % string array is fine
            elseif iscell(tp)
                % Can be a single level cell array or a cell array with
                % nested 1-by-2 cell arrays
                n = numel(tp);
                for ii=1:n
                    e = tp{ii};
                    if ischar(e) || isStringScalar(e) 
                        % fine
                    elseif iscell(e)
                        assert(numel(e) == 2, ...
                            message('shared_positioning:tuner:TunableParametersForm'));
                        e1 = e{1};
                        e2 = e{2};
                        assert(ischar(e1) || isStringScalar(e1), message('shared_positioning:tuner:TunableParametersForm'));
                        assert(isvector(e2), message('shared_positioning:tuner:TunableParametersForm'));
                        assert(isnumeric(e2), message('shared_positioning:tuner:TunableParametersIndices'));
                        assert(all(isfinite(e2), 'all'), message('shared_positioning:tuner:TunableParametersIndices'));
                        assert(all(isreal(e2), 'all'), message('shared_positioning:tuner:TunableParametersIndices'));
                        assert(all(e2 > 0, 'all'), message('shared_positioning:tuner:TunableParametersIndices'));
                        assert(isequal(round(e2), e2), message('shared_positioning:tuner:TunableParametersIndices'));
                    else
                        error(message('shared_positioning:tuner:TunableParametersForm'));
                    end
                 end
            else
                error(message('shared_positioning:tuner:TunableParametersForm'));
            end

       end
       function validateParams(tp, allowedParams)
           % Ensure that all parameters in TunableParameters (tp) are
           % in the allowed set and are not repeated.
           % Assumes: validateForm has passed
           if isstring(tp)
               tpc = cellstr(tp);
           else
               tpc = tp;
           end
           isUsed = false(size(allowedParams));
           for ii=1:numel(tp)
                p = getProp(tpc{ii});
                found = ismember(allowedParams, p);
                assert(any(found), ...
                    message('shared_positioning:tuner:InvalidTunableParameter',p));
                assert(any(found & ~isUsed), ...
                    message('shared_positioning:tuner:ReusedTunableParameters', p));
                isUsed = isUsed | found;
           end
       end
       function validateIndices(tp, filt)
           %Ensure all indices in TunableParameters tp are in range.
           %validateForm has ensured that any which are present are
           %integers
           % Assumes: validateForm and validateParams have passed

           % no validation needed if string array because those can't have
           % indices
           if iscell(tp) 
               for ii=1:numel(tp)
                   if iscell(tp{ii})
                       p = tp{ii}{1};
                       idx = tp{ii}{2};
                       default = filt.(p);
                       assert(all(idx <= numel(default)), message('shared_positioning:tuner:TunableParametersIndexRange', p));
                   end
               end
           end
       end
       function [params, indices, numparams] = expand(tp)
            % Expand TunableParameters to account for indices
            %   TunableParameters can be of the forms:
            %       ["foo", "bar"]
            %       {'foo', 'bar'}
            %       {"foo", 'bar'}   % mixed in strings
            %       { {"foo", [1 2 3]}, 'bar'} % specify indices. Again strings or chars
            %   Produce:
            %       params = ["foo", "foo", "foo", "bar"]  - strings   
            %       indices = (1, 2, 3, -1) - an array 
            %           % a -1 signifies "tune the whole array as one"
            %       numparams = 4
            N = numel(tp);
            if isstring(tp)
                params = tp;
                numparams = N;
                indices = repmat(-1, 1,N);
            else % cell array
                % Figure out numparams first.
                numparams = 0;
                for ii=1:N
                    e = tp{ii};
                    numparams = numparams + countindices(e);
                end
                indices = zeros(1,numparams);
                params = strings(1,numparams);
                cnt = 1; 
                for ii=1:N
                    e = tp{ii};
                    if iscell(e)
                        idx = e{2};
                        cntinc = numel(idx); 
                        indices(cnt:cnt + cntinc -1) = idx; 
                        params(cnt:cnt + cntinc -1) = e{1};
                    else % no indices
                        cntinc = 1;
                        indices(cnt) = -1; 
                        params(cnt) = e;
                    end
                    cnt = cnt + cntinc;
                end
            end
       end
   end
end

function p = getProp(e)
% Extract a parameter name from an element of TunableParameters, regardless
% of form. Here e is a single indexed element of TunableParameters 
% (i.e. tp{ii} or tp(ii)
%
% Assumes: validateForm has passed
    if isstring(e) || ischar(e)
        p = e;
    elseif iscell(e)
        p = e{1};
    end
end

function c = countindices(e)
% For a given element of TunableParameters, count how many indices it holds
if iscell(e)
    c = numel(e{2});
else
    c = 1; 
end

end
