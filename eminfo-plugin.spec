Summary: 	plugins for eminfo
Name: 		eminfo-plugin
Version: 	0.1
Release: 	beta2
License: 	GPLv3
Group:  	Extension
Packager: 	Zhang Guangzheng <zhang.elinks@gmail.com>
BuildRoot: 	/var/tmp/%{name}-%{version}-%{release}-root
Source0: 	eminfo-plugin-0.1-beta2.tgz
Requires:		eminfo >= 1.0, setup >= 2.5.58
Requires: 		coreutils >= 5.97, bash >= 3.1
Requires:		e2fsprogs >= 1.39, procps >= 3.2.7
Requires:		psmisc >= 22.2, util-linux >= 2.13
Requires:		SysVinit >= 2.86, nc >= 1.84
Requires: 		gawk >= 3.1.5, sed >= 4.1.5
Requires:		perl >= 5.8.8, grep >= 2.5.1
Requires:		tar >= 1.15.1, gzip >= 1.3.5
Requires:		curl >= 7.15.5, bc >= 1.06
Requires:		findutils >= 4.2.27, net-tools >= 1.60
Requires(post): 	chkconfig
Requires(preun): 	chkconfig, initscripts
Requires(postun): 	coreutils >= 5.97
#
# All of version requires are based on OS rhel5.1 release
#

%description 
plugins for eminfo

%prep
%setup -q

%build

%install 
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/local/eminfo/
mkdir -p $RPM_BUILD_ROOT/usr/local/eminfo/plugin/
mkdir -p $RPM_BUILD_ROOT/usr/local/eminfo/conf/
mkdir -p $RPM_BUILD_ROOT/usr/local/eminfo/handler/
mkdir -p $RPM_BUILD_ROOT/usr/local/eminfo/opt/
for p in `ls`
do
  cp -a ${p}/${p}	   $RPM_BUILD_ROOT/usr/local/eminfo/plugin/
  cp -a ${p}/conf/${p}.ini $RPM_BUILD_ROOT/usr/local/eminfo/conf/
  cp -a ${p}/handler/      $RPM_BUILD_ROOT/usr/local/eminfo/
  cp -a ${p}/opt/          $RPM_BUILD_ROOT/usr/local/eminfo/
done

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/usr/local/eminfo/plugin/
/usr/local/eminfo/conf/
/usr/local/eminfo/handler/
/usr/local/eminfo/opt/

%post

%preun

%postun

%changelog
* Sat Oct 26 2013 Guangzheng Zhang <zhang.elinks@gmail.com>
- release eminfo-plugin-0.1-beta2.rpm
- add plugin process, bugfix on mysql_ping
- rename some eminfo config
* Thu Oct 10 2013 Guangzheng Zhang <zhang.elinks@gmail.com>
- first buildrpm for eminfo-plugin-0.1-beta1.rpm
