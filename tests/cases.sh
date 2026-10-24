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
