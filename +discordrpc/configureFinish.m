function success = configureFinish()
    finishFile = fullfile(userpath, 'finish.m');
    stopCommand = 'discordrpc.stop();';
    
    if isfile(finishFile)
        content = fileread(finishFile);
        if contains(content, stopCommand)
            fprintf('Finish script already configured.\n');
            success = true;
            return;
        end
    end
    
    try
        fid = fopen(finishFile, 'a+');
        fwrite(fid, '%% Debug: Executing finish.m for Discord RPC cleanup.\n'); % Debugging line
        fprintf(fid, '%s\n', stopCommand);
        fclose(fid);
        fprintf('Added finish command to: %s\n', finishFile);
        success = true;
    catch e
        warning('Failed to write to finish.m file.\n');
        fprintf('Please add the following line to your finish.m file manually:\n');
        fprintf('%s\n', stopCommand);
        disp(e.message);
        success = false;
    end
end