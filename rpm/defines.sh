# natickOS target layout and macro loader
natick_rpm_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
natick_rpm_macro_path=$(rpm --showrc | awk '/^Macro path: / { sub(/^Macro path: /, ""); print }')
if [[ -z "$natick_rpm_macro_path" ]]; then
    echo 'Cannot determine RPM macro search path' >&2
    return 1
fi
natick_rpm_defs=(
    --macros "$natick_rpm_macro_path:$natick_rpm_dir/macros.natick"
    --define 'dist .natick'
    --define '_prefix /usr'
    --define '_exec_prefix %{_prefix}'
    --define '_bindir %{_exec_prefix}/bin'
    --define '_sbindir %{_exec_prefix}/sbin'
    --define '_libdir %{_exec_prefix}/lib'
    --define '_includedir %{_prefix}/include'
    --define '_sysconfdir /etc'
    --define '_localstatedir /var'
    --define '_sharedstatedir %{_localstatedir}/lib'
    --define '_rundir /run'
    --define '_runstatedir %{_rundir}'
)
