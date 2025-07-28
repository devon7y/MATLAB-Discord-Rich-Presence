function start()
    % START - Initializes the Discord Rich Presence integration.
    %
    % This function sets up and starts a timer that periodically checks for the
    % currently active file in the MATLAB editor and updates Discord Rich Presence.
    %
    % It ensures that only one instance of the timer is running at any time.
    %
    % Usage:
    %   discordrpc.start()

    % --- Timer Configuration ---
    timerName = 'discordRichPresenceTimer';

    % Stop any existing timers with the same name to prevent duplicates
    existingTimers = timerfind('Name', timerName);
    if ~isempty(existingTimers)
        try
            stop(existingTimers);
            delete(existingTimers);
        catch e
            warning('An error occurred while trying to stop the timer.\n%s', e.message);
        end
    end

    % --- Python Process Management ---
    % Ensure any old Python process is killed before starting a new one
    discordrpc.stop(); % Call stop to clean up any previous runs

    % Define communication file path (in temp directory)
    commFilePath = fullfile(tempdir, sprintf('matlab_discord_rpc_comm_%s.txt', datestr(now, 'yyyymmddHHMMSSFFF')));
    assignin('base', 'discordRPCCommFile', commFilePath); % Store for stop.m

    % Get Python executable path
    [pythonExecutable, isFound] = discordrpc.findPythonExecutable();
    if ~isFound
        warning('Discord RPC: Python executable not found. Please run discordrpc.setup().');
        return;
    end

    % Get Python script path
    [toolboxRoot, ~] = fileparts(mfilename('fullpath'));
    pythonScriptPath = fullfile(toolboxRoot, '..', 'update_presence.py');
    if ~isfile(pythonScriptPath)
        warning('Discord RPC: Python script not found at %s', pythonScriptPath);
        return;
    end

    % Get initial active file
    currentFile = '';
    try
        activeEditor = matlab.desktop.editor.getActive;
        if ~isempty(activeEditor)
            currentFile = activeEditor.Filename;
        end
    catch
        % Editor not available
    end

    % Write initial file to communication file
    try
        fid = fopen(commFilePath, 'w');
        fprintf(fid, '%s', currentFile);
        fclose(fid);
    catch e
        warning('Discord RPC: Could not write to communication file: %s', e.message);
        return;
    end

    % Launch Python script in background using nohup to ensure persistence
    % Redirect output to /dev/null
    command = sprintf('nohup "%s" "%s" "%s" "%s" > /dev/null 2>&1 &', pythonExecutable, pythonScriptPath, commFilePath, currentFile);
    
    [status, cmdout] = system(command); % Launch command
    if status ~= 0
        warning('Discord RPC: Failed to launch Python script (status %d): %s', status, cmdout);
        return;
    end

    % Create a new timer
    t = timer(...
        'Name', timerName, ...
        'Period', 2, ...  % Check every 2 seconds
        'ExecutionMode', 'fixedRate', ...
        'StartDelay', 2); % Wait 2 seconds before the first execution
    t.TimerFcn = {@discordrpc.update}; % This will now write to the comm file
    assignin('base', 'discordRPCTimer', t); % Store the timer object

    % --- Start the Timer ---
    try
        start(t);
        fprintf('Discord Rich Presence integration started.\n');
    catch e
        warning('Failed to start the Discord Rich Presence timer.');
        disp(e.message);
        discordrpc.stop(); % Clean up if timer fails to start
    end
end