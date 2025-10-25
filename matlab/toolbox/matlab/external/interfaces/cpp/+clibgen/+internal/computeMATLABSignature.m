function sig = computeMATLABSignature(fcnName, args, output, combinationCountMultipleMlTypes)
%

%   Copyright 2018-2020 The MathWorks, Inc.
if combinationCountMultipleMlTypes == 1
    
    inputs = "";
    outputs = "";
    if not (isempty(output))
        outputs(end+1) = output.MATLABType;
    end
    for argument=args
        if not(argument.IsHidden)
            % Walk through arguments and compute the MATLAB signature
            if(argument.Direction == "input")
                inputs(end+1) = argument.MATLABType; %#ok<*AGROW>
            elseif(argument.Direction == "output")
                outputs(end+1) = argument.MATLABType;
            else
                % argument is inputandoutput
                inputs(end+1) = argument.MATLABType;

                outputs(end+1) = argument.MATLABType;
            end
        end
    end
    if (numel(inputs)==1)
        inputs = "()";
    elseif (numel(inputs) > 1)
        inputs = "(" + inputs(2:end).join(",") + ")";
    end
    if (numel(outputs)==2)
        outputs = outputs(2) + " ";
    elseif (numel(outputs)>2)
        outputs = "[" + outputs(2:end).join(",") + "]" + " ";
    end
    sig = outputs + fcnName + inputs;
else
    % if it has multiple MlTypes for void* input
    [argCombinations] = clibgen.internal.argumentCombinations(args,"", 1, {});
    sig = [];
    inputs = "";
    outputs = "";
    for i= 1:numel(argCombinations)
        inputsList = argCombinations(i);
        inputsList = inputsList{1};
        if not (isempty(output))
            outputs(end+1) = output.MATLABType;
        end
        for j = 1:numel(args)
            argument = args(j);
            if not(argument.IsHidden)
                % Walk through arguments and compute the MATLAB signature
                if(argument.Direction == "input")
                    inputs(end+1) = inputsList(j+1); %#ok<*AGROW>
                elseif(argument.Direction == "output")
                    outputs(end+1) = inputsList(j+1);
                else
                    % argument is inputandoutput
                    inputs(end+1) = inputsList(j+1);

                    outputs(end+1) = inputsList(j+1);
                end
            end
        end
        if (numel(inputs)==1)
            inputs = "()";
        elseif (numel(inputs) > 1)
            inputs = "(" + inputs(2:end).join(",") + ")";
        end
        if (numel(outputs)==2)
            outputs = outputs(2) + " ";
        elseif (numel(outputs)>2)
            outputs = "[" + outputs(2:end).join(",") + "]" + " ";
        end
        sigIndividual = outputs + fcnName + inputs;

        sig = [sig sigIndividual];
    end
end