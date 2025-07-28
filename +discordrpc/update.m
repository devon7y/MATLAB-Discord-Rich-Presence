function update(~, ~)
    % UPDATE - Checks the active editor file and updates Discord Rich Presence.
    %
    % This function is called periodically by the timer started with `discordrpc.start()`.
    % It gets the current file from the MATLAB editor and writes it to a communication file.
    % A background Python script reads this communication file to update Discord Rich Presence.
    %
    % This function is not intended to be called directly by the user.

    persistent lastFile;

    % --- Initialization ---
    if isempty(lastFile)
        lastFile = '';
    end

    % Get communication file path from base workspace
    commFilePath = evalin('base', 'discordRPCCommFile');
    if isempty(commFilePath) || ~exist(commFilePath, 'file')
        warning('Discord RPC: Communication file not found. Stopping integration.');
        discordrpc.stop();
        return;
    end

    % --- Get Active Editor File ---
    currentFile = '';
    try
        activeEditor = matlab.desktop.editor.getActive;
        if ~isempty(activeEditor)
            currentFile = activeEditor.Filename;
        end
    catch
        % Handle cases where the editor is not available (e.g., -nodisplay mode)
        currentFile = '';
    end

    % --- Check for File Change and Update Communication File ---
    if ~strcmp(currentFile, lastFile)
        
        lastFile = currentFile;

        % Write current file to communication file
        try
            fid = fopen(commFilePath, 'w');
            fprintf(fid, '%s', currentFile);
            fclose(fid);
            
        catch e
            warning('Discord RPC: Could not write to communication file: %s', e.message);
        end
    end
end