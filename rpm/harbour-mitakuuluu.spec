Name:       harbour-mitakuuluu

# >> macros
# << macros

%{!?qtc_qmake:%define qtc_qmake %qmake}
%{!?qtc_qmake5:%define qtc_qmake5 %qmake5}
%{!?qtc_make:%define qtc_make make}
%{?qtc_builddir:%define _builddir %qtc_builddir}
Summary:    Mitäkuuluu
Version:    0.2
Release:    2
Group:      Qt/Qt
License:    LICENSE
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 libexif
Obsoletes: mitakuuluukiller mitakuuluu-autostart killme
Conflicts: mitakuuluukiller mitakuuluu-autostart killme
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5Contacts)
BuildRequires:  pkgconfig(sailfishapp)
BuildRequires:  desktop-file-utils
BuildRequires:  libexif-devel
BuildRequires:  mce-headers
BuildRequires:  libiphb-devel


%description
Short description of my SailfishOS Application


%prep
%setup -q -n %{name}-%{version}

# >> setup
# << setup

%build
# >> build pre
# << build pre

%qtc_qmake5 VERSION=%{version} RELEASE=%{release}

%qtc_make %{?_smp_mflags}

# >> build post
# << build post

%install
rm -rf %{buildroot}
# >> install pre
# << install pre
%qmake5_install

# >> install post

mkdir -p %{buildroot}/home/nemo/.config/systemd/user/post-user-session.target.wants/
touch %{buildroot}/home/nemo/.config/systemd/user/post-user-session.target.wants/harbour-mitakuuluu.service
mkdir -p %{buildroot}/home/nemo/.whatsapp/logs
touch %{buildroot}/home/nemo/.whatsapp/whatsapp.log
touch %{buildroot}/home/nemo/.whatsapp/whatsapp.db
touch %{buildroot}/home/nemo/.whatsapp/logs/whatsapp_log1.tar.gz
touch %{buildroot}/home/nemo/.whatsapp/logs/whatsapp_log2.tar.gz
touch %{buildroot}/home/nemo/.whatsapp/logs/whatsapp_log3.tar.gz
mkdir -p %{buildroot}/home/nemo/.config/coderus
touch %{buildroot}/home/nemo/.config/coderus/whatsapp.conf
# << install post

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%pre
# >> pre

if /sbin/pidof harbour-mitakuuluu-server > /dev/null; then
killall harbour-mitakuuluu-server
#su -l -c "dbus-send --print-reply --session --dest=org.coderus.harbour_mitakuuluu_server / org.coderus.harbour_mitakuuluu_server.exit" nemo || true
fi

if /sbin/pidof harbour-mitakuuluu > /dev/null; then
killall harbour-mitakuuluu
#su -l -c "dbus-send --print-reply --session --dest=org.coderus.harbour_mitakuuluu / org.coderus.harbour_mitakuuluu.exit" nemo || true
fi
# << pre

%preun
# >> preun

if /sbin/pidof harbour-mitakuuluu-server > /dev/null; then
killall harbour-mitakuuluu-server
#su -l -c "dbus-send --print-reply --session --dest=org.coderus.harbour_mitakuuluu_server / org.coderus.harbour_mitakuuluu_server.exit" nemo || true
fi

if /sbin/pidof harbour-mitakuuluu > /dev/null; then
killall harbour-mitakuuluu
#su -l -c "dbus-send --print-reply --session --dest=org.coderus.harbour_mitakuuluu / org.coderus.harbour_mitakuuluu.exit" nemo || true
fi
# << preun

%post
# >> post
if [ -d /home/nemo/.whatsapp ]; then
    chown -R nemo:privileged /home/nemo/.whatsapp
fi
if [ -d /home/nemo/.config/coderus ]; then
    chown -R nemo:privileged /home/nemo/.config/coderus
fi
if [ -d /home/nemo/.config/systemd/user/post-user-session.target.wants ]; then
    chown -R nemo:privileged /home/nemo/.config/systemd/user/post-user-session.target.wants
fi
# << post

%files
%defattr(-,root,root,-)
%{_datadir}/dbus-1/services
#/usr/lib/nemo-transferengine/plugins
%{_datadir}/lipstick/notificationcategories/
%{_datadir}/jolla-gallery/mediasources/
%{_datadir}/icons/hicolor/86x86/apps/%{name}.png
%{_datadir}/applications/%{name}.desktop
%{_datadir}/themes/base/meegotouch/icons/
%{_datadir}/%{name}
/usr/lib/qt5/qml/harbour/mitakuuluu/filemodel
/usr/lib/systemd/user
%{_bindir}
%ghost /home/nemo/.config/systemd/user/post-user-session.target.wants/harbour-mitakuuluu.service
%ghost /home/nemo/.whatsapp/whatsapp.log
%ghost /home/nemo/.whatsapp/whatsapp.db
%ghost /home/nemo/.whatsapp/logs/whatsapp_log1.tar.gz
%ghost /home/nemo/.whatsapp/logs/whatsapp_log2.tar.gz
%ghost /home/nemo/.whatsapp/logs/whatsapp_log3.tar.gz
%ghost /home/nemo/.config/coderus/whatsapp.conf
# >> files
# << files
