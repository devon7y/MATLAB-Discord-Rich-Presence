% This script configures the MATLAB finish.m file to stop the Discord Rich Presence
% when MATLAB closes.
% Author: Devon Yanitski and Gemini CLI 0.1.13

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
        fprintf(fid, '\n%% Stop Discord Rich Presence integration\n');
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