name "statsd"
maintainer       "Jon Wood"
maintainer_email "jon@blankpad.net"
license          "Apache 2.0"
description      "Installs/Configures statsd"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.4"

depends "build-essential"
depends "git"
depends "nodejs"

supports "ubuntu redhat"
