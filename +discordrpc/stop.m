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
            fprintf('Discord Rich Presence timer stopped.\n');
        catch e
            warning('An error occurred while trying to stop the timer.\n%s', e.message);
        end
    else
        % fprintf('Discord Rich Presence timer not found.\n'); % Removed for silence
    end

    % --- Kill Python Process ---
    if evalin('base', 'exist("discordRPCPid", "var")')
        pid = evalin('base', 'discordRPCPid');
        if ~isempty(pid)
            fprintf('Attempting to kill Python process with PID: %d\n', pid);
            if isunix || ismac
                % Use kill -9 to forcefully terminate the process group
                [status, cmdout] = system(sprintf('kill -9 -- -%d', pid)); 
            elseif ispc
                [status, cmdout] = system(sprintf('taskkill /F /PID %d', pid));
            else
                status = 1; cmdout = 'Unsupported OS';
            end

            if status == 0
                fprintf('Python process killed successfully.\n');
            else
                warning('Failed to kill Python process (PID %d): %s\n%s', pid, cmdout);
            end
        end
        evalin('base', 'clear discordRPCPid');
    end

    % --- Clean up Communication File ---
    if evalin('base', 'exist("discordRPCCommFile", "var")')
        commFilePath = evalin('base', 'discordRPCCommFile');
        if exist(commFilePath, 'file')
            try
                delete(commFilePath);
                fprintf('Communication file deleted: %s\n', commFilePath);
            catch e
                warning('Failed to delete communication file: %s\n%s', commFilePath, e.message);
            end
        end
        evalin('base', 'clear discordRPCCommFile');
    end

    % fprintf('Discord Rich Presence integration stopped and cleaned up.\n'); % Removed for silence
end