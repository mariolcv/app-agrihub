#!/bin/bash

git clone https://github.com/flutter/flutter.git -b stable --depth 1 /usr/local/flutter

echo 'export PATH="/usr/local/flutter/bin:$PATH"' >> ~/.bashrc
export PATH="/usr/local/flutter/bin:$PATH"

flutter config --enable-web
flutter doctor
