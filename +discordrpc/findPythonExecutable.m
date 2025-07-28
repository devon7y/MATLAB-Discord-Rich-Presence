% This function attempts to locate the Python executable on the system.
% It checks for the Python environment configured in MATLAB and then searches
% common system paths for 'python3' or 'python'.
% Author: Devon Yanitski and Gemini CLI 0.1.13

function [executable, isFound] = findPythonExecutable()
    % findPythonExecutable - Locates the Python executable using multiple methods.
    try
        env = pyenv;
        if ~isempty(env.Executable) && isfile(env.Executable)
            executable = env.Executable;
            isFound = true;
            return;
        end
    catch
    end

    if ismac || isunix
        commands = {'python3', 'python'};
        search_cmd = 'which';
    else
        commands = {'python.exe', 'python3.exe'};
        search_cmd = 'where';
    end

    for i = 1:length(commands)
        [status, result] = system([search_cmd ' ' commands{i}]);
        if status == 0
            executable = strsplit(strtrim(result), '\n');
            executable = executable{1};
            isFound = true;
            return;
        end
    end

    executable = '';
    isFound = false;
end