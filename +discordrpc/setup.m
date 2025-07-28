function setup()
    % SETUP - Configures the Discord Rich Presence integration.

    % --- Python Executable Check ---
    [pythonExecutable, isFound] = discordrpc.findPythonExecutable();
    if ~isFound
        warning('Python could not be automatically detected.');
        fprintf('Please configure the Python interpreter for MATLAB using the pyenv command.\n');
        fprintf('Example: pyenv(''Version'', ''/path/to/python'');\n');
        fprintf('See MATLAB documentation for ''pyenv'' for more details.\n');
        return;
    end
    fprintf('Python executable found: %s\n', pythonExecutable);

    % --- pypresence Library Check ---
    if ~isPypresenceInstalled(pythonExecutable)
        fprintf('The ''pypresence'' library is required for Discord integration.\n');
        choice = input('Would you like to attempt to install it now? (y/n): ', 's');
        if strcmpi(choice, 'y')
            if ~installPypresence(pythonExecutable)
                fprintf('Setup cannot continue until pypresence is installed.\n');
                return;
            end
        else
            fprintf('Please install it manually and run setup again.\n');
            return;
        end
    end
    fprintf('pypresence library is installed.\n');

    % --- startup.m Configuration ---
    if ~configureStartup()
        return;
    end

    % --- finish.m Configuration ---
    if ~discordrpc.configureFinish()
        return;
    end

    fprintf('Setup complete! Discord Rich Presence will start automatically the next time you open MATLAB.\n');
end



function isInstalled = isPypresenceInstalled(pythonExecutable)
    [status, ~] = system(sprintf('"%s" -m pip show pypresence', pythonExecutable));
    isInstalled = (status == 0);
end

function success = installPypresence(pythonExecutable)
    fprintf('Installing pypresence...\n');
    [status, result] = system(sprintf('"%s" -m pip install pypresence', pythonExecutable));
    
    if status == 0
        fprintf('pypresence installed successfully.\n');
        success = true;
        return;
    end

    % --- Installation Failed ---
    fprintf('\n-------------------- PIP INSTALLATION FAILED --------------------\n');
    fprintf('The automatic installation of the ''pypresence'' library failed.\n');
    fprintf('This is common on systems that protect the default Python environment.\n\n');
    
    fprintf('Pip Error Details:\n');
    disp(result);
    
    fprintf('------------------------- ACTION REQUIRED -------------------------\n');
    fprintf('To fix this, please perform the following steps:\n');
    fprintf('1. Open a new Terminal (on macOS/Linux) or Command Prompt (on Windows).\n');
    fprintf('2. Copy and paste the following command into the terminal and press Enter:\n\n');
    fprintf('   %s -m pip install pypresence --break-system-packages\n\n', pythonExecutable);
    fprintf('3. After the command completes successfully, return to MATLAB and run the setup again to complete the configuration:\n\n');
    fprintf('   discordrpc.setup()\n\n');
    fprintf('-----------------------------------------------------------------\n');
    
    success = false;
end

function success = configureStartup()
    startupFile = fullfile(userpath, 'startup.m');
    
    % Get the full path to this toolbox's root directory
    toolboxRoot = fileparts(fileparts(mfilename('fullpath')));
    
    % Define the lines to be added to startup.m
    header = '%% Discord Rich Presence Integration';
    addpathLine = sprintf('addpath(''%s'');', toolboxRoot);
    startLine = 'discordrpc.start();';

    % Check if already configured
    if isfile(startupFile)
        content = fileread(startupFile);
        if contains(content, addpathLine) && contains(content, startLine)
            fprintf('Startup script already configured.\n');
            success = true;
            return;
        end
    end
    
    % Write the configuration to startup.m
    try
        fid = fopen(startupFile, 'a+');
        fprintf(fid, '\n%s\n', header);
        fprintf(fid, '%s\n', addpathLine);
        fprintf(fid, '%s\n', startLine);
        fclose(fid);
        fprintf('Added startup configuration to: %s\n', startupFile);
        success = true;
    catch e
        warning('Failed to write to startup.m file.');
        fprintf('Please add the following lines to your startup.m file manually:\n');
        fprintf('   %s\n   %s\n', addpathLine, startLine);
        disp(e.message);
        success = false;
    end
end