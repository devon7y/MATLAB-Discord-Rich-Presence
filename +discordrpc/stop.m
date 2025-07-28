% This function stops the Discord Rich Presence integration.
% It stops and deletes the MATLAB timer, attempts to kill the associated Python process,
% and cleans up the communication file.
% Author: Devon Yanitski and Gemini CLI 0.1.13

function stop()
    % STOP - Stops the Discord Rich Presence integration.
    %
    % This function finds the active Discord RPC timer, stops it, and removes it.
    % It also attempts to clear the Rich Presence status in Discord.
    %
    % Usage:
    %   discordrpc.stop()

    % --- Find and Stop the Timer ---
    timerName = 'discordRichPresenceTimer';
    existingTimers = timerfind('Name', timerName);

    if ~isempty(existingTimers)
        try
            stop(existingTimers);
            delete(existingTimers);
        catch e
            warning('An error occurred while trying to stop the timer.\n%s', e.message);
        end
    else
        % fprintf('Discord Rich Presence timer not found.\n'); % Removed for silence
    end

    % --- Kill Python Process ---
    % Use pkill -9 -f to forcefully terminate the Python process by its command line
    % This is more robust than relying on a specific PID which might become stale.
    if isunix || ismac
        [status, cmdout] = system(sprintf('pkill -9 -f "update_presence.py"'));
    elseif ispc
        % On Windows, taskkill /IM can kill by image name, but -f for command line is harder.
        % For now, we'll rely on the user to manually kill if it persists on Windows.
        % A more robust Windows solution would involve WMI queries.
        warning('Discord RPC: Automatic process termination by command line is not fully supported on Windows. Please kill manually if needed.');
        status = 1; cmdout = 'Not supported on Windows';
    else
        status = 1; cmdout = 'Unsupported OS';
    end

    % Suppress output if pkill simply found no process (status 1)
    if status == 0
        % fprintf('Discord RPC: Python process killed successfully.\n'); % Removed for silence
    elseif status == 1
        % fprintf('Discord RPC: No Python process found to kill.\n'); % Removed for silence
    else
        warning('Discord RPC: Failed to kill Python process (status %d): %s\n%s', status, cmdout);
    end

    evalin('base', 'clear discordRPCPidFile'); % Clear PID file variable
    evalin('base', 'clear discordRPCPid'); % Clear old PID variable if it exists

    % --- Clean up Communication File ---
    if evalin('base', 'exist("discordRPCCommFile", "var")')
        commFilePath = evalin('base', 'discordRPCCommFile');
        if exist(commFilePath, 'file')
            try
                delete(commFilePath);
            catch e
                warning('Failed to delete communication file: %s\n%s', commFilePath, e.message);
            end
        end
        evalin('base', 'clear discordRPCCommFile');
    end

    % fprintf('Discord Rich Presence integration stopped and cleaned up.\n'); % Removed for silence
end