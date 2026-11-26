# NatickOS target layout, shared by RPM builds and spec queries.
# Use --define so the values survive rpmbuild --target initialization.
natick_rpm_defs=(
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
