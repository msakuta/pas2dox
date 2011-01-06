Summary: Pas2Dox is a Delphi/Kylix input filter for Doxygen
Name: pas2dox
Version: 0.40
Release: 1
Group: Development/Tools
License: GPL
Url: http://pas2dox.sourceforge.net
Packager: Darren Bowles<dbowles@users.sourceforge.net>
Source: ftp://ftp.sourceforge.net/pub/sourceforge/pas2dox/pas2dox-0.40.tar.gz

%description
Pas2Dox (Pascal To Doxygen) is a pre-processing filter for Doxygen. 
It allows Kylix/Delphi programmers to comment their code using JavaDoc
style tags and then have Doxygen build the application documentation.

This is a major update, with many syntax handling fixes, including : 

Properties handled in an acceptable way.
Updated array handling.
Pointer to array handled.
Class of handled.
Default values handled.
Single line comments handled in const/var sections
Additional minor fixes.

%prep
%setup

%build
make

%install
make install

%files
/usr/local/bin/pas2dox
