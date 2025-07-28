import sys
import time
from pypresence import Presence, exceptions
import os

def update_presence_loop(client_id, comm_file_path, initial_file_name):
    print(f"[Python RPC] Starting presence loop. Comm file: {comm_file_path}")
    RPC = None
    current_file = initial_file_name
    last_mtime = 0

    try:
        RPC = Presence(client_id)
        print("[Python RPC] Connecting to Discord...")
        RPC.connect()
        print("[Python RPC] Connected to Discord.")
        start_time = int(time.time()) # Initialize start_time once
        last_details_text = None
        last_state_text = None

        while True:
            try:
                # Check for updates in the communication file
                if os.path.exists(comm_file_path):
                    new_mtime = os.path.getmtime(comm_file_path)
                    if new_mtime > last_mtime:
                        with open(comm_file_path, 'r') as f:
                            updated_file = f.read().strip()
                        if updated_file != current_file:
                            current_file = updated_file
                            last_mtime = new_mtime
                            print(f"[Python RPC] Detected file change in comm file: {current_file}")

                # Determine current presence details
                if current_file:
                    details_text = f"Editing {os.path.basename(current_file)}"
                    state_text = "In MATLAB"
                else:
                    details_text = "Idle"
                    state_text = "In MATLAB"

                # Only update Discord if details have changed
                if details_text != last_details_text or state_text != last_state_text:
                    RPC.update(
                        details=details_text,
                        state=state_text,
                        start=start_time,
                        large_image="matlab_logo",
                        large_text="MATLAB"
                    )
                    last_details_text = details_text
                    last_state_text = state_text
                    print(f"[Python RPC] Presence updated: Details='{details_text}', State='{state_text}'")

            except exceptions.PipeClosed:
                print("[Python RPC] Discord pipe closed. Attempting to reconnect...")
                try:
                    RPC.connect()
                    print("[Python RPC] Reconnected to Discord.")
                    # Force update after reconnect
                    last_details_text = None
                    last_state_text = None
                except Exception as reconnect_e:
                    print(f"[Python RPC] Reconnection failed: {reconnect_e}. Retrying in 15s.")
            except Exception as e:
                print(f"[Python RPC] Error during update loop: {e}")
            
            time.sleep(5) # Check and update every 5 seconds

    except exceptions.PipeClosed as e:
        print(f"[Python RPC] Initial connection failed: Discord pipe closed. Is Discord running? {e}")
    except Exception as e:
        print(f"[Python RPC] An unexpected error occurred during initial setup: {e}")
    finally:
        if RPC:
            try:
                RPC.close()
                print("[Python RPC] Discord connection closed.")
            except Exception as close_e:
                print(f"[Python RPC] Error closing RPC connection: {close_e}")
        sys.exit(1)

if __name__ == "__main__":
    client_id = "1399483753474166916"
    comm_file_path = None
    initial_file_name = ""

    if len(sys.argv) > 1:
        comm_file_path = sys.argv[1]
    if len(sys.argv) > 2:
        initial_file_name = sys.argv[2]

    if comm_file_path:
        update_presence_loop(client_id, comm_file_path, initial_file_name)
    else:
        print("[Python RPC] Error: Communication file path not provided.")
        sys.exit(1)
