# Test cases, sourced by tests/run.sh. See run.sh for the helpers.

# Default layout and output formats.
run_case default-stdout             --stdout
run_case default-json               --json
run_case default-logo
run_case all-fields-intel           FAKE_ARCH=intel --config "$tests/configs/all-fields.conf" --stdout
config_case all-fields              all-fields.conf --stdout
config_case all-fields-json         all-fields.conf --json

# Field-only runs and options.
run_case fields-simple              uptime memory disk local_ip
run_case fields-gpu-resolution      gpu resolution
run_case gpu-ioreg-empty            FAKE_IOREG=empty gpu
run_case gpu-intel                  FAKE_ARCH=intel gpu
run_case options                    --stdout --uptime_shorthand tiny --memory_unit gib \
                                    --cpu_cores physical --disk_percent off --refresh_rate off
run_case disable                    --stdout --disable cpu gpu resolution
run_case disk-bar                   --stdout --disk_display barinfo --memory_display bar

# Configs whose print_info() runs custom code around GPU/Resolution.
config_case reads-gpu-var           reads-gpu-var.conf --stdout
config_case override-resolution     override-resolution.conf --stdout
config_case override-gpu            override-gpu.conf --stdout

# Layout editor (--customize).
customize_case customize-edit       'jj\nSystem\nJj \e[B\e[B\e[B\e[B\e[B\e[B\e[B\e[B\e[B\e[B\e[B\e[B\e[B\e[B\e[B\e[B\e[B s'
customize_case customize-quit       ' qq'
customize_case customize-refuse     's' custom-code.conf

# Disk names with spaces, and a name that tries to run a command from bash
# arithmetic (the fake df prints mount points as given).
run_case disk-spaces                --stdout --disk_show '/Volumes/My Passport' / --disk_display barinfo
run_case disk-injection             --stdout --disk_show '/Volumes/a x[$(printf${IFS}x>$FAKE_ROOT/INJECTED)] b' \
                                    --disk_display barinfo
run_case disk-subtitle-name         disk --disk_show '/Volumes/My Passport' --disk_subtitle name
run_case disk-subtitle-dir          disk --disk_show '/Volumes/My Passport' --disk_subtitle dir
run_case memory-gib-bar             memory --memory_unit gib --memory_display infobar
run_case disk-garbled-df            FAKE_DF=garbled -v --stdout
config_case bar-non-numeric         bad-bar-data.conf --stdout --memory_display infobar

# Detected text with control characters or '%b' escapes prints as plain text;
# neofetch's own colors still render (see default-logo).
run_case escape-raw-bytes           $'FAKE_GPU=Apple\e[31m M4\e]0;pwned\a' --stdout gpu
run_case escape-backslash-text      'FAKE_GPU=Apple \e[31mM4\033[0m \n end' --stdout gpu
run_case escape-backslash-json      'FAKE_GPU=Apple \e[31mM4' --json
run_case escape-colored             'FAKE_GPU=Apple \e[31mM4'
run_case escape-disk-name           --stdout disk --disk_show $'/Volumes/E\e[2Jvil\\e[31m'
run_case escape-title               $'USER=te\e[2Jster' 'HOSTNAME=host\e[31m' --stdout title
run_case escape-colored-bars        'FAKE_GPU=Apple \e[31mM4' --memory_display infobar --disk_display barinfo
run_case escape-tab-in-disk-name    --stdout disk --disk_show $'/Volumes/Tab\tName'
run_case escape-title-width         'HOSTNAME=host\name' --stdout --config "$tests/configs/title-underline.conf"

# The Shell field reports the login shell's version, not the bash running neofetch.
run_case shell-bash-version         "SHELL=$fakes/shells/bash" shell
run_case shell-bash-path            "SHELL=$fakes/shells/bash" shell --shell_path on

# An interrupted --customize save leaves no temporary file and the config intact.
interrupt_case customize-interrupted    slow-validation.conf
