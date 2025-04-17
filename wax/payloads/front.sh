#!/bin/bash
#
# hwid_manager.sh
#
# This script provides a CLI-based menu for managing the HWID and Cr50 functionalities
# on a Chromebook (or similar device). It supports:
#   1. Zeroing out HWID with Cr50 support (i.e. disabling Cr50 write protection first)
#   2. Zeroing out HWID without Cr50 support
#   3. Restoring HWID from a VPD backup
#   4. Manually disabling Cr50 protections
#
# WARNING: Modifying firmware or HWID data can brick your device.
# Use this script only with proper authorization and after thorough testing.
#

# Set a log file (adjust this path if needed)
LOGFILE="/mnt/usb/hwid_management.log"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

# Function to detect and log the Chromebook model
get_model() {
    log "Detecting Chromebook model..."
    MODEL=$(dmidecode -s system-product-name 2>/dev/null || echo "Unknown Model")
    log "Model detected: $MODEL"
}

# Function to back up the current VPD settings
backup_vpd() {
    log "Backing up VPD data..."
    vpd -l > /mnt/usb/vpd_backup.txt
    if [ $? -eq 0 ]; then
        log "VPD backup saved to /mnt/usb/vpd_backup.txt"
    else
        log "Failed to back up VPD!"
    fi
}

# Function to disable Cr50 write protection via gsctool
disable_cr50() {
    log "Disabling Cr50 write protection..."
    gsctool -a disable_wp
    if [ $? -eq 0 ]; then
        log "Cr50 write protection disabled successfully."
    else
        log "Failed to disable Cr50 write protection!"
    fi
}

# Option 1: Zero out HWID with Cr50 support
zero_out_hwid_cr50() {
    log "Zeroing out HWID with Cr50 support..."
    disable_cr50
    vpd -s "HWID="
    if [ $? -eq 0 ]; then
        log "HWID has been zeroed out (with Cr50 support)."
    else
        log "Failed to zero out HWID!"
    fi
}

# Option 2: Zero out HWID without using Cr50 methods
zero_out_hwid_nocr50() {
    log "Zeroing out HWID without Cr50 support..."
    vpd -s "HWID="
    if [ $? -eq 0 ]; then
        log "HWID has been zeroed out (no Cr50 support)."
    else
        log "Failed to zero out HWID!"
    fi
}

# Option 3: Restore HWID from backup file
restore_hwid() {
    log "Restoring HWID from backup..."
    if [ -f /mnt/usb/vpd_backup.txt ]; then
        BACKUP_HWID=$(grep "^HWID=" /mnt/usb/vpd_backup.txt | cut -d= -f2)
        if [ -n "$BACKUP_HWID" ]; then
            vpd -s "HWID=$BACKUP_HWID"
            if [ $? -eq 0 ]; then
                log "HWID successfully restored to '$BACKUP_HWID'."
            else
                log "Failed to restore HWID!"
            fi
        else
            log "No HWID value found in the backup file!"
        fi
    else
        log "Backup file /mnt/usb/vpd_backup.txt not found!"
    fi
}

# Option 4: Manually disable Cr50 protections
manual_disable_cr50() {
    log "Manually disabling Cr50 write protection..."
    disable_cr50
}

# Main execution starts here.
log "----- Starting HWID Management Script -----"
get_model

echo "Please choose an option:"
echo "  1) Zero out HWID (with Cr50 support)"
echo "  2) Zero out HWID (no Cr50 support)"
echo "  3) Restore HWID"
echo "  4) Disable Cr50 protections (Manual)"
echo "  5) Exit"

# Using the select command to provide a CLI menu:
PS3="Enter your choice [1-5]: "
select option in "Zero out HWID (with Cr50 support)" "Zero out HWID (no Cr50 support)" "Restore HWID" "Disable Cr50 Protections" "Exit"
do
    case $REPLY in
        1)
            backup_vpd
            zero_out_hwid_cr50
            break
            ;;
        2)
            backup_vpd
            zero_out_hwid_nocr50
            break
            ;;
        3)
            restore_hwid
            break
            ;;
        4)
            manual_disable_cr50
            break
            ;;
        5)
            log "Exiting script without changes."
            exit 0
            ;;
        *)
            echo "Invalid selection. Please select a valid option."
            ;;
    esac
done

log "----- HWID Management Script Completed -----"